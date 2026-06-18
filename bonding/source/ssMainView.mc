import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class ssMainView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // shows "Scan?"
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }
}

class ssMainViewDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();

        System.println("init delegate");
        if (sBle == null) {
            var conn_cb = new Method(MyUiCallbacks, :onBleConnected);
            var data_cb = new Method(MyUiCallbacks, :onDataUpdated);
            var enc_cb = new Method(MyUiCallbacks, :onBleEncrypted);
            var err_cb = new Method(MyUiCallbacks, :onBleError);
            var disc_cb = new Method(MyUiCallbacks, :onBleDisconnected);
            sBle = new simpleBle(conn_cb, data_cb, enc_cb, err_cb, disc_cb);
        }
    }

    function onMenu() as Boolean {
        System.println("Menu button pressed");
        return true;
    }

    function onSelect() as Boolean {
        System.println("Start scanning");
        sBle.scan(true, null);

        var busySpinner = new WatchUi.ProgressBar("Scanning for sensor..", null);
        WatchUi.pushView(
            busySpinner,
            new scanSpinnerDelegate(),
            WatchUi.SLIDE_RIGHT
        );

        return true;
    }

    function onBack() as Boolean {
        System.println("Exiting app");
        sBle.scan(false, null);
        WatchUi.popView(WatchUi.SLIDE_LEFT);
        return true;
    }
}

class scanSpinnerDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Boolean {
        System.println("Stopping scan");
        sBle.scan(false, null);
        return true;
    }
}
