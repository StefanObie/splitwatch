import Toybox.Lang;
import Toybox.WatchUi;

// Buttons on the Forerunner 945 / 645:
//   START          start / stop
//   BACK (LAP)     running: lap   stopped: reset   at zero: close the app
//   DOWN           lap list (2 or more laps)
//   hold UP        settings
class SplitWatchDelegate extends WatchUi.BehaviorDelegate {

    private var _m as StopwatchModel;

    function initialize(m as StopwatchModel) {
        BehaviorDelegate.initialize();
        _m = m;
    }

    function onSelect() as Boolean {
        if (_m.running) {
            _m.stop();
        } else {
            _m.start();
        }
        return true;
    }

    function onBack() as Boolean {
        if (_m.running) {
            _m.lap();
            return true;
        }
        if (_m.elapsed() > 0) {
            _m.reset();
            return true;
        }
        return false;   // already at zero: let BACK close the app
    }

    function onPreviousPage() as Boolean {
        return true;
    }

    function onNextPage() as Boolean {
        if (_m.laps.size() >= 2) {
            var v = new LapListView(_m);
            WatchUi.pushView(v, new LapListDelegate(_m, v), WatchUi.SLIDE_UP);
        }
        return true;
    }

    function onMenu() as Boolean {
        var s = new SettingsMenu(_m);
        WatchUi.pushView(s.menu, new SettingsMenuDelegate(_m, s), WatchUi.SLIDE_UP);
        return true;
    }
}

// ---- settings menu -----------------------------------------------------------
//
//   Beep interval   12.75  (Off when 0)
//   Vibrate         on / off
//   Sound           on / off

class SettingsMenu {

    var menu as WatchUi.Menu2;
    private var _m as StopwatchModel;
    private var _interval as WatchUi.MenuItem;

    function initialize(m as StopwatchModel) {
        _m = m;
        menu = new WatchUi.Menu2({:title => "Settings"});
        _interval = new WatchUi.MenuItem("Beep interval", "", :interval, null);
        menu.addItem(_interval);
        menu.addItem(new WatchUi.ToggleMenuItem("Vibrate", {:enabled => "On", :disabled => "Off"}, :vibrate, m.vibrateOn, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Sound", {:enabled => "On", :disabled => "Off"}, :sound, m.soundOn, null));
        refresh();
    }

    function refresh() as Void {
        _interval.setSubLabel(_m.intervalCs > 0 ? $.formatTime(_m.intervalMs(), true) : "Off");
        WatchUi.requestUpdate();
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _m as StopwatchModel;
    private var _s as SettingsMenu;

    function initialize(m as StopwatchModel, s as SettingsMenu) {
        Menu2InputDelegate.initialize();
        _m = m;
        _s = s;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :vibrate) {
            _m.setVibrate((item as WatchUi.ToggleMenuItem).isEnabled());
        } else if (id == :sound) {
            _m.setSound((item as WatchUi.ToggleMenuItem).isEnabled());
        } else if (id == :interval) {
            var v = new TimeEditView(_m.intervalCs);
            WatchUi.pushView(v, new TimeEditDelegate(_m, _s, v), WatchUi.SLIDE_LEFT);
        }
    }
}
