# Base image
FROM ubuntu:20.04

# Metadata
LABEL maintainer="yourname@example.com"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

# Install dependencies including stable OpenJDK 17
RUN apt-get update && \
    apt-get install -y \
    wget curl unzip git build-essential \
    autoconf automake libtool pkg-config \
    openjdk-17-jdk \
    python3 python3-pip && \
    apt-get clean

# (Optional) confirm Java version for sdkmanager compatibility
RUN java -version

# Download and extract Android command line tools
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    cd ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip -q commandlinetools-linux-11076708_latest.zip && \
    rm commandlinetools-linux-11076708_latest.zip && \
    mv cmdline-tools latest

# Set environment variable for sdkmanager to work properly
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Accept all SDK licenses and update tools
RUN yes | sdkmanager --sdk_root=${ANDROID_HOME} --licenses && \
    sdkmanager --sdk_root=${ANDROID_HOME} --update

# Install SDK components (updated versions + non-interactive)
ENV SDK_VERSION=34
ENV BUILDTOOLS_VERSION=34.0.0
ENV NDK_VERSION=25.2.9519653

RUN yes | sdkmanager --sdk_root=${ANDROID_HOME} \
    "platform-tools" \
    "platforms;android-${SDK_VERSION}" \
    "build-tools;${BUILDTOOLS_VERSION}" \
    "ndk;${NDK_VERSION}"

# Optional: Qt for Android (commented out)
# ENV QT_VERSION=5.13.2
# ENV QT_DIR=/opt/qt
# RUN mkdir -p ${QT_DIR} && \
#     cd ${QT_DIR} && \
#     wget -q https://download.qt.io/archive/qt/5.13/${QT_VERSION}/android/qt-opensource-linux-${QT_VERSION}.tar.xz && \
#     tar -xf qt-opensource-linux-${QT_VERSION}.tar.xz && \
#     rm qt-opensource-linux-${QT_VERSION}.tar.xz

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
