# android-bitgesell-docker
<img src="Icon.png" style="height: 60px;" />

Docker setup for cross-compiling Bitgesell core for Android (SDK 28+) from a Docker container

## Notes
- Uses `NDK version = `21.4.7075529` (NDK 23 also works)
- Works with `libc++` version and `Qt 5.9` (tested on this release `0.1.9`)


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
git checkout 0.1.13

# run the container
docker run --rm -v $(pwd):/work --user root -it android-bitgesell /bin/bash
cd /work

```

while inside the container in interractive mode,


1. Cross compile libs:
Install cmake:

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

Symlink `QtCore` lib for `configure` to find it easily:

```sh
cd depends/$HOST/lib/pkgconfig
for f in *Qt5*_arm64-v8a.pc; do
    ln -s "$f" "${f/_arm64-v8a/}"
done

```

4. `./configure` to generate Make file:

```sh
./configure --host=$HOST --prefix=$PWD/depends/$HOST   --with-gui=qt5   --enable-glibc-back-compat   --disable-bench   --disable-tests

```

`-DHAVE_WORKING_BOOST_SLEEP` flag propagates the `#define HAVE_WORKING_BOOST_SLEEP` macro to the compiler.


Upon sucess should output:
```sh

Build Options:
  with external callbacks = no
  with benchmarks         = no
  with tests              = no
  with coverage           = no
  with examples           = no
  module ecdh             = no
  module recovery         = yes
  module extrakeys        = yes
  module schnorrsig       = yes

  asm                     = no
  ecmult window size      = 15
  ecmult gen prec. bits   = 4

  valgrind                = no
  CC                      = /opt/android-sdk-linux/ndk/23.1.7779620/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android28-clang
  CPPFLAGS                =  -I/work/depends/aarch64-linux-android/include/ 
  SECP_CFLAGS             = -O2  -std=c89 -pedantic -Wno-long-long -Wnested-externs -Wshadow -Wstrict-prototypes -Wundef -Wno-overlength-strings -Wall -Wno-unused-function -Wextra -Wcast-align -Wconditional-uninitialized -fvisibility=hidden 
  CFLAGS                  = -std=c11 
  LDFLAGS                 = -L/work/depends/aarch64-linux-android/lib -lc++

Options used to compile and link:
  external signer = yes
  multiprocess    = no
  with experimental syscall sandbox support = no
  with libs       = yes
  with wallet     = yes
    with sqlite   = yes
    with bdb      = yes
  with gui / qt   = yes
    with qr       = yes
  with zmq        = yes
  with test       = no
  with fuzz binary = yes
  with bench      = no
  with upnp       = yes
  with natpmp     = yes
  use asm         = yes
  USDT tracing    = no
  sanitizers      = 
  debug enabled   = no
  gprof enabled   = no
  werror          = no
  LTO             = no

  target os       = linux-android
  build os        = linux-gnu

  CC              = /opt/android-sdk-linux/ndk/23.1.7779620/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android28-clang
  CFLAGS          = -pthread -std=c11 
  CPPFLAGS        =   -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2  -DHAVE_BUILD_INFO -DPROVIDE_FUZZ_MAIN_FUNCTION -I/work/depends/aarch64-linux-android/include/ 
  CXX             = /opt/android-sdk-linux/ndk/23.1.7779620/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android28-clang++ -std=c++17
  CXXFLAGS        =    -Wstack-protector -fstack-protector-all      -std=c++17 --std=c++17
  LDFLAGS         =    -Wl,-z,relro -Wl,-z,now -Wl,-z,separate-code -pie   -L/work/depends/aarch64-linux-android/lib -lc++
  ARFLAGS         = cr

```

5. `make -j $(nproc)`
Run make

Before running make, disable `lpthread.so` linking - already included in Android `libc` library:

```sh
sed -E '/^BOOST_LIBS\s*=/c\BOOST_LIBS = -L/work/depends/aarch64-linux-android/lib -lboost_system-mt-s-a64 -lboost_filesystem-mt-s-a64 -lboost_thread-mt-s-a64 -lpthread -lboost_chrono-mt-a64' Makefile | \
sed -E '/^BOOST_SYSTEM_LIB\s*=/c\BOOST_SYSTEM_LIB = -lboost_system-mt-s-a64' | \
sed -E '/^BOOST_THREAD_LIB\s*=/c\BOOST_THREAD_LIB = -lboost_thread-mt-s-a64 -lpthread' | \
tee Makefile.patched > /dev/null && mv Makefile.patched Makefile

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