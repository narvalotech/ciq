import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

const sesame = "topsecret";

class WebRequestDelegate extends WatchUi.BehaviorDelegate {
    public function initialize() {
        WatchUi.BehaviorDelegate.initialize();
    }

    public function onMenu() as Boolean {
        return true;
    }

    public function onSelect() as Boolean {
        return true;
    }
}

class MyMenuDelegate extends WatchUi.Menu2InputDelegate {
    public function onReceive(
        responseCode as Number,
        data as Dictionary or String or Null
    ) as Void {
        if (responseCode == 200) {
            System.println(data);
        } else {
            System.println("Failed to load\nError: " + responseCode.toString());
        }
    }

    private function setLight(name as String, state as Boolean) as Void {
        var options = {
            :responseType
            =>
            Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN,
            :method => Communications.HTTP_REQUEST_METHOD_PUT,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => sesame,
            },
        };

        var body = {
            "type" => "button",
            "name" => name,
            "value" => state ? "on" : "off",
        };

        Communications.makeWebRequest(
            "https://relay.rico.live/light",
            body,
            options,
            method(:onReceive)
        );
    }

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        if (item instanceof WatchUi.ToggleMenuItem) {
            var toggleItem = item as ToggleMenuItem;
            System.println(
                "item: " + item.getId() + "state: " + toggleItem.isEnabled()
            );
            setLight(item.getLabel(), toggleItem.isEnabled());
        }
    }
}

class WebRequestView extends WatchUi.View {
    private var _message as String = "";
    // private var _lights as Array? = null;

    public function initialize() {
        WatchUi.View.initialize();
        getLights();
    }

    public function onLayout(dc) as Void {}

    public function onShow() as Void {
    }

    private function getLights() as Void {
        var options = {
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => sesame,
            },
        };

        Communications.makeWebRequest(
            "https://relay.rico.live/json",
            null,
            options,
            method(:onReceive)
        );
    }

    public function spawnMenu(items as Array) as Void {
        var menu = new WatchUi.Menu2({ :title => "Lights" });
        var delegate;
        for (var i = 0; i < items.size(); i++) {
            var item = items[i];
            menu.addItem(
                new ToggleMenuItem(
                    item,
                    { :enabled => "On", :disabled => "Off" },
                    item,
                    false,
                    null
                )
            );
        }

        delegate = new MyMenuDelegate();
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    public function onReceiveSuccess(
        args as Dictionary or String or Null
    ) as Void {
        var _message;

        if (args instanceof String) {
            _message = args;
        } else if (args instanceof Dictionary) {
            var keys = args.keys();
            _message = "";
            for (var i = 0; i < keys.size(); i++) {
                _message += Lang.format("$1$: $2$\n", [keys[i], args[keys[i]]]);
            }
            System.println("Got data");
            System.println(_message);

            spawnMenu(args["lights"]);
        }
        WatchUi.requestUpdate();
    }

    public function onReceive(
        responseCode as Number,
        data as Dictionary or String or Null
    ) as Void {
        if (responseCode == 200) {
            System.println(data);
            onReceiveSuccess(data);
        } else {
            System.println("Failed to load\nError: " + responseCode.toString());
        }
    }

    public function onUpdate(dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_MEDIUM,
            _message,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    public function onHide() as Void {}
}
