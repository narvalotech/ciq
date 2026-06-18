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
    public var m_DisconnectedCallback as Method? = null;
    public var m_reconnecting as Boolean = false;
    public var pairedDevice as BluetoothLowEnergy.Device? = null;
    public var isSubscribed = false;

    function initialize(
        connectedCallback,
        dataCallback,
        encryptedCallback,
        errorCallback,
        disconnectedCallback
    ) {
        System.println("init simpleBle");
        myBleDelegate = new MyBleDelegate(self);
        BluetoothLowEnergy.setDelegate(myBleDelegate);
        m_ConnectedCallback = connectedCallback;
        m_DataCallback = dataCallback;
        m_EncryptedCallback = encryptedCallback;
        m_ErrorCallback = errorCallback;
        m_DisconnectedCallback = disconnectedCallback;

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
            // HID Service (0x1812), Protocol Mode (0x2A4E) + Boot Mouse Input Report (0x2A33)
            var profile = {
                :uuid => sigUuid(0x1812),
                :characteristics => [
                    {
                        :uuid => sigUuid(0x2A4E),
                    },
                    {
                        :uuid => sigUuid(0x2A33),
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
            System.println("Subscribing: setting Boot Protocol mode");
            if (pairedDevice != null) {
                var svc = pairedDevice.getService(sigUuid(0x1812));
                if (svc == null) {
                    System.println("svc null");
                    return;
                }
                // Write 0x00 to Protocol Mode (0x2A4E) to enter Boot Protocol mode.
                // The CCCD write on 0x2A33 is chained in onCharacteristicWrite.
                var protMode = svc.getCharacteristic(sigUuid(0x2A4E));
                if (protMode == null) {
                    System.println("Protocol Mode chr null");
                    return;
                }
                protMode.requestWrite([0x00]b, {:writeType => BluetoothLowEnergy.WRITE_TYPE_DEFAULT});
            }
        } catch (ex) {
            System.println("Error subscribing: " + ex);
        }
    }

    function subscribeBootReport() {
        try {
            if (pairedDevice != null) {
                var svc = pairedDevice.getService(sigUuid(0x1812));
                if (svc == null) { return; }
                var chr = svc.getCharacteristic(sigUuid(0x2A33));
                if (chr == null) { System.println("boot report chr null"); return; }
                var dsc = chr.getDescriptor(sigUuid(0x2902));
                if (dsc == null) { System.println("cccd null"); return; }
                System.println("Writing CCCD for Boot Mouse Input Report");
                dsc.requestWrite([0x01, 0x00]b);
            }
        } catch (ex) {
            System.println("Error writing CCCD: " + ex);
        }
    }

    function tearDown(disconnect as Boolean) {
        scan(false, null);
        if (disconnect) {
            disconnectAll();
        }

        isSubscribed = false;
    }

    function on_connected(device, state) {
        System.println("Connection state change: " + state);

        if (state == BluetoothLowEnergy.CONNECTION_STATE_CONNECTED) {
            // Always adopt the device handed to us by the connection callback.
            // On a background reconnect pairDevice() can throw (the bonded
            // device is already pairing), leaving pairedDevice null even though
            // the link came up, which would make subscribe() silently no-op.
            pairedDevice = device;
            if (m_ConnectedCallback != null) {
                m_ConnectedCallback.invoke(device);
            }
            m_reconnecting = false;
        } else {
            // Disconnected: notify the app, then start scanning again in the
            // background so we can transparently re-connect to the bonded
            // device and surface a "connected" toast once it returns.
            isSubscribed = false;
            pairedDevice = null;
            if (m_DisconnectedCallback != null) {
                m_DisconnectedCallback.invoke(device, state);
            }
            m_reconnecting = true;
            scan(true, m_match);
        }
    }

    function on_encryption(device, state) {
        System.println("Encryption state change: " + state);

        if (m_EncryptedCallback != null) {
            if (state == BluetoothLowEnergy.STATUS_SUCCESS) {
                m_EncryptedCallback.invoke(device);
            } else {
                m_ErrorCallback.invoke(device, state);
            }
        }
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
        var hidsUuid = sigUuid(0x1812);
        var result = scanResults.next() as BluetoothLowEnergy.ScanResult?;
        while (result != null) {
            System.println("Scan result: " + result.getDeviceName());
            var uuids = result.getServiceUuids();
            if (uuids != null) {
                var uuid = uuids.next() as BluetoothLowEnergy.Uuid?;
                while (uuid != null) {
                    if (uuid.equals(hidsUuid)) {
                        System.println("Found HIDS device, connecting");
                        bleInstance.connect(result, true);
                        break;
                    }
                    uuid = uuids.next() as BluetoothLowEnergy.Uuid?;
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
        bleInstance.on_connected(device, state);
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
            // ATT 0x12 (18) = Database Out of Sync: stale bond cache.
            // Unpair so the next connection does a fresh pair.
            System.println("Subscription failed: status " + status + ", clearing bond");
            bleInstance.isSubscribed = false;
            bleInstance.tearDown(true);
            if (bleInstance.m_ErrorCallback != null) {
                bleInstance.m_ErrorCallback.invoke(bleInstance.pairedDevice, status);
            }
        }
    }

    public function onCharacteristicWrite(
        characteristic as Characteristic,
        status as Status
    ) as Void {
        if (characteristic.getUuid().equals(sigUuid(0x2A4E))) {
            if (status == BluetoothLowEnergy.STATUS_SUCCESS) {
                System.println("Boot Protocol mode set, subscribing to CCCD");
                bleInstance.subscribeBootReport();
            } else {
                System.println("Protocol Mode write failed: " + status);
                bleInstance.isSubscribed = false;
                bleInstance.tearDown(true);
                if (bleInstance.m_ErrorCallback != null) {
                    bleInstance.m_ErrorCallback.invoke(bleInstance.pairedDevice, status);
                }
            }
        }
    }

    public function onEncryptionStatus(
        device as Device,
        status as Status
    ) as Void {
        bleInstance.on_encryption(device, status);
    }

    public function onCharacteristicChanged(
        characteristic as Characteristic,
        value as ByteArray
    ) as Void {
        System.println("notification value: " + value);
        bleInstance.m_DataCallback.invoke(characteristic, value);
    }
}
