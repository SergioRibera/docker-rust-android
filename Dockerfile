FROM rust:1.80-slim

# Variable arguments
# ARG RUST_VERSION=1.70.0
ARG GRADLE_VERSION=8.0.1
ARG GRADLE_PLUGIN_VERSION=7.4
ARG JAVA_VERSION=17
ARG NDK_VERSION=25.1.8937393
ARG BUNDLETOOL_VERSION=1.15.1
ARG BUILDTOOLS_VERSION=30.0.0
ARG PLATFORM_VERSION=android-33

# Prepare Android requirements
# Install JDK required for build android
RUN apt-get update -yqq && \
    apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev libssl-dev pkg-config build-essential python wget zip unzip openjdk-${JAVA_VERSION}-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install toolchain required
# RUN rustup toolchain install -c rust-src -- ${RUST_VERSION} && \
#     rustup default ${RUST_VERSION}
# Install android target required
RUN rustup target add armv7-linux-androideabi aarch64-linux-android i686-linux-android x86_64-linux-android x86_64-unknown-linux-gnu

# Generate Environment Variables
# for automate the next steps
ENV GRADLE_PLUGIN_VERSION=${GRADLE_PLUGIN_VERSION}
ENV JAVA_VERSION=${JAVA_VERSION}
ENV ANDROID_HOME=/opt/Android
ENV NDK_HOME=/opt/Android/ndk/${NDK_VERSION}
ENV GRADLE_HOME=/opt/gradle/gradle-${GRADLE_VERSION}/bin
ENV BUNDLETOOL_PATH=${ANDROID_HOME}/bundletool-all-${BUNDLETOOL_VERSION}.jar
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_NDK_ROOT=${NDK_HOME}
ENV PATH=$PATH:${ANDROID_HOME}:${ANDROID_NDK_ROOT}:${GRADLE_HOME}:${ANDROID_HOME}/build-tools/${BUILDTOOLS_VERSION}:${ANDROID_HOME}/cmdline-tools/bin

# Copy tool
COPY --chmod=0755 ./tools/apk2aab /bin

# Download gradle with correct version
RUN wget -c https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp && unzip -d /opt/gradle /tmp/gradle-${GRADLE_VERSION}-bin.zip && rm -fr /tmp/gradle-${GRADLE_VERSION}-bin.zip
# Install bundletools
RUN wget -c "https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar" -P ${ANDROID_HOME}

# Install command line tools
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -c "https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip" -P /tmp && \
    unzip -d ${ANDROID_HOME} /tmp/commandlinetools-linux-8512546_latest.zip && \
    rm -fr /tmp/commandlinetools-linux-8512546_latest.zip
# Install sdk required
RUN echo y | sdkmanager --sdk_root=${ANDROID_HOME} --install "build-tools;${BUILDTOOLS_VERSION}" "ndk;${NDK_VERSION}" "platforms;${PLATFORM_VERSION}" "platform-tools"

ENTRYPOINT [ "gradle" ]
