# SplitWatch

A full-screen stopwatch with an interval beep, a Connect IQ watch app for the Garmin Forerunner 945, 965 and 735XT.

- The time fills the screen: tenths while running (`12.7`), hundredths when stopped (`12.75`, yellow).
  Stopped past a minute, the hundredths are drawn smaller (`1:02` big, `.75` small) so the rest stays big.
- The latest lap time shows small under the big time.
- **Beep interval:** for example `12.75` signals at 12.75, 25.50, 38.25 … for as long as the stopwatch runs, with a double buzz and beep. `00:00.00` = off.
- Starting gives a single buzz and beep. Both follow the Vibrate and Sound settings.
- It never starts a Garmin activity and records nothing.

## Buttons

| Button | What it does |
|---|---|
| START | Start / stop |
| BACK (lap) | While running: lap. While stopped: reset. At 0.00: close the app |
| DOWN | Lap list (2 or more laps), starting at lap 1. DOWN scrolls to later laps; UP at lap 1 or BACK returns |
| Hold UP | Settings |

## Settings (hold UP)

| Item | |
|---|---|
| Beep interval | mm:ss.hh. UP/DOWN change the orange digit, START moves on (saves on the last digit), BACK goes back (cancels on the first) |
| Vibrate | On / off (default on) |
| Sound | On / off (default off) |

## Building

You need the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (free Garmin developer
login), Java, and a developer key.

1. **SDK Manager.** Download it, then download the latest SDK and the target device (e.g. Forerunner 945).
   On Ubuntu 24.04 or newer the SDK Manager fails with `libwebkit2gtk-4.0.so.37: cannot open shared object file`.
   Run it through Docker instead:
   ```bash
   tools/sdkmanager-docker/run-sdkmanager.sh
   ```
   This expects the SDK Manager in `~/Downloads/connectiq-sdk-manager-linux`; set `SDKMANAGER_DIR` otherwise.
2. **Developer key** (one time; keep it and back it up, since every future build must use the same key):
   ```bash
   openssl genrsa -out developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
   ```
   The key is in `.gitignore` and must never be committed.
3. **Build:**
   ```bash
   SDK=$(ls -d ~/.Garmin/ConnectIQ/Sdks/*/ | tail -1)
   "$SDK/bin/monkeyc" -d fr945 -f monkey.jungle -o bin/SplitWatch.prg -y developer_key.der
   ```
   Use `-d fr965` or `-d fr735xt` (and a matching `-o` name) for the other watches.
   `monkey.jungle` names all three watches, so all three must be downloaded in the SDK Manager
   before any build works.
4. **Install:** plug in the watch, copy `bin/SplitWatch.prg` into `GARMIN/Apps` on the watch (replace any
   older one), eject and unplug.

For another watch model, see **[HOW-TO.md](HOW-TO.md)**. When you're done installing, see **[CLEANUP.md](CLEANUP.md)**.
