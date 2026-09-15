#!/usr/bin/env python3
"""
PHUD BOX BLE peripheral for Raspberry Pi, built on BlueZ via the
`bluezero` library (pip install bluezero). Must run as root (or with
CAP_NET_ADMIN) since it registers a GATT server and advertises.

Implements the same protocol the Flutter app's BleService expects:

  Service UUID:     b3f1e100-0a1e-4b8b-9a53-4f0e6d6a10a0
  Telemetry (notify): b3f1e101-0a1e-4b8b-9a53-4f0e6d6a10a0
  Command   (write):  b3f1e102-0a1e-4b8b-9a53-4f0e6d6a10a0

Every message is a JSON object encoded as UTF-8, terminated with '\n'.
Messages longer than ~20 bytes (default BLE MTU) are split into chunks;
the phone-side app reassembles by buffering until it sees '\n'.

This script simulates the sensor/relay layer (door switch, UV lamp,
battery fuel gauge) with plain Python state so you can test the app
end-to-end before wiring real GPIO. Replace `read_door_sensor()`,
`set_uv_lamp()`, and `read_battery_percent()` with your actual hardware
calls (RPi.GPIO / gpiozero / I2C fuel gauge, etc).

NOTE: bluezero's exact method names have shifted across versions.
Check `python3 -c "import bluezero; print(bluezero.__file__)"` and the
installed examples under site-packages/bluezero/examples if any call
here doesn't match your version.
"""

import json
import threading
import time
from datetime import datetime, timedelta

from bluezero import peripheral, adapter

SERVICE_UUID = 'b3f1e100-0a1e-4b8b-9a53-4f0e6d6a10a0'
TELEMETRY_CHAR_UUID = 'b3f1e101-0a1e-4b8b-9a53-4f0e6d6a10a0'
COMMAND_CHAR_UUID = 'b3f1e102-0a1e-4b8b-9a53-4f0e6d6a10a0'

CYCLE_SECONDS = 525  # 08:45, matches the reference UI
BATCH_COLORS = ['RED', 'BLUE', 'GREEN', 'YELLOW']
INSTRUMENT_SETS = [
    ['Scalpel', 'Forceps', 'Scissors', 'Needle Holder'],
    ['Scalpel', 'Forceps'],
    ['Scissors', 'Scalpel'],
    ['Forceps', 'Needle Holder', 'Scissors'],
]

state_lock = threading.Lock()
state = {
    'battery': 100,
    'status': 'idle',           # 'idle' | 'disinfecting'
    'door_open': True,
    'chamber_slots_left': 3,
    'seconds_left': 0,
    'active_batch': None,
    'next_batch_id': 1,
}

telemetry_char = None  # set once the peripheral is built
_tx_buffer = []


# --------------------------------------------------------------------
# Replace these with real GPIO / sensor reads on actual hardware.
# --------------------------------------------------------------------
def read_door_sensor():
    return state['door_open']


def set_uv_lamp(on: bool):
    print(f'[hardware] UV lamp {"ON" if on else "OFF"}')


def read_battery_percent():
    return state['battery']


# --------------------------------------------------------------------
# Protocol helpers
# --------------------------------------------------------------------
def send_json(obj):
    """Queue a JSON line for delivery over the telemetry characteristic."""
    global telemetry_char
    if telemetry_char is None:
        return
    payload = (json.dumps(obj) + '\n').encode('utf-8')
    chunk_size = 20  # conservative default ATT MTU payload size
    for i in range(0, len(payload), chunk_size):
        telemetry_char.set_value(list(payload[i:i + chunk_size]))
        time.sleep(0.02)  # small delay so notifications aren't dropped


def broadcast_telemetry():
    with state_lock:
        send_json({
            'type': 'telemetry',
            'battery': state['battery'],
            'status': state['status'],
            'door_open': state['door_open'],
            'chamber_slots_left': state['chamber_slots_left'],
            'seconds_left': state['seconds_left'],
            'active_batch': state['active_batch'],
        })


def broadcast_log_entry(entry):
    send_json({'type': 'log_entry', **entry})


# --------------------------------------------------------------------
# Cycle logic
# --------------------------------------------------------------------
def start_cycle():
    with state_lock:
        if state['status'] == 'disinfecting' or state['door_open']:
            return
        n = state['next_batch_id']
        color = BATCH_COLORS[(n - 1) % len(BATCH_COLORS)]
        instruments = INSTRUMENT_SETS[(n - 1) % len(INSTRUMENT_SETS)]
        state['active_batch'] = {
            'id': f'#{n:03d}',
            'color': color,
            'instruments': instruments,
            'uv_intensity': '275nm',
            'started_at': datetime.utcnow().isoformat() + 'Z',
        }
        state['status'] = 'disinfecting'
        state['seconds_left'] = CYCLE_SECONDS
        state['chamber_slots_left'] = 0
    set_uv_lamp(True)
    broadcast_telemetry()


def end_cycle(manual=True):
    with state_lock:
        if state['status'] != 'disinfecting':
            return
        batch = state['active_batch']
        started_at = datetime.fromisoformat(batch['started_at'].replace('Z', ''))
        ended_at = datetime.utcnow()
        passed = not manual
        entry = {
            'id': batch['id'],
            'color': batch['color'],
            'date': started_at.strftime('%m/%d/%Y'),
            'result': 'PASS' if passed else 'FAIL',
            'instruments': ', '.join(batch['instruments']),
            'time': f"{started_at.strftime('%I:%M %p')} - {ended_at.strftime('%I:%M %p')}",
            'uv_intensity': batch['uv_intensity'],
            'expiry': (ended_at + timedelta(days=1)).strftime('%m/%d/%Y @ %I:%M %p')
            if passed else None,
            'error': None if passed else 'Cycle ended early by operator.',
        }
        state['status'] = 'idle'
        state['active_batch'] = None
        state['seconds_left'] = 0
        state['chamber_slots_left'] = 3
        state['next_batch_id'] += 1
        state['battery'] = max(0, state['battery'] - 8)
    set_uv_lamp(False)
    broadcast_log_entry(entry)
    broadcast_telemetry()


def cycle_ticker():
    """Background loop: counts down active cycles and pushes telemetry."""
    while True:
        time.sleep(1)
        with state_lock:
            state['door_open'] = read_door_sensor()
            state['battery'] = read_battery_percent()
            if state['status'] == 'disinfecting':
                if state['seconds_left'] > 0:
                    state['seconds_left'] -= 1
                    finished = state['seconds_left'] == 0
                else:
                    finished = True
            else:
                finished = False
        if finished:
            end_cycle(manual=False)
        else:
            broadcast_telemetry()


# --------------------------------------------------------------------
# GATT write callback: handles commands from the phone
# --------------------------------------------------------------------
_rx_buffer = bytearray()


def on_command_write(value, options):
    global _rx_buffer
    _rx_buffer.extend(bytes(value))
    while b'\n' in _rx_buffer:
        line, _, rest = _rx_buffer.partition(b'\n')
        _rx_buffer = bytearray(rest)
        if not line:
            continue
        try:
            command = json.loads(line.decode('utf-8'))
        except (ValueError, UnicodeDecodeError):
            continue
        cmd = command.get('cmd')
        if cmd == 'start_cycle':
            start_cycle()
        elif cmd == 'end_cycle':
            end_cycle(manual=True)
        else:
            print(f'[ble] unknown command: {command}')


def main():
    global telemetry_char

    adapters = list(adapter.list_adapters())
    if not adapters:
        raise RuntimeError('No Bluetooth adapter found. Is BlueZ running?')
    adapter_address = adapters[0]

    phud_box = peripheral.Peripheral(adapter_address, local_name='PHUD BOX MED-UV-001')

    phud_box.add_service(srv_id=1, uuid=SERVICE_UUID, primary=True)

    phud_box.add_characteristic(
        srv_id=1, chr_id=1, uuid=TELEMETRY_CHAR_UUID,
        value=[], notifying=False,
        flags=['notify', 'read'],
        read_callback=lambda: [],
        notify_callback=None,
    )
    telemetry_char = phud_box  # bluezero exposes set_value on the peripheral;
    # if your installed version instead returns a characteristic object from
    # add_characteristic, use that object's set_value(...) in send_json()
    # instead of telemetry_char.set_value(...).

    phud_box.add_characteristic(
        srv_id=1, chr_id=2, uuid=COMMAND_CHAR_UUID,
        value=[], notifying=False,
        flags=['write', 'write-without-response'],
        write_callback=on_command_write,
    )

    threading.Thread(target=cycle_ticker, daemon=True).start()

    print('Advertising PHUD BOX... Ctrl+C to stop.')
    phud_box.publish()


if __name__ == '__main__':
    main()
