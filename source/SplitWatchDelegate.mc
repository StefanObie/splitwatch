import Toybox.Lang;
import Toybox.WatchUi;

// Buttons (Forerunner 945 / 965 / 735XT):
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
        $.openSettings(_m);   // source-ciq3/ or source-ciq2/Platform.mc
        return true;
    }
}
