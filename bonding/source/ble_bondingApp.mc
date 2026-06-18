import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.BluetoothLowEnergy;
using Toybox.System;

var sBle as simpleBle? = null;

module MyUiCallbacks {
    function onBleConnected(device as BluetoothLowEnergy.Device) as Void {
        System.println("Switching to pairing spinner");
        var busySpinner = new WatchUi.ProgressBar("Pairing..", null);
        WatchUi.switchToView(
            busySpinner,
            new encryptionSpinnerDelegate(),
            WatchUi.SLIDE_RIGHT
        );
    }

    function onBleError(
        device as BluetoothLowEnergy.Device,
        status as BluetoothLowEnergy.Status
    ) as Void {
        System.println("BLE error!");
        WatchUi.switchToView(
            new ssErrorView(status),
            new ssErrorViewDelegate(),
            WatchUi.SLIDE_RIGHT
        );
    }

    function onBleEncrypted(device as BluetoothLowEnergy.Device) as Void {
        System.println("Switching to connected view");
        WatchUi.switchToView(
            new ssConnectedView(),
            new ssConnectedViewDelegate(),
            WatchUi.SLIDE_RIGHT
        );
    }
}

// The compiler expects this exact name:
// [app_name_snake_case]App
class ble_bondingApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {}

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        sBle.tearDown(false);
        System.println("[APP] Stopped, all BLE cleaned up");
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new ssMainView(), new ssMainViewDelegate()];
    }
}

function getApp() as ble_bondingApp {
    return Application.getApp() as ble_bondingApp;
}
