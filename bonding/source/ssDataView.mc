import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.System;
import Toybox.Lang;

var hid_report as ByteArray?;
var cursorX as Number = 0;
var cursorY as Number = 0;
var drawBuffer as Graphics.BufferedBitmap? = null;

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

        hid_report = value;

        WatchUi.requestUpdate();
    }
}

class ssDataView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {}

    function onShow() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        // Create the offscreen draw buffer on first use
        if (drawBuffer == null) {
            drawBuffer = Graphics.createBufferedBitmap({:width => w, :height => h}).get();
            var bdc = drawBuffer.getDc();
            bdc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            bdc.clear();
            cursorX = w / 2;
            cursorY = h / 2;
        }

        // Consume the latest HID report
        var report = hid_report;
        hid_report = null;

        if (report != null && report.size() >= 3) {
            var buttons = report[0] & 0x07;
            var dx = report.decodeNumber(NUMBER_FORMAT_SINT8, {:offset => 1});
            var dy = report.decodeNumber(NUMBER_FORMAT_SINT8, {:offset => 2});

            cursorX += dx;
            cursorY += dy;

            // Clamp cursor to screen
            if (cursorX < 0)     { cursorX = 0; }
            if (cursorX >= w)    { cursorX = w - 1; }
            if (cursorY < 0)     { cursorY = 0; }
            if (cursorY >= h)    { cursorY = h - 1; }

            var bdc = drawBuffer.getDc();

            if ((buttons & 0x01) != 0) {
                // Left button: draw red
                bdc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
                bdc.fillCircle(cursorX, cursorY, 3);
            } else if ((buttons & 0x02) != 0) {
                // Right button: erase to black
                bdc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                bdc.fillCircle(cursorX, cursorY, 6);
            }
        }

        // Blit the draw buffer to the screen
        dc.drawBitmap(0, 0, drawBuffer);

        // Draw cursor as a filled red circle on top
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.fillCircle(cursorX, cursorY, 5);
    }

    function onHide() as Void {
        drawBuffer = null;
    }
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
        drawBuffer = null;
        System.println("Disconnecting");
        sBle.disconnect();

        WatchUi.popView(WatchUi.SLIDE_LEFT);
        return true;
    }
}
