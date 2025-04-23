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

make -C depends/
```

The cross-compiled libs for Android are :
```sh
- libevent
- libboost
- qt- base, tools, translations
- libqrencode
```

Note: `make -C depends` needs faster internet connection as `curl` times out forcing redownload from `https://bglcore/depends` which doesn't have any of the packages.

To clean up:

```sh
make -C depends/ clean #cleans up the dependencies
```
