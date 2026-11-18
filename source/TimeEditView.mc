import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Beep-interval editor: "00:12.75", one digit at a time. 00:00.00 = off.
//   UP / DOWN   change the highlighted digit
//   START       next digit (on the last digit: save)
//   BACK        previous digit (on the first digit: cancel)
class TimeEditView extends WatchUi.View {

    // [min tens, min ones, sec tens, sec ones, hundredths tens, hundredths ones]
    var digits as Array<Number>;
    var pos as Number = 2;   // start on the seconds; most races are under a minute

    private var _max as Array<Number> = [5, 9, 5, 9, 9, 9] as Array<Number>;

    function initialize(cs as Number) {
        View.initialize();
        if (cs < 0 || cs > 359999) {
            cs = 0;
        }
        var min = cs / 6000;
        var sec = (cs / 100) % 60;
        var hun = cs % 100;
        digits = [min / 10, min % 10, sec / 10, sec % 10, hun / 10, hun % 10] as Array<Number>;
        if (min > 0) {
            pos = 1;
        }
    }

    function valueCs() as Number {
        var min = digits[0] * 10 + digits[1];
        var sec = digits[2] * 10 + digits[3];
        var hun = digits[4] * 10 + digits[5];
        return (min * 60 + sec) * 100 + hun;
    }

    function change(delta as Number) as Void {
        var v = digits[pos] + delta;
        if (v > _max[pos]) {
            v = 0;
        }
        if (v < 0) {
            v = _max[pos];
        }
        digits[pos] = v;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 20) / 100, Graphics.FONT_SMALL,
            "Beep interval",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Lay the characters out one by one so the active digit can be marked.
        var font = Graphics.FONT_NUMBER_MILD;
        var chars = [
            digits[0].format("%d"), digits[1].format("%d"), ":",
            digits[2].format("%d"), digits[3].format("%d"), ".",
            digits[4].format("%d"), digits[5].format("%d")
        ] as Array<String>;
        var digitSlot = [0, 1, -1, 2, 3, -1, 4, 5] as Array<Number>;

        var gap = 4;
        var total = 0;
        for (var i = 0; i < chars.size(); i++) {
            total += dc.getTextWidthInPixels(chars[i], font) + gap;
        }
        total -= gap;

        var x = (w - total) / 2;
        var y = h / 2;
        var fh = dc.getFontHeight(font);
        for (var i = 0; i < chars.size(); i++) {
            var cw = dc.getTextWidthInPixels(chars[i], font);
            var selected = (digitSlot[i] == pos);
            dc.setColor(selected ? Graphics.COLOR_ORANGE : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, font, chars[i], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            if (selected) {
                dc.fillRectangle(x, y + fh / 2 + 2, cw, 3);
            }
            x += cw + gap;
        }

        if (valueCs() == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (h * 76) / 100, Graphics.FONT_SMALL, "Off",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class TimeEditDelegate extends WatchUi.BehaviorDelegate {

    private var _m as StopwatchModel;
    private var _v as TimeEditView;
    private var _onSaved as Method?;   // called after saving, e.g. to refresh the menu

    function initialize(m as StopwatchModel, v as TimeEditView, onSaved as Method?) {
        BehaviorDelegate.initialize();
        _m = m;
        _v = v;
        _onSaved = onSaved;
    }

    function onPreviousPage() as Boolean {   // UP
        _v.change(1);
        return true;
    }

    function onNextPage() as Boolean {       // DOWN
        _v.change(-1);
        return true;
    }

    function onSelect() as Boolean {         // START
        if (_v.pos < 5) {
            _v.pos += 1;
            WatchUi.requestUpdate();
        } else {
            _m.setIntervalCs(_v.valueCs());
            var cb = _onSaved;
            if (cb != null) {
                cb.invoke();
            }
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }

    function onBack() as Boolean {           // BACK
        if (_v.pos > 0) {
            _v.pos -= 1;
            WatchUi.requestUpdate();
        } else {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }

    function onMenu() as Boolean {
        return true;
    }
}
