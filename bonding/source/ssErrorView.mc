import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.System;
import Toybox.Lang;

class ssErrorView extends WatchUi.View {
    hidden var errorStatus;

    function makeText(text as String) as WatchUi.Text {
        var obj = new WatchUi.Text({
            :text => text,
            :color => Graphics.COLOR_RED,
            :font => Graphics.FONT_SMALL,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER,
        });
        return obj;
    }

    function initialize(status) {
        errorStatus = status;
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {}

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        makeText("Error! status " + errorStatus).draw(dc);
    }

    function onHide() as Void {}
}

class ssErrorViewDelegate extends WatchUi.BehaviorDelegate {
    function tearDownAndExit() {
        sBle.tearDown(true);
        System.exit();
    }

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Boolean {
        tearDownAndExit();
        return true;
    }
}
