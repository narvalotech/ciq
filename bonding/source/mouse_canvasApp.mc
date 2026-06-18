import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.BluetoothLowEnergy;
using Toybox.System;

var sBle as simpleBle? = null;

module MyUiCallbacks {
    function onBleConnected(device as BluetoothLowEnergy.Device) as Void {
        if (sBle != null && sBle.m_reconnecting) {
            // Background re-connection succeeded; just let the user know with
            // a toast instead of switching views.
            System.println("Reconnected");
            WatchUi.showToast("Connected", null);
            return;
        }
        System.println("Switching to pairing spinner");
        var busySpinner = new WatchUi.ProgressBar("Pairing..", null);
        WatchUi.switchToView(
            busySpinner,
            new encryptionSpinnerDelegate(),
            WatchUi.SLIDE_RIGHT
        );
    }

    function onBleDisconnected(
        device as BluetoothLowEnergy.Device,
        state as BluetoothLowEnergy.ConnectionState
    ) as Void {
        System.println("BLE disconnected, scanning to reconnect");
        WatchUi.showToast("Disconnected", null);
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
        System.println("Encrypted: subscribing and showing canvas");
        sBle.subscribe();
        if (!is_data_view) {
            is_data_view = true;
            WatchUi.switchToView(
                new ssDataView(),
                new ssDataViewDelegate(),
                WatchUi.SLIDE_RIGHT
            );
        }
    }
}

// The compiler expects this exact name:
// [app_name_snake_case]App
class mouse_canvasApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {}

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        sBle.tearDown(true);
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new ssMainView(), new ssMainViewDelegate()];
    }
}

function getApp() as mouse_canvasApp {
    return Application.getApp() as mouse_canvasApp;
}
