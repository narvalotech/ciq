## CIQ BLE DataField demo

This app showcases two things: how to use the built-in "custom sensor" pairing
scheme for a BLE sensor and how to make a data field using that BLE sensor's
data.

This involves:
- connecting to a BLE device by name
- forming a permanent sensor pairing ("bonding" in BLE parlance)
- subscribing to a secured characteristic
- decoding and displaying the data in an activity field
- recording data to the .FIT file

## App user guide

1. Start the peripheral
2. Go into the "Connectivity" -> "Sensors & Accessories" -> "Add New" -> "Search All"
3. Click the "Temperature" sensor. Wait until a green screen: "Temperature connected".
4. Configure the "Run" activity to show a new data field "BLE Temperature".
5. Start the "Run" activity.
6. Observe the data in the field showing the temperature.
7. Power-cycle the peripheral. Observe the sensor reconnects seamlessly.
8. Stop and save the activity.
9. Verify with a .FIT viewer that the temperature has been logged under "Custom temperature".

## Peripheral sample

The peripheral side is an nRF 52840 DK running the zephyr-sample/ app.
It emulates a temperature sensor with random data, readable only with a secure BLE connection.

``` sh
west init -l .
west update
west build -b nrf52840dk/nrf52840
west flash
```
