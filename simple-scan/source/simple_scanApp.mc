import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.BluetoothLowEnergy;
using Toybox.System;

var sBle as simpleBle? = null;

module MyUiCallbacks {
    function onBleConnected(device as BluetoothLowEnergy.Device) as Void {
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
class simple_scanApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {}

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        sBle.tearDown();
        System.println("[APP] Stopped, all BLE cleaned up");
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new ssMainView(), new ssMainViewDelegate()];
    }
}

function getApp() as simple_scanApp {
    return Application.getApp() as simple_scanApp;
}
