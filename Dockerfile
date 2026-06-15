FROM debian:bullseye-slim

# Variable arguments
ARG RUST_VERSION=1.90
ARG GRADLE_VERSION=8.13
ARG GRADLE_PLUGIN_VERSION=8.13.0
ARG JAVA_VERSION=17
ARG NDK_VERSION=29.0.14033849
ARG BUNDLETOOL_VERSION=1.18.0
ARG BUILDTOOLS_VERSION=35.0.0
ARG PLATFORM_VERSION=android-36

# Prepare Android requirements
RUN apt-get update -yqq && \
    apt-get install -y --no-install-recommends \
    curl libcurl4-openssl-dev libssl-dev pkg-config \
    build-essential python3 wget zip unzip \
    openjdk-${JAVA_VERSION}-jdk ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    -y --default-toolchain "$RUST_VERSION" --profile minimal \
    --component rust-src,rustc,cargo,llvm-tools-preview,rust-std \
    --target arm-linux-androideabi,armv7-linux-androideabi,aarch64-linux-android,i686-linux-android,thumbv7neon-linux-androideabi,x86_64-linux-android,x86_64-unknown-linux-gnu

# Base Environment Variables
ENV GRADLE_PLUGIN_VERSION=${GRADLE_PLUGIN_VERSION}
ENV JAVA_VERSION=${JAVA_VERSION}
ENV ANDROID_HOME=/opt/Android
ENV NDK_HOME=${ANDROID_HOME}/ndk/${NDK_VERSION}
ENV GRADLE_HOME=/opt/gradle/gradle-${GRADLE_VERSION}/bin
ENV BUNDLETOOL_PATH=${ANDROID_HOME}/bundletool-all-${BUNDLETOOL_VERSION}.jar
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_NDK_ROOT=${NDK_HOME}
ENV ANDROID_NDK=${NDK_HOME}
ENV RUST_ANDROID_GRADLE_PYTHON_COMMAND=/usr/bin/python3

# Set up paths
ENV PATH="$PATH:${ANDROID_HOME}:${NDK_HOME}:${GRADLE_HOME}:${ANDROID_HOME}/build-tools/${BUILDTOOLS_VERSION}:${ANDROID_HOME}/cmdline-tools/bin:${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin:/root/.cargo/bin"

# OpenSSL specific configuration for older Android versions
ENV OPENSSL_NO_GETENTROPY=1

# Copy tool
COPY --chmod=0755 ./tools/apk2aab /bin

# Install Gradle
RUN wget -c https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp && \
    unzip -d /opt/gradle /tmp/gradle-${GRADLE_VERSION}-bin.zip && \
    rm -fr /tmp/gradle-${GRADLE_VERSION}-bin.zip

# Install bundletool
RUN wget -c "https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar" -P ${ANDROID_HOME}

# Install Android Command Line Tools. Pin matches the version used by
# .github/workflows/docker-publish.yml so the matrix-discovery step
# (which runs the same `sdkmanager --list` outside the container)
# resolves the same package set the Dockerfile then installs.
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -c "https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip" -P /tmp && \
    unzip -d ${ANDROID_HOME} /tmp/commandlinetools-linux-13114758_latest.zip && \
    rm -fr /tmp/commandlinetools-linux-13114758_latest.zip

# Install sdk required
RUN echo y | sdkmanager --sdk_root=${ANDROID_HOME} --install "build-tools;${BUILDTOOLS_VERSION}"
RUN echo y | sdkmanager --sdk_root=${ANDROID_HOME} --install "ndk;${NDK_VERSION}"
RUN echo y | sdkmanager --sdk_root=${ANDROID_HOME} --install "platforms;${PLATFORM_VERSION}"
RUN echo y | sdkmanager --sdk_root=${ANDROID_HOME} --install "platform-tools"

# Build OpenSSL for Android architectures
ARG OPENSSL_VERSION=3.0.15
ENV OPENSSL_DIR=/opt/openssl

RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar xzf openssl-${OPENSSL_VERSION}.tar.gz && \
    rm openssl-${OPENSSL_VERSION}.tar.gz

# Build for aarch64 (arm64-v8a)
RUN cd openssl-${OPENSSL_VERSION} && \
    export ANDROID_NDK_ROOT=${NDK_HOME} && \
    export PATH=${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH && \
    ./Configure android-arm64 \
        -D__ANDROID_API__=28 \
        --prefix=${OPENSSL_DIR}/aarch64-linux-android \
        --openssldir=${OPENSSL_DIR}/aarch64-linux-android \
        no-shared \
        no-tests && \
    make -j$(nproc) && \
    make install_sw && \
    make clean

# Build for armv7 (armeabi-v7a)
RUN cd openssl-${OPENSSL_VERSION} && \
    export ANDROID_NDK_ROOT=${NDK_HOME} && \
    export PATH=${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH && \
    ./Configure android-arm \
        -D__ANDROID_API__=28 \
        --prefix=${OPENSSL_DIR}/armv7-linux-androideabi \
        --openssldir=${OPENSSL_DIR}/armv7-linux-androideabi \
        no-shared \
        no-tests && \
    make -j$(nproc) && \
    make install_sw && \
    make clean

# Build for x86_64
RUN cd openssl-${OPENSSL_VERSION} && \
    export ANDROID_NDK_ROOT=${NDK_HOME} && \
    export PATH=${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH && \
    ./Configure android-x86_64 \
        -D__ANDROID_API__=28 \
        --prefix=${OPENSSL_DIR}/x86_64-linux-android \
        --openssldir=${OPENSSL_DIR}/x86_64-linux-android \
        no-shared \
        no-tests && \
    make -j$(nproc) && \
    make install_sw && \
    make clean

# Build for i686 (x86)
RUN cd openssl-${OPENSSL_VERSION} && \
    export ANDROID_NDK_ROOT=${NDK_HOME} && \
    export PATH=${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH && \
    ./Configure android-x86 \
        -D__ANDROID_API__=28 \
        --prefix=${OPENSSL_DIR}/i686-linux-android \
        --openssldir=${OPENSSL_DIR}/i686-linux-android \
        no-shared \
        no-tests && \
    make -j$(nproc) && \
    make install_sw && \
    make clean

# Cleanup
RUN rm -rf openssl-${OPENSSL_VERSION}

# Set OpenSSL environment variables for each architecture
ENV AARCH64_LINUX_ANDROID_OPENSSL_DIR=${OPENSSL_DIR}/aarch64-linux-android
ENV AARCH64_LINUX_ANDROID_OPENSSL_STATIC=1
ENV ARMV7_LINUX_ANDROIDEABI_OPENSSL_DIR=${OPENSSL_DIR}/armv7-linux-androideabi
ENV ARMV7_LINUX_ANDROIDEABI_OPENSSL_STATIC=1
ENV X86_64_LINUX_ANDROID_OPENSSL_DIR=${OPENSSL_DIR}/x86_64-linux-android
ENV X86_64_LINUX_ANDROID_OPENSSL_STATIC=1
ENV I686_LINUX_ANDROID_OPENSSL_DIR=${OPENSSL_DIR}/i686-linux-android
ENV I686_LINUX_ANDROID_OPENSSL_STATIC=1

ENV PKG_CONFIG_ALLOW_CROSS=1

# ARMv7 (armeabi-v7a)
ENV CC_armv7_linux_androideabi="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi28-clang"
ENV CXX_armv7_linux_androideabi="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi28-clang++"
ENV AR_armv7_linux_androideabi="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
ENV RANLIB_armv7_linux_androideabi="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib"
ENV CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="${CC_armv7_linux_androideabi}"

# ARM64 (aarch64)
ENV CC_aarch64_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android28-clang"
ENV CXX_aarch64_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android28-clang++"
ENV AR_aarch64_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
ENV RANLIB_aarch64_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib"
ENV CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="${CC_aarch64_linux_android}"

# x86 (i686)
ENV CC_i686_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android28-clang"
ENV CXX_i686_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android28-clang++"
ENV AR_i686_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
ENV RANLIB_i686_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib"
ENV CARGO_TARGET_I686_LINUX_ANDROID_LINKER="${CC_i686_linux_android}"

# x86_64
ENV CC_x86_64_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android28-clang"
ENV CXX_x86_64_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android28-clang++"
ENV AR_x86_64_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
ENV RANLIB_x86_64_linux_android="${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib"
ENV CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="${CC_x86_64_linux_android}"

# Common CFLAGS and CXXFLAGS
ENV CFLAGS="-D__ANDROID_MIN_SDK_VERSION__=28"
ENV CXXFLAGS="-D__ANDROID_MIN_SDK_VERSION__=28"

ENTRYPOINT [ "gradle" ]
