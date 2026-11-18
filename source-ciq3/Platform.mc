import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Connect IQ 3.0+ watches (Forerunner 945, 965 ...): settings in Storage,
// Menu2 settings menu with toggles.
// The Connect IQ 2 version for the Forerunner 735XT is source-ciq2/Platform.mc.

function loadSetting(key as String) as Application.PropertyValueType? {
    return Storage.getValue(key);
}

function saveSetting(key as String, value as Application.PropertyValueType) as Void {
    Storage.setValue(key, value);
}

// The watch only plays app sounds when its own tones are on
// (watch settings: Sound & Vibe / Alert Tones).
function watchTonesOn() as Boolean {
    var s = System.getDeviceSettings();
    return !(s has :tonesOn) || s.tonesOn;
}

function openSettings(m as StopwatchModel) as Void {
    var s = new SettingsMenu(m);
    WatchUi.pushView(s.menu, new SettingsMenuDelegate(m, s), WatchUi.SLIDE_UP);
}

// ---- settings menu -----------------------------------------------------------
//
//   Beep interval   12.75  (Off when 0)
//   Vibrate         on / off
//   Sound           on / off  ("Watch tones are off" when the watch mutes apps)

class SettingsMenu {

    var menu as WatchUi.Menu2;
    private var _m as StopwatchModel;
    private var _interval as WatchUi.MenuItem;
    private var _sound as WatchUi.ToggleMenuItem;

    function initialize(m as StopwatchModel) {
        _m = m;
        menu = new WatchUi.Menu2({:title => "Settings"});
        _interval = new WatchUi.MenuItem("Beep interval", "", :interval, null);
        menu.addItem(_interval);
        menu.addItem(new WatchUi.ToggleMenuItem("Vibrate", {:enabled => "On", :disabled => "Off"}, :vibrate, m.vibrateOn, null));
        _sound = new WatchUi.ToggleMenuItem("Sound", {:enabled => "On", :disabled => "Off"}, :sound, m.soundOn, null);
        menu.addItem(_sound);
        refresh();
    }

    function refresh() as Void {
        _interval.setSubLabel(_m.intervalCs > 0 ? $.formatTime(_m.intervalMs(), true) : "Off");
        if (_m.soundOn && !$.watchTonesOn()) {
            _sound.setSubLabel("Watch tones are off");
        } else {
            _sound.setSubLabel({:enabled => "On", :disabled => "Off"});
        }
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
            _s.refresh();
        } else if (id == :interval) {
            var v = new TimeEditView(_m.intervalCs);
            WatchUi.pushView(v, new TimeEditDelegate(_m, v, _s.method(:refresh)), WatchUi.SLIDE_LEFT);
        }
    }
}
