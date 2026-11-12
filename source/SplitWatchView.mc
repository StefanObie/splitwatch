import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// Main screen: the stopwatch time as big as the round screen allows,
// and the latest lap underneath once there is one.
//   running  tenths      "12.7"
//   stopped  hundredths  "12.75" (yellow)
class SplitWatchView extends WatchUi.View {

    private var _m as StopwatchModel;

    // Biggest first. The view picks the first one that fits.
    private var _fonts as Array<Graphics.FontType or WatchUi.FontResource> =
        [] as Array<Graphics.FontType or WatchUi.FontResource>;

    // Remember the font for each time "shape" so we don't measure 10x a second.
    private var _fontCacheKey as String = "";
    private var _fontCacheVal as Graphics.FontType or WatchUi.FontResource = Graphics.FONT_NUMBER_MILD;

    function initialize(m as StopwatchModel) {
        View.initialize();
        _m = m;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _fonts = [
            WatchUi.loadResource(Rez.Fonts.Big0),
            WatchUi.loadResource(Rez.Fonts.Big1),
            WatchUi.loadResource(Rez.Fonts.Big2),
            WatchUi.loadResource(Rez.Fonts.Big3),
            WatchUi.loadResource(Rez.Fonts.Big4),
            WatchUi.loadResource(Rez.Fonts.Big5),
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD
        ] as Array<Graphics.FontType or WatchUi.FontResource>;
        _fontCacheKey = "";
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var n = _m.laps.size();
        var ms = _m.elapsed();
        var text = $.formatTime(ms, !_m.running);

        // With a lap line under it, the time sits a little higher.
        var cy = (n > 0) ? (h * 44) / 100 : h / 2;
        var font = pickFont(dc, text, cy, n > 0 ? (h * 74) / 100 : h);

        dc.setColor(_m.running || ms == 0 ? Graphics.COLOR_WHITE : Graphics.COLOR_YELLOW,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, cy, font, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (n > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (h * 81) / 100, Graphics.FONT_SMALL,
                $.formatTime(_m.laps[n - 1], true),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Largest font whose text fits inside the round screen when centred at
    // cy, without going below maxBottom. Every digit is measured as "8" so
    // the size doesn't jump around while the digits change.
    private function pickFont(dc as Graphics.Dc, text as String, cy as Number, maxBottom as Number)
            as Graphics.FontType or WatchUi.FontResource {
        var key = shapeOf(text) + "@" + cy.format("%d");
        if (key.equals(_fontCacheKey)) {
            return _fontCacheVal;
        }
        var r = dc.getWidth() / 2;
        var chosen = _fonts[_fonts.size() - 1];
        for (var i = 0; i < _fonts.size(); i++) {
            var f = _fonts[i];
            var fh = dc.getFontHeight(f);
            if (cy + fh / 2 > maxBottom) {
                continue;
            }
            // Widest the screen is at the text's top or bottom edge.
            var d = (cy - r).abs() + fh / 2;
            if (d >= r) {
                continue;
            }
            var chord = 2 * Math.sqrt(r * r - d * d) + 8;   // digit corners are rounded
            if (dc.getTextWidthInPixels(shapeOf(text), f) <= chord) {
                chosen = f;
                break;
            }
        }
        _fontCacheKey = key;
        _fontCacheVal = chosen;
        return chosen;
    }

    private function shapeOf(text as String) as String {
        var chars = text.toCharArray();
        var out = "";
        for (var i = 0; i < chars.size(); i++) {
            var c = chars[i];
            var code = c.toNumber();
            if (code >= 48 && code <= 57) {
                out = out + "8";
            } else {
                out = out + c.toString();
            }
        }
        return out;
    }
}
