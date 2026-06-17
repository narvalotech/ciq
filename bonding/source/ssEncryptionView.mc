import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.System;
import Toybox.Lang;

class encryptionSpinnerDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Boolean {
        System.println("Disconnecting");
        sBle.disconnect();
        return true;
    }
}
