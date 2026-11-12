# Cleanup once SplitWatch is on every watch

Do this only when you're done installing on new watches. Everything below
except the two **keep** items can be reinstalled later.

## Keep (back these up somewhere safe)

- `~/Downloads/splitwatch/`: the app's source code, fonts, `HOW-TO.md` and this file (also on GitHub once pushed).
- `~/Downloads/splitwatch/developer_key.der` (and `developer_key.pem`): the signing key.
  Future updates to the app on any watch must be signed with this key.
  Don't share it or put it anywhere public.

## Remove

### 1. Docker image used for the SDK Manager and simulator (about 1.2 GB)

```bash
docker rmi ciq-sdkmanager ubuntu:22.04
```

`tools/sdkmanager-docker/run-sdkmanager.sh` rebuilds it automatically if you ever need it again.
Skip removing `ubuntu:22.04` if something else of yours uses it (`docker ps -a` shows what's running).

### 2. The Connect IQ SDK and device files (about 350 MB)

```bash
rm -rf ~/.Garmin
```

You need these to build again, but you can download them again with the SDK Manager.

### 3. The SDK Manager (about 10 MB)

```bash
rm -rf ~/Downloads/connectiq-sdk-manager-linux
```

The Docker workaround that makes it run on Ubuntu 26.04 is kept in this repo
(`tools/sdkmanager-docker/`), so nothing needs saving first. To use it again, re-download the
SDK Manager into the same folder.

### 4. Build output (under 1 MB)

```bash
rm -rf ~/Downloads/splitwatch/bin
```

A new build recreates it.

### 5. Garmin developer account (optional)

The free developer login at developer.garmin.com can stay. It costs nothing and you need it to download the SDK again.

## Nothing to clean on the watches

The app is a single `.prg` file in `GARMIN/Apps`. To remove it from a watch later,
delete that file over USB. Its settings go with it.
