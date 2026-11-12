import Toybox.Application.Storage;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Stopwatch state plus a repeating interval beep.
//
// With a beep interval of 12.75 the watch signals at 12.75, 25.50, 38.25 ...
// for as long as the stopwatch runs. Each beep time is k * interval worked
// out from the real clock, so timer delays never add up. 0 = no beeps.
//
// Time is kept in milliseconds from System.getTimer(). Laps don't affect the
// beeps; stopping the stopwatch pauses them.
class StopwatchModel {

    var intervalCs as Number = 0;        // beep interval in hundredths, 0 = off
    var vibrateOn as Boolean = true;
    var soundOn as Boolean = false;

    var running as Boolean = false;
    var laps as Array<Number> = [] as Array<Number>;   // each lap's own duration, ms

    private var _accumulatedMs as Number = 0;
    private var _startTick as Number = 0;
    private var _lastLapMark as Number = 0;
    private var _nextBeep as Number = 1;     // index k of the next beep

    private var _refreshTimer as Timer.Timer;
    private var _alertTimer as Timer.Timer;

    function initialize() {
        _refreshTimer = new Timer.Timer();
        _alertTimer = new Timer.Timer();

        var iv = Storage.getValue("intervalCs");
        if (iv instanceof Number && iv >= 0) {
            intervalCs = iv;
        }
        var vib = Storage.getValue("vibrate");
        if (vib instanceof Boolean) {
            vibrateOn = vib;
        }
        var snd = Storage.getValue("sound");
        if (snd instanceof Boolean) {
            soundOn = snd;
        }
    }

    // ---- time -------------------------------------------------------------

    function elapsed() as Number {
        if (running) {
            return _accumulatedMs + (System.getTimer() - _startTick);
        }
        return _accumulatedMs;
    }

    // ---- stopwatch controls ----------------------------------------------

    function start() as Void {
        if (running) {
            return;
        }
        _startTick = System.getTimer();
        running = true;
        _refreshTimer.start(method(:onRefresh), 100, true);
        armFromNow();
        WatchUi.requestUpdate();
    }

    function stop() as Void {
        if (!running) {
            return;
        }
        _accumulatedMs = elapsed();
        running = false;
        _refreshTimer.stop();
        _alertTimer.stop();
        WatchUi.requestUpdate();
    }

    function reset() as Void {
        stop();
        _accumulatedMs = 0;
        _lastLapMark = 0;
        laps = [] as Array<Number>;
        WatchUi.requestUpdate();
    }

    function lap() as Void {
        var now = elapsed();
        laps.add(now - _lastLapMark);
        _lastLapMark = now;
        buzz(40, 60);
        WatchUi.requestUpdate();
    }

    // ---- settings ---------------------------------------------------------

    function intervalMs() as Number {
        return intervalCs * 10;
    }

    function beepsActive() as Boolean {
        return intervalCs > 0 && (vibrateOn || soundOn);
    }

    function setIntervalCs(cs as Number) as Void {
        intervalCs = cs;
        Storage.setValue("intervalCs", cs);
        armFromNow();
        WatchUi.requestUpdate();
    }

    function setVibrate(on as Boolean) as Void {
        vibrateOn = on;
        Storage.setValue("vibrate", on);
        armFromNow();
    }

    function setSound(on as Boolean) as Void {
        soundOn = on;
        Storage.setValue("sound", on);
        armFromNow();
    }

    // ---- timers -----------------------------------------------------------

    function onRefresh() as Void {
        WatchUi.requestUpdate();
    }

    // Work out the next beep from the current time. Used on start, resume
    // and whenever a setting changes.
    private function armFromNow() as Void {
        _alertTimer.stop();
        if (!running || !beepsActive()) {
            return;
        }
        _nextBeep = elapsed() / intervalMs() + 1;
        armNext();
    }

    // One-shot timer aimed at the next beep, re-aimed from the real clock
    // every time.
    private function armNext() as Void {
        var delay = _nextBeep * intervalMs() - elapsed();
        if (delay < 50) {
            delay = 50;   // shortest timer Connect IQ allows
        }
        _alertTimer.start(method(:onAlert), delay, false);
    }

    function onAlert() as Void {
        if (!running || !beepsActive()) {
            return;
        }
        signal();
        // Skip any beeps that were missed, e.g. if the watch was busy.
        _nextBeep = elapsed() / intervalMs() + 1;
        armNext();
    }

    // ---- alerts -----------------------------------------------------------

    private function signal() as Void {
        if (vibrateOn && (Attention has :vibrate)) {
            Attention.vibrate([new Attention.VibeProfile(80, 150)]);
        }
        if (soundOn && (Attention has :playTone)) {
            Attention.playTone(Attention.TONE_LOUD_BEEP);
        }
    }

    private function buzz(strength as Number, durationMs as Number) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(strength, durationMs)]);
        }
    }

    function shutdown() as Void {
        _refreshTimer.stop();
        _alertTimer.stop();
    }
}

// ---- formatting helper (shared) --------------------------------------------

// Stopwatch style, truncated (never rounded up):
//   under a minute  "12.7"     / "12.75"
//   under an hour   "3:04.5"   / "3:04.50"
//   longer          "1:02:03.4"
// hundredths = true gives two decimals.
function formatTime(ms as Number, hundredths as Boolean) as String {
    var frac;
    if (hundredths) {
        frac = ((ms / 10) % 100).format("%02d");
    } else {
        frac = ((ms / 100) % 10).format("%d");
    }
    var totalSec = ms / 1000;
    var s = totalSec % 60;
    var m = (totalSec / 60) % 60;
    var h = totalSec / 3600;
    if (h > 0) {
        return h.format("%d") + ":" + m.format("%02d") + ":" + s.format("%02d") + "." + frac;
    }
    if (m > 0) {
        return m.format("%d") + ":" + s.format("%02d") + "." + frac;
    }
    return s.format("%d") + "." + frac;
}
