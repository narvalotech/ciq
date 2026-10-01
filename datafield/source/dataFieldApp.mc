import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.BluetoothLowEnergy;
import Toybox.Sensor;
using Toybox.System;

var sBle as simpleBle? = null;
var sCustomSensor as CustomTemperatureSensor? = null;
var isDatafieldView = false;

// The entry point is set in the manifest.
class dataFieldEntryPoint extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {}

    // onStop() is called when the app exits, both during the pairing process
    // and when the datafield is active.
    //
    // DO NOT disconnect during the pairing process, this will break key
    // distribution: the watch will believe pairing is successful but the peer
    // will think pairing has failed.
    function onStop(state as Dictionary?) as Void {
        var disconnect = isDatafieldView;
        sBle.tearDown(disconnect);
    }

    // Return the initial view of your datafield here.
    // Called only when datafield is active, not during pairing process.
    function getInitialView() as [Views] or [Views, InputDelegates] {
        isDatafieldView = true;
        return [new ssDataView()];
    }

    function getSensorDelegate() as SensorDelegate or Null {
        if (sCustomSensor == null) {
            sCustomSensor = new CustomTemperatureSensor();
        }

        return sCustomSensor;
    }
}

function getApp() as dataFieldEntryPoint {
    return Application.getApp();
}
