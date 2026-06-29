import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.BluetoothLowEnergy;
using Toybox.System;
import Toybox.Lang;

function sigUuid(uuid16 as Number) as BluetoothLowEnergy.Uuid {
    // This is the Bluetooth SIG-defined UUID base for 16-bit UUIDs.
    var uuid16_as_str = uuid16.format("%04X");
    var uuid128 = "0000" + uuid16_as_str + "-0000-1000-8000-00805F9B34FB";
    return BluetoothLowEnergy.stringToUuid(uuid128);
}

function prettyPrintScanResult(
    result as BluetoothLowEnergy.ScanResult
) as Void {
    System.println("ScanResult {");
    System.println("  name: " + result.getDeviceName());
    System.println("  rssi: " + result.getRssi());
    System.println("  raw: " + result.toString());
    var uuids = result.getServiceUuids();
    System.println("  uuids: [");
    for (var uuid = uuids.next(); uuid != null; uuid = uuids.next()) {
        System.println("    " + uuid);
    }
    System.println("  ]");
    System.println("}");
}

function prettyPrintDevice(device as BluetoothLowEnergy.Device) as Void {
    System.println("Device {");
    System.println("  name:        " + device.getName());
    System.println("  isConnected: " + device.isConnected());
    System.println("  isBonded:    " + device.isBonded());
    System.println("  services:    " + device.getServices());
    System.println("  raw:    " + device.toString());
    System.println("}");
}

function matchesString(main as String?, sub as String?) as Boolean {
    if (main == null || sub == null) {
        return false;
    }

    return main.find(sub) != null;
}

class simpleBle {
    private var myBleDelegate;
    hidden var profilesRegistered = false;
    public var m_match as String? = null;
    public var m_ConnectedCallback as Method? = null;
    public var m_DataCallback as Method? = null;
    public var m_EncryptedCallback as Method? = null;
    public var m_ErrorCallback as Method? = null;
    public var m_DeviceFoundCallback as Method? = null;
    public var pairedDevice as BluetoothLowEnergy.Device? = null;
    public var isSubscribed = false;

    function initialize(
        connectedCallback,
        dataCallback,
        encryptedCallback,
        errorCallback,
        deviceFoundCallback
    ) {
        System.println("init simpleBle");
        myBleDelegate = new MyBleDelegate(self);
        BluetoothLowEnergy.setDelegate(myBleDelegate);
        m_ConnectedCallback = connectedCallback;
        m_DataCallback = dataCallback;
        m_EncryptedCallback = encryptedCallback;
        m_ErrorCallback = errorCallback;
        m_DeviceFoundCallback = deviceFoundCallback;

        ppBonds();

        if (!profilesRegistered) {
            // BluetoothLowEnergy pretty much requires the layout of each
            // service you want to interact with to to be defined and registered
            // before the connection attempt.
            //
            // The CCCD needs to be added for each characteristic that you want
            // to subscribe to. Use one registerProfile() call per-service.
            //
            // All UUIDs have to be in 128-bit form. Here we register a
            // SIG-defined service and characteristic (temperature), so we
            // convert 16-bit SIG-defined UUIDs to their long form.
            //
            // Custom services are supported, so we could've used any valid
            // 128-bit UUID.
            var profile = {
                :uuid => sigUuid(0x181a),
                :characteristics => [
                    {
                        :uuid => sigUuid(0x2a6e),
                        :descriptors => [sigUuid(0x2902)],
                    },
                ],
            };
            BluetoothLowEnergy.registerProfile(profile);
            profilesRegistered = true;
        }
    }

    function reconnect(match as String?) as Boolean {
        try {
            var iter = BluetoothLowEnergy.getBondedDevices();
            var sr = iter.next() as BluetoothLowEnergy.ScanResult?;
            while (sr != null) {
                var name = sr.getDeviceName();
                if (match == null || matchesString(name, match)) {
                    connect(sr, true);
                    return true;
                }
                sr = iter.next() as BluetoothLowEnergy.ScanResult?;
            }
        } catch (e) {}

        return false;
    }

    function scan(enable as Boolean, match as String?) as Void {
        m_match = match;
        try {
            if (enable) {
                if (reconnect(match)) {
                    // We re-connected to a matching previously bonded device
                    return;
                }

                BluetoothLowEnergy.setScanState(
                    BluetoothLowEnergy.SCAN_STATE_SCANNING
                );
            } else {
                BluetoothLowEnergy.setScanState(
                    BluetoothLowEnergy.SCAN_STATE_OFF
                );
            }
        } catch (ex) {
            System.println("scan error");
        }
    }

    function connect(
        result as BluetoothLowEnergy.ScanResult,
        secure as Boolean
    ) {
        if (secure) {
            BluetoothLowEnergy.setConnectionStrategy(
                BluetoothLowEnergy.CONNECTION_STRATEGY_SECURE_PAIR_BOND
            );
        } else {
            BluetoothLowEnergy.setConnectionStrategy(
                BluetoothLowEnergy.CONNECTION_STRATEGY_DEFAULT
            );
        }

        System.println("Connecting to " + result.getDeviceName());
        scan(false, null);
        if (pairedDevice == null) {
            try {
                pairedDevice = BluetoothLowEnergy.pairDevice(result);
            } catch (ex) {
                System.println("Couldn't pair device: " + ex);
            }
        }
    }

    function disconnect() {
        try {
            if (pairedDevice != null) {
                var dev = pairedDevice;
                pairedDevice = null;
                // Note: This will not remove a bonded device, it just disconnects it.
                BluetoothLowEnergy.unpairDevice(dev);
            }
        } catch (ex) {}
    }

    function disconnectAll() {
        System.println("disconnectAll -- start");
        // Disconnect all devices from this session.
        //
        // Note: unpairDevice()'s name is misleading: the only thing it does is
        // DISCONNECT the link. Bonded devices will remain bonded and
        // re-connectable via the getBondedDevices() iterator the next time the
        // app is opened. The bonded devices persist across app sessions; to
        // remove them, the user has to go to the "Sensors" settings menu and
        // manually remove them.
        try {
            var iter = BluetoothLowEnergy.getPairedDevices();
            var device = iter.next() as BluetoothLowEnergy.Device?;
            while (device != null) {
                try {
                    System.println("Disconnecting: " + device.getName());
                    BluetoothLowEnergy.unpairDevice(device);
                } catch (ex) {}
                device = iter.next() as BluetoothLowEnergy.Device?;
            }
        } catch (e) {}
        System.println("disconnectAll -- end");
    }

    function ppBonds() {
        // Pretty-print:
        // - paired devices (currently connected devices)
        // - bonds (not connected, remembered)
        {
            var iter = BluetoothLowEnergy.getPairedDevices();
            var device = iter.next() as BluetoothLowEnergy.Device?;
            while (device != null) {
                try {
                    prettyPrintDevice(device);
                } catch (ex) {}
                device = iter.next() as BluetoothLowEnergy.Device?;
            }
        }

        {
            var iter = BluetoothLowEnergy.getBondedDevices();
            var sr = iter.next() as BluetoothLowEnergy.ScanResult?;
            while (sr != null) {
                try {
                    prettyPrintScanResult(sr);
                } catch (ex) {}
                sr = iter.next() as BluetoothLowEnergy.ScanResult?;
            }
        }
    }

    function subscribe() {
        try {
            if (isSubscribed) {
                return;
            }
            isSubscribed = true;
            // Hardcode the characteristic we want for now: 0x2a6e
            System.println("Subscribing");
            if (pairedDevice != null) {
                var svc = pairedDevice.getService(sigUuid(0x181a));
                if (svc == null) {
                    System.println("svc null");
                    return;
                }
                var chr = svc.getCharacteristic(sigUuid(0x2a6e));
                if (chr == null) {
                    System.println("chr null");
                    return;
                }
                var dsc = chr.getDescriptor(sigUuid(0x2902));
                if (dsc == null) {
                    System.println("dsc null");
                    return;
                }
                System.println("request cccd write");

                // Subscribe by writing 01 00 to CCCD
                dsc.requestWrite([0x01, 0x00]b);
            }
        } catch (ex) {
            System.println("Error subscribing");
        }
    }

    function tearDown(disconnect as Boolean) {
        scan(false, null);
        if (disconnect) {
            disconnectAll();
        }

        isSubscribed = false;
    }
}

class MyBleDelegate extends BluetoothLowEnergy.BleDelegate {
    private var bleInstance as simpleBle;

    public function initialize(inst as simpleBle) {
        bleInstance = inst;
        BleDelegate.initialize();
    }

    public function onScanResults(
        scanResults as BluetoothLowEnergy.Iterator
    ) as Void {
        var result = scanResults.next() as BluetoothLowEnergy.ScanResult?;
        while (result != null) {
            var name = result.getDeviceName();
            if (name != null) {
                System.println("Scan result: " + result.getDeviceName());

                if (
                    bleInstance.m_match != null &&
                    name.find(bleInstance.m_match) != null
                ) {
                    var cb = bleInstance.m_DeviceFoundCallback;
                    if (cb != null) {
                        cb.invoke(result);
                    }
                }
            }
            result = scanResults.next() as BluetoothLowEnergy.ScanResult?;
        }
        WatchUi.requestUpdate();
    }

    public function onConnectedStateChanged(
        device as Device,
        state as ConnectionState
    ) as Void {
        System.println("Connection state change: " + state);

        var conn_cb = bleInstance.m_ConnectedCallback;
        var err_cb = bleInstance.m_ErrorCallback;

        if (conn_cb == null || err_cb == null) {
            System.println("error: Callbacks not registered");
            return;
        }

        switch (state) {
            case BluetoothLowEnergy.CONNECTION_STATE_CONNECTED:
                conn_cb.invoke(true);
                break;
            case BluetoothLowEnergy.CONNECTION_STATE_DISCONNECTED:
                conn_cb.invoke(false);
                break;
            case BluetoothLowEnergy.CONNECTION_STATE_REJECTED:
                conn_cb.invoke(false);
                err_cb.invoke("Connection error: " + state);
                break;
            default:
                break;
        }
    }

    public function onProfileRegister(
        uuid as BluetoothLowEnergy.Uuid,
        status as BluetoothLowEnergy.Status
    ) as Void {
        System.println("Profile registered: " + uuid + " status=" + status);
    }

    public function onDescriptorWrite(
        descriptor as Descriptor,
        status as Status
    ) as Void {
        if (status == BluetoothLowEnergy.STATUS_SUCCESS) {
            System.println("Subscribed!");
        } else {
            System.println("Subscription failed: status " + status);
        }
    }

    public function onEncryptionStatus(
        device as Device,
        status as Status
    ) as Void {
        System.println("Encryption state change: " + status);

        var enc_cb = bleInstance.m_EncryptedCallback;
        var err_cb = bleInstance.m_ErrorCallback;

        if (enc_cb != null && err_cb != null) {
            if (status == BluetoothLowEnergy.STATUS_SUCCESS) {
                enc_cb.invoke(device.getName());
            } else {
                err_cb.invoke("Encryption error: " + status);
            }
        }
    }

    public function onCharacteristicChanged(
        characteristic as Characteristic,
        value as ByteArray
    ) as Void {
        System.println("notification value: " + value);
        bleInstance.m_DataCallback.invoke(value);
    }
}
