# android-bitgesell-docker
<img src="Icon.png" style="height: 60px;" />

Docker setup for cross-compiling Bitgesell core for Android (SDK 28+) from a Docker container

## Notes
- Uses `NDK version = `21.4.7075529` (NDK 23 also works)
- Works with `libc++` version and `Qt 5.13x`


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
git checkout android-qt-patch

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
export ANDROID_NDK="/opt/android-sdk-linux/ndk/21.4.7075529"
export ANDROID_TOOLCHAIN_BIN="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin"

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
Note: ensure you provide platform triplet i.e `aarch64-linux-android`  for 64-bit ARM architecture for Linux.

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

3. Set `clang` C++ compiler for current session:

```sh
export API=28
export TOOLCHAIN=/opt/android-sdk-linux/ndk/21.4.7075529/toolchains/llvm/prebuilt/linux-x86_64/bin

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

4. `./configure` to generate Make file:

```sh
CXXFLAGS="-DHAVE_WORKING_BOOST_SLEEP" \
./configure \
  --host=${HOST} \
  --prefix=/work/depends/${HOST} \
  --disable-bench \
  --disable-gui-tests \
  --disable-tests \
  --disable-wallet \
  --with-boost-libdir=/work/depends/${HOST}/lib \
  --without-libzmq \
  --without-libevent

```

`-DHAVE_WORKING_BOOST_SLEEP` flag propagates the `#define HAVE_WORKING_BOOST_SLEEP` macro to the compiler.


Upon sucess should output:
```sh
-long-long -Wno-overlength-strings -fvisibility=hidden -O3
  CPPFLAGS            = -I/work/depends/aarch64-linux-android/share/../include/ 
  LDFLAGS             = -L/work/depends/aarch64-linux-android/share/../lib -Wl,--exclude-libs=ALL -lc


Options used to compile and link:
  with wallet   = no
  with gui / qt = yes
    with qr     = no
  with zmq      = yes
  with test     = no
  with bench    = no
  with upnp     = no
  use asm       = yes
  sanitizers    = 
  debug enabled = no
  gprof enabled = no
  werror        = no

  target os     = android
  build os      = 

  CC            = /opt/android-sdk-linux/ndk/21.4.7075529/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang
  CFLAGS        = --sysroot=/opt/android-sdk-linux/ndk/21.4.7075529/toolchains/llvm/prebuilt/linux-x86_64/sysroot
  CPPFLAGS      =   -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -I/work/depends/aarch64-linux-android/share/../include/  -DHAVE_BUILD_INFO -D__STDC_FORMAT_MACROS
  CXX           = /opt/android-sdk-linux/ndk/21.4.7075529/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang++ -std=c++11
  CXXFLAGS      =   -Wstack-protector -fstack-protector-all     -DHAVE_WORKING_BOOST_SLEEP
  LDFLAGS       = -pthread  -Wl,-z,relro -Wl,-z,now -pie  -L/work/depends/aarch64-linux-android/share/../lib -Wl,--exclude-libs=ALL -lc
  ARFLAGS       = cr

```

5. `make -j $(nproc)`
Run make

Set flags for `lpthread` library for linker to link:

```sh
export LDFLAGS="-L$ANDROID_NDK/platforms/android-21/arch-arm64/usr/lib -lc++_static"
export LDFLAGS="-L$ANDROID_NDK/platforms/android-21/arch-arm64/usr/lib -pthread"
nm $ANDROID_NDK/platforms/android-21/arch-arm64/usr/lib/libc.a | grep pthread
```

```sh
make HOST=aarch64-linux-android -j $(nproc)
```

Should output:

```sh
root@fc88f2344529:/work# make -j8
Making all in src
make[1]: Entering directory '/work/src'
make[2]: Entering directory '/work/src'
make[3]: Entering directory '/work'
make[3]: Leaving directory '/work'
  CXX      qt/qt_BGL_qt-main.o
  CXX      qt/qt_libBGLqt_a-bantablemodel.o
  CXX      qt/qt_libBGLqt_a-BGL.o
  CXX      qt/qt_libBGLqt_a-BGLaddressvalidator.o
  CXX      qt/qt_libBGLqt_a-BGLamountfield.o
  CXX      qt/qt_libBGLqt_a-BGLunits.o
  CXX      qt/qt_libBGLqt_a-BGLgui.o
  CXX      qt/qt_libBGLqt_a-clientmodel.o
  CXX      qt/qt_libBGLqt_a-csvmodelwriter.o
  CXX      qt/qt_libBGLqt_a-guiutil.o
  CXX      qt/qt_libBGLqt_a-intro.o
  CXX      qt/qt_libBGLqt_a-modaloverlay.o
  CXX      qt/qt_libBGLqt_a-networkstyle.o
  CXX      qt/qt_libBGLqt_a-notificator.o
  CXX      qt/qt_libBGLqt_a-optionsdialog.o
  CXX      qt/qt_libBGLqt_a-optionsmodel.o
  CXX      qt/qt_libBGLqt_a-peertablemodel.o
  CXX      qt/qt_libBGLqt_a-platformstyle.o
  CXX      qt/qt_libBGLqt_a-qvalidatedlineedit.o
  CXX      qt/qt_libBGLqt_a-qvaluecombobox.o
  CXX      qt/qt_libBGLqt_a-rpcconsole.o
  CXX      qt/qt_libBGLqt_a-splashscreen.o
  CXX      qt/qt_libBGLqt_a-trafficgraphwidget.o
  CXX      qt/qt_libBGLqt_a-utilitydialog.o
  CXX      qt/qt_libBGLqt_a-moc_addressbookpage.o
...
```

6. Build the BGL-qt GUI apk 

```sh
make -C src/qt apk
```

apks will be output to:

```sh
src/qt/android/build/outputs/apk/release/android-release-unsigned.apk
src/qt/android/build/outputs/apk/debug/android-debug.apk
```

Check build for a signed apk under `build/`

## Roadmap
This is experimental, currently the project is in progress as follows:

1. Patch `libevent`, `zmq`, `boost` for Android (NDK 21, SDK 28) - DONE
2. Cross compiling libs for Android `libevent`, `zmq`, `bdb`, `qt`
3. Linking - DONE
4. Android APK- [PENDING]

Target is to cross-compile with `Qt 6x` in sync with the current Bitcoin core updates. See issue submitted here: 