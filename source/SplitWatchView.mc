import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// Main screen: the stopwatch time as big as the round screen allows,
// and the latest lap underneath once there is one.
//   running  tenths      "12.7"
//   stopped  hundredths  "12.75" (yellow)
// Stopped past a minute, "1:02.75" doesn't fit big in one size, so the
// hundredths are drawn smaller: big "1:02" + small ".75".
class SplitWatchView extends WatchUi.View {

    static const NBIG = 9;        // custom fonts Big0..Big8, biggest first
    static const FRAC_STEP = 3;   // hundredths use the font this many sizes down

    private var _m as StopwatchModel;

    // Big0..Big8, then two system fonts as a last resort. Biggest first.
    private var _fonts as Array<Graphics.FontType or WatchUi.FontResource> =
        [] as Array<Graphics.FontType or WatchUi.FontResource>;

    // Remember the pick for each time "shape" so we don't measure 10x a second.
    private var _cacheKey as String = "";
    private var _cacheVal as Number = 0;

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
            WatchUi.loadResource(Rez.Fonts.Big6),
            WatchUi.loadResource(Rez.Fonts.Big7),
            WatchUi.loadResource(Rez.Fonts.Big8),
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD
        ] as Array<Graphics.FontType or WatchUi.FontResource>;
        _cacheKey = "";
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
        var maxBottom = n > 0 ? (h * 74) / 100 : h;

        dc.setColor(_m.running || ms == 0 ? Graphics.COLOR_WHITE : Graphics.COLOR_YELLOW,
            Graphics.COLOR_TRANSPARENT);

        var dot = text.find(".");
        var i = -1;
        if (!_m.running && text.find(":") != null && dot != null) {
            var main = text.substring(0, dot) as String;
            var frac = text.substring(dot, text.length()) as String;
            i = pick(dc, main, frac, cy, maxBottom);
            if (i >= 0) {
                // Big main part and small hundredths, bottoms lined up.
                var f = _fonts[i];
                var g = _fonts[i + FRAC_STEP];
                var mw = dc.getTextWidthInPixels(main, f);
                var x = (w - mw - dc.getTextWidthInPixels(frac, g)) / 2;
                var bottom = cy + dc.getFontHeight(f) / 2;
                dc.drawText(x, cy, f, main, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.drawText(x + mw, bottom - dc.getFontHeight(g) / 2, g, frac,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
        if (i < 0) {
            i = pick(dc, text, "", cy, maxBottom);
            dc.drawText(w / 2, cy, _fonts[i], text,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        if (n > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (h * 81) / 100, Graphics.FONT_SMALL,
                $.formatTime(_m.laps[n - 1], true),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Index of the largest font for which the text fits inside the screen
    // when centred at cy, without going below maxBottom. With frac given,
    // frac is drawn FRAC_STEP sizes smaller after main, and -1 means it
    // doesn't fit that way; without it the smallest system font is the
    // fallback. Every digit is measured as "8" so the size doesn't jump
    // around while the digits change.
    private function pick(dc as Graphics.Dc, main as String, frac as String, cy as Number,
            maxBottom as Number) as Number {
        var split = frac.length() > 0;
        var key = shapeOf(main) + "|" + shapeOf(frac) + "@" + cy.format("%d");
        if (key.equals(_cacheKey)) {
            return _cacheVal;
        }
        // Round screens, and the 735XT's 215x180 "semi-round" one: a circle
        // as wide as the screen, centred, with the top and bottom cut flat.
        var r = dc.getWidth() / 2;
        var mid = dc.getHeight() / 2;
        var last = split ? NBIG - 1 - FRAC_STEP : _fonts.size() - 1;
        var chosen = split ? -1 : last;
        for (var i = 0; i <= last; i++) {
            var f = _fonts[i];
            var fh = dc.getFontHeight(f);
            if (cy + fh / 2 > maxBottom || cy - fh / 2 < 0) {
                continue;
            }
            // Widest the screen is at the text's top or bottom edge.
            var d = (cy - mid).abs() + fh / 2;
            if (d >= r) {
                continue;
            }
            var chord = 2 * Math.sqrt(r * r - d * d) + 8;   // digit corners are rounded
            var tw = dc.getTextWidthInPixels(shapeOf(main), f);
            if (split) {
                tw += dc.getTextWidthInPixels(shapeOf(frac), _fonts[i + FRAC_STEP]);
            }
            if (tw <= chord) {
                chosen = i;
                break;
            }
        }
        _cacheKey = key;
        _cacheVal = chosen;
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
