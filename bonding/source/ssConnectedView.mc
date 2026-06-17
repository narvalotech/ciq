import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.System;
import Toybox.Lang;

class ssConnectedView extends WatchUi.View {
    function makeText(text as String) as WatchUi.Text {
        var obj = new WatchUi.Text({
            :text => text,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SMALL,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER,
        });
        return obj;
    }

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {}

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        makeText("Connected!").draw(dc);

        sBle.subscribe();
    }

    function onHide() as Void {}
}

class ssConnectedViewDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        System.println("Menu button pressed");
        return true;
    }

    function onSelect() as Boolean {
        return true;
    }

    function onBack() as Boolean {
        System.println("Disconnecting");
        sBle.disconnect();

        WatchUi.popView(WatchUi.SLIDE_LEFT);
        return true;
    }
}
