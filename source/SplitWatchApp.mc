import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Entry point. One shared model holds the stopwatch state; the view draws it
// and the delegate turns button presses into model actions.
class SplitWatchApp extends Application.AppBase {

    private var _model as StopwatchModel?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
        var m = _model;
        if (m != null) {
            m.shutdown();
        }
    }

    function getInitialView() {
        var m = new StopwatchModel();
        _model = m;
        return [new SplitWatchView(m), new SplitWatchDelegate(m)];
    }
}
