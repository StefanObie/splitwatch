# How to put SplitWatch on another watch

You need the watch itself and its USB charging cable. SplitWatch isn't in the
Connect IQ Store, so the watch has to be plugged into this computer.

## 1. Find out the watch model

Ask the owner to check either of these:

- On the watch: **Settings → System → About**. The model is at the top, e.g. "Forerunner 265".
- The box, or the back of the watch.

Write down the exact name, including any letters or sizes ("Forerunner 965", "fenix 7S", "Venu 2 Plus").
The exact model matters: an app built for one model won't run on another.

If they don't know it, plug the watch in. The model is in `GARMIN/GarminDevice.xml` on the watch, in the `<Description>` line.

## 2. Check that the watch supports apps

Look the model up at **developer.garmin.com/connect-iq/compatible-devices**.

- If the model isn't listed, it can't run Connect IQ apps (basic models like the Forerunner 55 can't), so stop here.
- If it's listed, check its Connect IQ version: SplitWatch needs **3.0 or higher**.

## 3. Download the watch in the SDK Manager

```bash
~/Downloads/splitwatch/tools/sdkmanager-docker/run-sdkmanager.sh
```

The first run after cleanup rebuilds a Docker image, which takes a few minutes.
Log in with the Garmin developer account, open **Devices**, and download the new model.
While you're there, update the SDK if it offers an update.

Then find the watch's device ID (the folder name the SDK Manager created):

```bash
ls ~/.Garmin/ConnectIQ/Devices/
```

For example `fr265`, `fenix7s`, `venu2plus`.

## 4. Add the watch to the app

In `~/Downloads/splitwatch/manifest.xml`, add one line inside `<iq:products>` for the new ID:

```xml
        <iq:products>
            <iq:product id="fr945"/>
            <iq:product id="fr265"/>
        </iq:products>
```

## 5. Build for that watch

```bash
cd ~/Downloads/splitwatch
SDK=$(ls -d ~/.Garmin/ConnectIQ/Sdks/*/ | tail -1)
"$SDK/bin/monkeyc" -d fr265 -f monkey.jungle -o bin/SplitWatch-fr265.prg -y developer_key.der
```

Replace `fr265` (both places) with the real device ID. It should end with `BUILD SUCCESSFUL`.
Always sign with this same `developer_key.der`.

## 6. Copy it onto the watch

1. Plug in the watch. It shows up in the file manager (Files) as the watch's name.
2. Open **Internal Storage → GARMIN → Apps** (on some watches it's **Primary → GARMIN → Apps**).
3. Copy `bin/SplitWatch-fr265.prg` into that folder. Renaming it to `SplitWatch.prg` is optional.
4. Eject the watch in the file manager, then unplug it.
5. On the watch, press START and scroll the list of activities and apps to **SplitWatch**. It can take a few
   seconds after unplugging to appear.

If the file vanishes from `Apps` after unplugging, the build was for the wrong model. Check the device ID in step 3.

## 7. Check it on the watch

- START starts the stopwatch, BACK laps, and START stops it. The time should fill the screen.
- Hold UP for settings: Beep interval, Vibrate, Sound. Set an interval and check that it buzzes.
- With 2 or more laps, press DOWN for the lap list.

## Different screens and buttons

- **Bigger screen** (e.g. 260 or 280 px wide on the Forerunner 255/265/965): the app works, but the digits
  won't fill the screen. To fill it, add larger sizes to `HEIGHTS` in `tools/make_fonts.py`, run
  `python3 tools/make_fonts.py`, add the new fonts to `resources/fonts/fonts.xml` and to the font list in
  `source/SplitWatchView.mc`, then rebuild. The app picks the biggest size that fits, so the 945 isn't affected.
- **Touchscreen-only watches or a different button layout** (e.g. Venu, Vivoactive): the buttons may not
  map the same way and the app may need changes. Try it first.

Claude can do steps 4–7 for you: say "build SplitWatch for a &lt;model&gt; and copy it to the watch" with
the watch plugged in.
