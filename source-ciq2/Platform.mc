import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Connect IQ 2.4 watches (Forerunner 735XT): no Menu2 there, so settings
// use a plain menu that reopens after each change. The Connect IQ 3+ version is source-ciq3/Platform.mc.

function loadSetting(key as String) as Application.PropertyValueType? {
    return Storage.getValue(key);
}

function saveSetting(key as String, value as Application.PropertyValueType) as Void {
    Storage.setValue(key, value);
}

function watchTonesOn() as Boolean {
    var s = System.getDeviceSettings();
    return !(s has :tonesOn) || s.tonesOn;
}

function onOff(on as Boolean) as String {
    return on ? "On" : "Off";
}

function openSettings(m as StopwatchModel) as Void {
    var menu = new WatchUi.Menu();
    menu.setTitle("Settings");
    menu.addItem("Interval " + (m.intervalCs > 0 ? $.formatTime(m.intervalMs(), true) : "Off"), :interval);
    menu.addItem("Vibrate: " + $.onOff(m.vibrateOn), :vibrate);
    var snd = "Sound: " + $.onOff(m.soundOn);
    if (m.soundOn && !$.watchTonesOn()) {
        snd = "Sound: tones off";
    }
    menu.addItem(snd, :sound);
    WatchUi.pushView(menu, new SettingsMenuDelegate(m), WatchUi.SLIDE_UP);
}

class SettingsMenuDelegate extends WatchUi.MenuInputDelegate {

    private var _m as StopwatchModel;

    function initialize(m as StopwatchModel) {
        MenuInputDelegate.initialize();
        _m = m;
    }

    // The menu closes itself after a pick; toggles reopen it to show the change.
    function onMenuItem(item as Symbol) as Void {
        if (item == :vibrate) {
            _m.setVibrate(!_m.vibrateOn);
            $.openSettings(_m);
        } else if (item == :sound) {
            _m.setSound(!_m.soundOn);
            $.openSettings(_m);
        } else if (item == :interval) {
            var v = new TimeEditView(_m.intervalCs);
            WatchUi.pushView(v, new TimeEditDelegate(_m, v, null), WatchUi.SLIDE_LEFT);
        }
    }
}
