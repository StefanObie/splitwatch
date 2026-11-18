import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// All laps, oldest at the top. Opens at lap 1; DOWN scrolls to later laps.
//   UP / DOWN   scroll (UP at lap 1 goes back to the stopwatch)
//   BACK        back to the stopwatch
//   START       start / stop, same as on the main screen
class LapListView extends WatchUi.View {

    static const ROWS = 4;

    var top as Number = 0;   // index of the first visible lap
    private var _m as StopwatchModel;

    function initialize(m as StopwatchModel) {
        View.initialize();
        _m = m;
    }

    function maxTop() as Number {
        var t = _m.laps.size() - ROWS;
        return t > 0 ? t : 0;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Running time, small, so it's still visible here.
        var ms = _m.elapsed();
        dc.setColor(_m.running || ms == 0 ? Graphics.COLOR_WHITE : Graphics.COLOR_YELLOW,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 13) / 100, Graphics.FONT_MEDIUM, $.formatTime(ms, !_m.running),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w / 5, (h * 23) / 100, w - w / 5, (h * 23) / 100);

        var laps = _m.laps;
        var font = Graphics.FONT_MEDIUM;
        var rowH = (h * 16) / 100;
        var y0 = (h * 32) / 100;
        for (var i = 0; i < ROWS; i++) {
            var idx = top + i;
            if (idx >= laps.size()) {
                break;
            }
            var y = y0 + i * rowH;
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText((w * 30) / 100, y, font, (idx + 1).format("%d"),
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText((w * 79) / 100, y, font, $.formatTime(laps[idx], true),
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Thin scroll bar on the right when not everything fits.
        var n = laps.size();
        if (n > ROWS) {
            var barTop = y0 - rowH / 2;
            var barLen = ROWS * rowH;
            var thumb = (barLen * ROWS) / n;
            var pos = barTop + ((barLen - thumb) * top) / (n - ROWS);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle((w * 90) / 100, barTop, 3, barLen);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle((w * 90) / 100, pos, 3, thumb);
        }
    }
}

class LapListDelegate extends WatchUi.BehaviorDelegate {

    private var _m as StopwatchModel;
    private var _v as LapListView;

    function initialize(m as StopwatchModel, v as LapListView) {
        BehaviorDelegate.initialize();
        _m = m;
        _v = v;
    }

    function onPreviousPage() as Boolean {   // UP
        if (_v.top > 0) {
            _v.top -= 1;
            WatchUi.requestUpdate();
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    function onNextPage() as Boolean {       // DOWN
        if (_v.top < _v.maxTop()) {
            _v.top += 1;
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onSelect() as Boolean {         // START
        if (_m.running) {
            _m.stop();
        } else {
            _m.start();
        }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onMenu() as Boolean {
        return true;
    }
}
