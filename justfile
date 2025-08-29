genkey key_alias key_store:
    # Run keytool to generate key
    docker run --rm -it -v "$(pwd)/:/src" -w /src --entrypoint keytool rust-android:1.86-sdk-36 \
        -genkey -v -keystore {{key_store}} -alias {{key_alias}} -keyalg RSA -keysize 2048 -validity 10000

build example:
    docker run --rm -it -v "$(pwd)/:/src" -w /src rust-android:1.86-sdk-36 assembleRelease -p examples/{{example}}

sign example key_alias key_store:
    # Run apksigner to sign generated apk
    docker run --rm -it -v "$(pwd)/:/src" -w /src --entrypoint apksigner rust-android:1.86-sdk-36 \
        sign --ks-key-alias {{key_alias}} --ks {{key_store}} examples/{{example}}/android/build/outputs/apk/release/android-release-unsigned.apk
    sudo cp examples/{{example}}/android/build/outputs/apk/release/android-release-unsigned.apk \
        examples/{{example}}/android/build/outputs/apk/release/android-release-signed.apk

install example:
    adb install examples/{{example}}/android/build/outputs/apk/release/android-release-signed.apk

run example key_alias key_store: (build example) (sign example key_alias key_store) (install example)
