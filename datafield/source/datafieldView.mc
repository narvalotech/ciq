import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.System;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.Time;
import Toybox.FitContributor;

class ssDataView extends WatchUi.SimpleDataField {
    var mPairStatus = false;
    var mCustomSensor as CustomTemperatureSensor? = null;
    private var mFitField as FitContributor.Field? = null;
    const NO_DATA_STR = "🌡️ --";
    const CUSTOM_FIELD_ID = 0x3456; // This can be anything

    function initialize() {
        SimpleDataField.initialize();

        // Grab the already-initialized custom sensor object
        mCustomSensor = getApp().getSensorDelegate() as CustomTemperatureSensor;

        // Try to reconnect to our sensor.
        mPairStatus = mCustomSensor.reconnect();
    }

    function compute(info as Info) as Numeric or Duration or String or Null {
        var temperature = mCustomSensor.getData();

        if (mCustomSensor.mBleError != null) {
            return NO_DATA_STR;
        }

        if (!mPairStatus || temperature == null) {
            System.println("Sensor not connected");
            return NO_DATA_STR;
        }

        // Write to the .FIT file, ONLY if the activity is running
        if (info.timerState == Activity.TIMER_STATE_ON) {
            writeFit(temperature);
        }

        // Note that the data returned here isn't written to the .FIT file. This
        // means that it's perfectly fine to be cute and display an emoji in a
        // string to the user.
        var dataString = "🌡️ " + temperature.format("%.2f") + " C";
        return dataString;
    }

    function writeFit(value as Float) {
        if (!(self has :createField)) {
            System.println("Can't write to .FIT");
            return;
        }

        if (mFitField == null) {
            mFitField = createField(
                "Custom temperature",
                CUSTOM_FIELD_ID,
                FitContributor.DATA_TYPE_FLOAT,
                {
                    :mesgType => FitContributor.MESG_TYPE_RECORD,
                    :units => "Celsius",
                }
            );
        }

        mFitField.setData(value);
    }
}
