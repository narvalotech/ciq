This app demonstrates how to:
- connect to a BLE device by name
- form a permanent pairing ("bonding" in BLE parlance)
- subscribe to a particular characteristic
- decode and display the data on a watch
- the device should be visible in the "Sensors" watch menu

The peripheral side is an nRF 52840 dongle running the zephyr-sample/ app.

It emulates a temperature sensor with random data, readable only with a secure BLE connection.
