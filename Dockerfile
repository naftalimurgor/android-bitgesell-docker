# Set Android SDK and NDK versions
ARG SDK_VERSION=28
ARG NDK_VERSION=23.1.7779620
ARG BUILDTOOLS_VERSION=28.0.3

FROM androidsdk/android-${SDK_VERSION}

# Pass build args again inside the image
ARG SDK_VERSION
ARG NDK_VERSION
ARG BUILDTOOLS_VERSION

# Install Android NDK and build tools
RUN sdkmanager --install "ndk;${NDK_VERSION}" \
    && sdkmanager --install "build-tools;${BUILDTOOLS_VERSION}"

# Set environment variables for Android build
ENV ANDROID_SDK=/opt/android-sdk-linux
ENV ANDROID_API_LEVEL=${SDK_VERSION}
ENV HOST="aarch64-linux-android"
ENV ANDROID_NDK="${ANDROID_SDK}/ndk/${NDK_VERSION}"
ENV ANDROID_TOOLCHAIN_BIN="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin"
ENV CC="${ANDROID_TOOLCHAIN_BIN}/${HOST}${ANDROID_API_LEVEL}-clang"
ENV CXX="${ANDROID_TOOLCHAIN_BIN}/${HOST}${ANDROID_API_LEVEL}-clang++"
ENV CXXFLAGS="--std=c++17"
ENV LDFLAGS="-lc++"

# Update apt and install required build dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    autoconf automake libtool make pkg-config \
    clang g++ git cmake python3 bison flex \
    zlib1g-dev libtool-bin gettext libsdl1.2-dev \
    libiconv-hook-dev bsdmainutils libqrencode-dev gradle

# Create symlinks for ar and ranlib in toolchain bin
RUN cd ${ANDROID_TOOLCHAIN_BIN} && \
    ln -sf llvm-ar ${HOST}-ar && \
    ln -sf llvm-ranlib ${HOST}-ranlib

# Set workdir
WORKDIR /work
