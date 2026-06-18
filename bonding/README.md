## CIQ BLE Bonding demo

Demonstrates how to:
- connect to a BLE device by name
- form a permanent pairing ("bonding" in BLE parlance)
- subscribe to a secured characteristic
- decode and display the data on a watch

## App user guide

1. Start the peripheral
2. Start the app, scan and connect. Observe that there is a "Pairing.." spinner.
3. Exit the app. Observe the sensor is now in the "Sensors" watch settings page.
4. Reset the peripheral board
5. Open the app again. Observe that the "Pairing.." spinner doesn't appear. That means the peer was recognized and re-encrypted with the same keys.
6. Exit the app. Remove the CIQ sensor from the "Sensors" settings page
7. Re-open the app. Pairing should fail, as the peer detected the keys are now missing.
8. Observe on the peer's serial terminal a message indicating pairing has failed and the bonds have been cleared.
9. Re-open the app. Pairing should now succeed.

## Peripheral sample

The peripheral side is an nRF 52840 DK running the zephyr-sample/ app.
It emulates a temperature sensor with random data, readable only with a secure BLE connection.

``` sh
west init -l .
west update
west build -b nrf52840dk/nrf52840
west flash
```
