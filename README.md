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
sdkmanager --install "ndk;25.2.9519653"
cd $ANDROID_TOOLCHAIN_BIN
ln -s llvm-ar aarch64-linux-android-ar
ln -s llvm-ranlib aarch64-linux-android-ranlib
#Add deps for `libqrencode` lib:

apt update
apt install libtool automake autoconf gettext libtool-bin \
                 libsdl1.2-dev libiconv-hook-dev bsdmainutils
```

1. Cross compile libs:
```sh
/work
make -C depends/ HOST=aarch64-linux-android
```

which outputs:

```sh
....
/bin/mkdir -p '/work/depends/work/staging/aarch64-linux-android/zeromq/4.3.1-559e011f607/work/depends/aarch64-linux-android/include'
/usr/bin/install -c -m 644 include/zmq.h include/zmq_utils.h '/work/depends/work/staging/aarch64-linux-android/zeromq/4.3.1-559e011f607/work/depends/aarch64-linux-android/include'
/bin/mkdir -p '/work/depends/work/staging/aarch64-linux-android/zeromq/4.3.1-559e011f607/work/depends/aarch64-linux-android/lib/pkgconfig'
/usr/bin/install -c -m 644 src/libzmq.pc '/work/depends/work/staging/aarch64-linux-android/zeromq/4.3.1-559e011f607/work/depends/aarch64-linux-android/lib/pkgconfig'
make[1]: Leaving directory '/work/depends/work/build/aarch64-linux-android/zeromq/4.3.1-559e011f607'
Postprocessing zeromq...
Caching zeromq...
copying packages: boost libevent zlib qt qrencode bdb miniupnpc zeromq
to: /work/depends/aarch64-linux-android
make: Leaving directory '/work/depends'

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

3. Set the correct C++ compiler for current session:

```sh
export API=28
export TOOLCHAIN=/opt/android-sdk-linux/ndk/25.2.9519653/toolchains/llvm/prebuilt/linux-x86_64/bin

export CC=$TOOLCHAIN/aarch64-linux-android${API}-clang
export CXX=$TOOLCHAIN/aarch64-linux-android${API}-clang++
export AR=$TOOLCHAIN/llvm-ar
export RANLIB=$TOOLCHAIN/llvm-ranlib
export STRIP=$TOOLCHAIN/llvm-strip

```

Symlink boost libs to `aarch-64-android` directory:

```sh
mkdir -p /work/depends/aarch64-linux-android/lib/aarch64-linux-android
cd /work/depends/aarch64-linux-android/lib/aarch64-linux-android
ln -s ../libboost_* .

```

Set boost paths for ./configure to detect:
```sh
export BOOST_ROOT=/work/depends/aarch64-linux-android
export BOOST_INCLUDEDIR=$BOOST_ROOT/include
export BOOST_LIBRARYDIR=$BOOST_ROOT/lib
export BOOST_THREAD_USE_LIB=1
export CXXFLAGS="-DBOOST_THREAD_USE_LIB=1"
export LDFLAGS="-latomic"

```

Patch `Config.ac` to Disable `Boost Sleep not found` to prevent alt of ./configure flow

```sh
 sed -i '31049s/as_fn_error .*$/echo "WARNING: Boost sleep not found, continuing anyway..."/' configure

```
4. `./configure` to generate Make file:

```sh
./configure --host=${HOST} --prefix=/work/depends/${HOST}   --disable-bench   --disable-gui-tests   --disable-tests   --with-wallet
```

5. `make -j $(nproc)`
Run make

```sh
make -j 8
```

6. Build apk 

```sh
make -C src/qt apk
```

apks will be output to:

```sh
src/qt/android/build/outputs/apk/release/android-release-unsigned.apk
src/qt/android/build/outputs/apk/debug/android-debug.apk
```

Check build for a signed apk under `build/`