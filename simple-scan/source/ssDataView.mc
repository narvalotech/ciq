import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.System;
import Toybox.Lang;

var temp_encoded as ByteArray?;

module MyUiCallbacks {
    var is_data_view as Boolean = false;

    function onDataUpdated(characteristic, value as ByteArray) as Void {
        if (!is_data_view) {
            is_data_view = true;
            WatchUi.switchToView(
                new ssDataView(),
                new ssDataViewDelegate(),
                WatchUi.SLIDE_RIGHT
            );
        }

        temp_encoded = value;

        WatchUi.requestUpdate();
    }
}

class ssDataView extends WatchUi.View {
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

        if (temp_encoded == null || temp_encoded.size() < 2) {
            return;
        }

        var t_100 = temp_encoded.decodeNumber(NUMBER_FORMAT_SINT16, {
            :endianness => ENDIAN_LITTLE,
        });
        var temperature = t_100 / 100.0;

        makeText("Temperature\n🌡️ " + temperature.format("%.2f") + " C").draw(dc);
    }

    function onHide() as Void {}
}

class ssDataViewDelegate extends WatchUi.BehaviorDelegate {
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
        MyUiCallbacks.is_data_view = false;
        System.println("Disconnecting");
        sBle.disconnect();

        WatchUi.popView(WatchUi.SLIDE_LEFT);
        return true;
    }
}
