# android-bitgesell-docker

## Notes
- Uses `NDK version 23.1.7779620`
- Works with old `libc++` version and `Qt 5.13x`


## 1. Build environment setup for Android
1. Setup environment(needs Docker)

Build the docker image from `Dockerfile`:

```sh
docker build -t android-bitgesell .
```

or Pull the image from the dockerhub registry

```sh
docker pull naftalimurgor/android-bitgesell
```


## 2. Build Bitgesell APK 

Clone the repo:

```sh
git clone https://github.com/naftalimurgor/bitgesell.git
cd bitgesell
# patched for Android based on this release:
git checkout 0.1.2 

# run the container
docker run --rm -v $(pwd):/work --user root -it android-bitgesell /bin/bash
cd /work

```

while inside the container in interractive mode,

Set up a few variables:


```sh
# 64-bit ARM arch:
export HOST="aarch64-linux-android"
export ANDROID_API_LEVEL=28
export HOST="aarch64-linux-android"
export ANDROID_TOOLCHAIN_BIN="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
yes | sdkmanager --install "ndk;21.4.7075529"
export ANDROID_NDK=/opt/android-sdk-linux/ndk/21.4.7075529
cd /opt/android-sdk-linux/ndk/25.2.9519653/toolchains/llvm/prebuilt/linux-x86_64/bin

ln -s llvm-ar aarch64-linux-android-ar
ln -s llvm-ranlib aarch64-linux-android-ranlib
Add deps for `libqrencode` lib:

apt update
apt install libtool automake autoconf gettext libtool-bin \
                 libsdl1.2-dev libiconv-hook-dev bsdmain-utils
```

1. Cross compile libs:
```sh
/work
make -C depends/ HOST=aarch64-linux-android
```

The cross-compiled libs for Android are :
```sh
-  boost libevent zlib qt qrencode bdb miniupnpc zeromq
```

Note: `make -C depends/ HOST=aarch64-linux-android` needs faster internet connection as `curl` times out forcing redownload from `https://BGLcore.org/depends` which doesn't have any of the packages.

Note: To clean up:

```sh
make -C depends/ clean #cleans up the dependencies
```

> Patching build-aux/m4/ax_boost_base.m4 for `aarch64-linux-android`:

```sh
sed -i '/AS_CASE(\[\${host_cpu}\],/a\      [aarch64],[multiarch_libsubdir="lib/aarch64-linux-android"],' build-aux/m4/ax_boost_base.m4
```

2. Run `./autogen.sh` to generate all the necessary config files:

```sh
./autogen.sh
```

3. `./configure` to generate Make file:

```sh
./configure \
  --host=aarch64-linux-android \
  --prefix=/work/depends/aarch64-linux-android \
  --with-boost=/work/depends/aarch64-linux-android \
  --with-boost-libdir=/work/depends/aarch64-linux-android/lib

```

