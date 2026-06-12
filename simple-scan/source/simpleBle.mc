import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.BluetoothLowEnergy;
using Toybox.System;
import Toybox.Lang;

class simpleBle {
    private var myBleDelegate;
    hidden var profilesRegistered = false;
    public var m_match as String? = null;
    public var m_ConnectedCallback as Method? = null;
    public var m_DataCallback as Method? = null;
    public var pairedDevice as BluetoothLowEnergy.Device? = null;
    public var isSubscribed = false;

    function initialize(connectedCallback, dataCallback) {
        System.println("init simpleBle");
        myBleDelegate = new MyBleDelegate(self);
        BluetoothLowEnergy.setDelegate(myBleDelegate);
        m_ConnectedCallback = connectedCallback;
        m_DataCallback = dataCallback;

        if (!profilesRegistered) {
            var profile = {
                :uuid => BluetoothLowEnergy.stringToUuid(
                    "0000181A-0000-1000-8000-00805F9B34FB"
                ),
                :characteristics => [
                    {
                        :uuid => BluetoothLowEnergy.stringToUuid(
                            "00002A6E-0000-1000-8000-00805F9B34FB"
                        ),
                        :descriptors => [
                            BluetoothLowEnergy.stringToUuid(
                                "00002902-0000-1000-8000-00805F9B34FB"
                            ),
                        ],
                    },
                ],
            };
            BluetoothLowEnergy.registerProfile(profile);
            profilesRegistered = true;
        }
    }

    function scan(enable as Boolean, match as String?) as Void {
        m_match = match;
        try {
            if (enable) {
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

    function connect(result as BluetoothLowEnergy.ScanResult) {
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
                BluetoothLowEnergy.unpairDevice(dev);
            }
        } catch (ex) {}
    }

    function unpairAll() {
        // Unpair ALL paired devices to avoid lingering state
        try {
            var iter = BluetoothLowEnergy.getPairedDevices();
            var device = iter.next() as BluetoothLowEnergy.Device?;
            while (device != null) {
                try {
                    BluetoothLowEnergy.unpairDevice(device);
                    System.println("[BLE] Unpaired device on stop");
                } catch (ex) {}
                device = iter.next() as BluetoothLowEnergy.Device?;
            }
        } catch (e) {}
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
                var svc = pairedDevice.getService(
                    BluetoothLowEnergy.stringToUuid(
                        "0000181A-0000-1000-8000-00805F9B34FB"
                    )
                );
                if (svc == null) {
                    System.println("svc null");
                    return;
                }
                var chr = svc.getCharacteristic(
                    BluetoothLowEnergy.stringToUuid(
                        "00002A6E-0000-1000-8000-00805F9B34FB"
                    )
                );
                if (chr == null) {
                    System.println("chr null");
                    return;
                }
                var dsc = chr.getDescriptor(
                    BluetoothLowEnergy.stringToUuid(
                        "00002902-0000-1000-8000-00805F9B34FB"
                    )
                );
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

    function tearDown() {
        scan(false, null);
        unpairAll();
        isSubscribed = false;
    }

    function on_connected(device, state) {
        if (m_ConnectedCallback != null) {
            m_ConnectedCallback.invoke(device);
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
        var result = scanResults.next() as BluetoothLowEnergy.ScanResult?;
        while (result != null) {
            var name = result.getDeviceName();
            if (name != null) {
                System.println("[BLE] Scan result: " + result.getDeviceName());

                if (
                    bleInstance.m_match != null &&
                    name.find(bleInstance.m_match) != null
                ) {
                    System.println("Telling UI to connect");
                    bleInstance.connect(result);
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
        System.println("Connected!");
        bleInstance.on_connected(device, state);
    }

    public function onProfileRegister(
        uuid as BluetoothLowEnergy.Uuid,
        status as BluetoothLowEnergy.Status
    ) as Void {
        System.println(
            "[BLE] Profile registered: " + uuid + " status=" + status
        );
    }

    public function onDescriptorWrite(
        descriptor as Descriptor,
        status as Status
    ) as Void {
        System.println("Subscribed!");
    }

    public function onCharacteristicChanged(
        characteristic as Characteristic,
        value as ByteArray
    ) as Void {
        System.println("notification value: " + value);
        bleInstance.m_DataCallback.invoke(characteristic, value);
    }
}
