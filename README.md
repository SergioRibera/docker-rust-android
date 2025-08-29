# Rust Android

<p align="center">
    <img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/sergioribera/rust-android">
    <img alt="Docker Image Size with architecture (latest by date/latest semver)" src="https://img.shields.io/docker/image-size/sergioribera/rust-android">
</p>
This is a project that tries to package in a small container everything needed and required to build an android gradle project.

Among the components it has are:

- rust
- gradle
- java jdk
- ndk
- bundletool
- buildtools
- command line tools
- platform tools

## Usage

Command Line:

> **Note:** for more information, consider looking at [examples](./examples)

```bash
# Debug
docker run --rm -it -v "$(pwd)/:/src" -w /src sergioribera/rust-android:1.80-sdk-36 assembleDebug -p <android project path>
# Release
docker run --rm -it -v "$(pwd)/:/src" -w /src sergioribera/rust-android:1.80-sdk-36 assembleRelease -p <android project path>
```

Github Action:

> **Note:** for more information, consider looking at my project [kill errors](https://github.com/SergioRibera/game_kill_errors)

```yaml
env:
  APP_NAME: my_application

jobs:
  native_build:
    container: sergioribera/rust-android:180-sdk-33
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: Swatinem/rust-cache@v2
      - name: Load .env file
        uses: xom9ikk/dotenv@v2
      # Start to build
      - name: build apk
        run: gradle assembleRelease -p launchers/mobile/android
      - name: Rename APK
        run: |
          cp launchers/mobile/android/build/outputs/apk/release/android-release.apk ${{ env.APP_NAME }}.apk
      - name: build aab
        run: |
          apk2aab ${{ env.APP_NAME }}.apk ${{ env.APP_NAME }}.aab
```

## Build Examples

> [!IMPORTANT]
> You can check the justfile to see how build, generate key and sign apk
> You can use `just run <example name>` and `build -> sign -> install` automatic

Bevy Game

```bash
docker run --rm -it -v "$(pwd)/:/src" -w /src sergioribera/rust-android:1.80-sdk-36 assembleDebug -p examples/bevy_game/android
```

Rust Library

```bash
docker run --rm -it -v "$(pwd)/:/src" -w /src sergioribera/rust-android:1.80-sdk-36 assembleDebug -p examples/rust_lib/android
```
