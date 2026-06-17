import sys

# ruff: noqa: E402
sys.path.append("")

from micropython import const

import asyncio
import aioble
import bluetooth

import random
import struct

import aioble.core
import aioble.security
aioble.core.log_level = 3

_ENV_SENSE_SVC_UUID = bluetooth.UUID(0x181A)
_ENV_SENSE_TEMP_CHRC_UUID = bluetooth.UUID(0x2A6E)
_ADV_APPEARANCE_GENERIC_THERMOMETER = const(768)
_GAP_NAME = "PicoW-XRP"

# How frequently to send advertising beacons.
_ADV_INTERVAL_US = 250_000

# Characteristic permission flag requiring an encrypted link to read.
# (Defined in aioble.server but not exposed via the Characteristic ctor.)
_FLAG_READ_ENCRYPTED = const(0x0200)

# Load any previously-stored bonding keys so paired centrals can reconnect
# without pairing again. Must be called before the BLE stack is activated.
aioble.security.load_secrets()

def make_gap_service(name, appearance):
    # aioble doesn't populate the "Appearance" characteristic in the GAP service
    # This is a mandatory characteristic. Build and add it ourselves instead.
    _GAP_SERVICE_UUID = bluetooth.UUID(0x1800)
    _GAP_NAME_CHAR_UUID = bluetooth.UUID(0x2A00)
    _GAP_APPEARANCE_CHAR_UUID = bluetooth.UUID(0x2A01)
    gap_service = aioble.Service(_GAP_SERVICE_UUID)
    name_char = aioble.Characteristic(gap_service, _GAP_NAME_CHAR_UUID, read=True)
    appearance_char = aioble.Characteristic(gap_service, _GAP_APPEARANCE_CHAR_UUID, read=True)
    name_char.write(name.encode('utf-8'))
    appearance_char.write(struct.pack("<H", appearance))
    return gap_service


# Register GATT server.
temp_service = aioble.Service(_ENV_SENSE_SVC_UUID)
temp_characteristic = aioble.Characteristic(
    temp_service, _ENV_SENSE_TEMP_CHRC_UUID, read=True, notify=True
)

# Require an encrypted (paired) link before the temperature value can be read.
# The stack rejects unencrypted reads with "Insufficient Encryption", which
# prompts the central to pair. Must be set before register_services().
temp_characteristic.flags |= _FLAG_READ_ENCRYPTED

# Populate the GATT table with both services
aioble.register_services(make_gap_service(_GAP_NAME, _ADV_APPEARANCE_GENERIC_THERMOMETER), 
                         temp_service)


# Helper to encode the temperature characteristic encoding (sint16, hundredths of a degree).
def _encode_temperature(temp_deg_c):
    return struct.pack("<h", int(temp_deg_c * 100))


# This would be periodically polling a hardware sensor.
async def sensor_task():
    t = 24.5
    while True:
        print(f'temp: {t}')
        temp_characteristic.write(_encode_temperature(t), send_update=True)
        t += random.uniform(-0.5, 0.5)
        await asyncio.sleep_ms(1000)


# Serially wait for connections. Don't advertise while a central is
# connected.
async def peripheral_task():
    while True:
        async with await aioble.advertise(
            _ADV_INTERVAL_US,
            name=_GAP_NAME,
            services=[_ENV_SENSE_SVC_UUID],
            appearance=_ADV_APPEARANCE_GENERIC_THERMOMETER,
        ) as connection:
            print("Connection from", connection.device)

            # Force a secure connection before allowing any use of the
            # temperature characteristic. LESC "just works":
            #   le_secure=True  -> LE Secure Connections (LESC) pairing
            #   mitm=False      -> no man-in-the-middle protection (just works)
            #   bond=True       -> persist keys for faster reconnection
            try:
                await connection.pair(bond=True, le_secure=True, mitm=False)
            except asyncio.TimeoutError:
                print("Pairing timed out; disconnecting")
                await connection.disconnect()
                continue

            if not connection.encrypted:
                print("Link not encrypted; disconnecting")
                await connection.disconnect()
                continue

            print("Secure connection established (encrypted)")
            await connection.disconnected(timeout_ms=None)


# Run both tasks.
async def main():
    t1 = asyncio.create_task(sensor_task())
    t2 = asyncio.create_task(peripheral_task())
    await asyncio.gather(t1, t2)


asyncio.run(main())
