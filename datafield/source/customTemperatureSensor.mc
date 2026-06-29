import Toybox.Sensor;
import Toybox.System;
import Toybox.Lang;
import Toybox.BluetoothLowEnergy;

class CustomTemperatureSensor extends Sensor.SensorDelegate {
    // See howto: https://developer.garmin.com/connect-iq/core-topics/pairing-wireless-devices/
    // And docs: https://developer.garmin.com/connect-iq/api-docs/Toybox/Sensor/SensorDelegate.html
    public const CUSTOM_SENSOR_NAME = "Temperature";
    // private var mScanTimer as Timer.Timer?;
    private var mTemperatureData as Float? = null;
    private var mSensorInfo as SensorInfo? = null;
    public var mBleError as String? = null;

    function initialize() {
        SensorDelegate.initialize();
        System.println("SensorDelegate: initialize");

        if (sBle == null) {
            var conn_cb = method(:onBleConnected);
            var data_cb = method(:onBleData);
            var enc_cb = method(:onBleEncrypted);
            var err_cb = method(:onBleError);
            var scan_cb = method(:onBleDeviceFound);
            sBle = new simpleBle(conn_cb, data_cb, enc_cb, err_cb, scan_cb);
        }
    }

    function onBleConnected(connected as Boolean) {
        if (!connected) {
            // Clear the value if we have disconnected. Caching and when to
            // invalidate data is up to the implementor really, and will depend
            // on the type of data.
            mTemperatureData = null;
        }

        if (!isInPairingContext()) {
            // Notify the user ONLY if we are in an activity and not the sensor
            // pairing screen.
            WatchUi.showToast(connected ? "🌡️ connected" : "🌡️ disconnected", null);
        }
    }

    function onBleError(description as String) {
        System.println("Sensor error: " + mBleError);
        mBleError = description;
    }

    function onBleData(data as ByteArray?) as Void {
        System.println("Sensor.onBleData()");

        if (data == null || data.size() < 2) {
            return;
        }

        var t_100 = data.decodeNumber(NUMBER_FORMAT_SINT16, {
            :endianness => ENDIAN_LITTLE,
        });
        var temperature = t_100 / 100.0;

        // Used by getData() which is called by the datafield
        mTemperatureData = temperature;
    }

    public function getData() as Float? {
        return mTemperatureData;
    }

    public function reconnect() {
        // We reconnect based only on the name, to keep the example simple. A
        // real application would store the sensor's serial number & name (e.g.
        // obtained through the Device Information Service) and compare that to
        // the bonded devices list.
        return sBle.reconnect(CUSTOM_SENSOR_NAME);
    }

    function buildSensor(name as String?) as SensorInfo {
        var info = new SensorInfo();

        // Add some canned data
        info.manufacturerId = 0x1337;
        info.partNumber = 42;
        info.softwareVersion = 11111111;
        info.technology = Sensor.SENSOR_TECHNOLOGY_BLE;
        info.type = Sensor.SENSOR_GENERIC;

        // Add the data that matters
        info.enabled = true; // sensor is enabled for pairing
        info.name = name != null ? name : "Custom sensor";

        return info;
    }

    function isInPairingContext() as Boolean {
        // If mSensorInfo is not null, this means the system has called onPair()
        // and this app instance is NOT the datafield but rather the system
        // pairing screen.
        return mSensorInfo != null;
    }

    function onBleEncrypted(name as String?) as Void {
        // Assume we got the right device and attempt to subscribe to data.
        sBle.subscribe();

        if (isInPairingContext()) {
            //  Notify the system that we managed to pair a sensor.
            System.println("Notifying pair complete: " + mSensorInfo);
            System.println("NO SENSOR INFO");
            Sensor.notifyPairComplete(mSensorInfo);
        }
    }

    function onBleDeviceFound(device as BluetoothLowEnergy.ScanResult) as Void {
        System.println("Sensor.onBleDeviceFound()");

        var info = buildSensor(device.getDeviceName());
        info.data = {
            :bleScanResult => device,
        };

        // Setting this will pop an app-defined custom configuration view during
        // the pairing process. The demo is already complex, let's not do that.
        var customConfigurationView = false;

        Sensor.notifyNewSensor(info, customConfigurationView);

        // Here we also stop the scan since we expect only a single sensor. If
        // the user has to make a choice between multiple sensors, do not stop
        // the scan here but rather forward all the scanned sensors (like we're
        // doing above) and wait for the system scan timeout. The user will then be
        // presented with a list.
        sBle.scan(false, null);
        Sensor.notifyScanComplete();
    }

    // Below this line are methods that the system will call into
    // ----------------------------------------------------------
    function onScan() as Boolean {
        System.println("Sensor.onScan()");

        // We will now be called as part of the scanning process. We must call
        // Sensor.notifyNewSensor() for each device we detect and call
        // notifyScanComplete() when we think we found enough devices. Note that
        // as a datafield app we do not have access to the Timer class so can't
        // setup a timeout to stop scanning.
        //
        // If we don't already have a paired device, we will start the scan. If
        // we do have a paired CIQ sensor, we try to reconnect it instead.
        if (sBle.reconnect(CUSTOM_SENSOR_NAME)) {
            // We managed to reconnect. Return BLE control to the system.
            return false;
        }

        // We didn't manage to reconnect. Let's start a timer and start
        // scanning. We want to return `true` to block the system from using
        // bluetooth at the same time.
        // mScanTimer.start(method(:onScanTimeout), 10000, false);
        sBle.scan(true, CUSTOM_SENSOR_NAME);

        return true; // Assume we paired successfully
    }

    function onPair(sensor as SensorInfo) as Boolean {
        System.println("Sensor.onPair()");

        var scanResult = sensor.data[:bleScanResult];
        sBle.connect(scanResult, true);

        // We need to give this exact SensorInfo instance back when we
        // notify pairing success.
        mSensorInfo = sensor;

        return true;
    }

    function pairingRequired() as Boolean {
        System.println("Sensor.pairingRequired()");

        // Returning `true` here makes the system call onScan()
        return true;
    }
}
