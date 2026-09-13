import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class lightsApp extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
    }

    public function onStop(state as Dictionary?) as Void {
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new $.WebRequestView();
        var delegate = new $.WebRequestDelegate();
        return [view, delegate];
    }
}