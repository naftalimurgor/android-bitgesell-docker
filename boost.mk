package=boost
$(package)_version=1_70_0
$(package)_download_path=https://dl.bintray.com/boostorg/release/1.70.0/source/
$(package)_file_name=$(package)_$($(package)_version).tar.bz2
$(package)_sha256_hash=430ae8354789de4fd19ee52f3b1f739e1fba576f0aded0897c3c2bc00fb38778

# Absolute paths for Boost
$(package)_source_dir=/work/depends/sources/boost_1_70_0
$(package)_staging_prefix_dir=/work/depends/staging/boost_1_70_0

define $(package)_set_vars
	$(package)_config_opts_release=variant=release
	$(package)_config_opts_debug=variant=debug
	$(package)_config_opts=--layout=tagged --build-type=complete --user-config=user-config.jam
	$(package)_config_opts+=threading=multi link=static -sNO_BZIP2=1 -sNO_ZLIB=1
	$(package)_config_opts_linux=threadapi=pthread runtime-link=shared
	$(package)_config_opts_darwin=--toolset=clang-darwin runtime-link=shared
	$(package)_config_opts_mingw32=binary-format=pe target-os=windows threadapi=win32 runtime-link=static
	$(package)_config_opts_x86_64_mingw32=address-model=64
	$(package)_config_opts_i686_mingw32=address-model=32
	$(package)_config_opts_i686_linux=address-model=32 architecture=x86
	$(package)_config_opts_i686_android=address-model=32 threadapi=pthread
	$(package)_config_opts_aarch64_android=address-model=64 threadapi=pthread
	$(package)_config_opts_x86_64_android=address-model=64 threadapi=pthread
	$(package)_config_opts_armv7a_android=address-model=32 threadapi=pthread
	$(package)_toolset_$(host_os)=gcc
	$(package)_archiver_$(host_os)=$($(package)_ar)
	$(package)_toolset_darwin=clang-darwin
	$(package)_config_libraries=chrono,filesystem,system,thread,test
	$(package)_cxxflags=-std=c++11 -fvisibility=hidden
	$(package)_cxxflags_linux=-fPIC
	$(package)_cxxflags_android=-fPIC
endef

define $(package)_preprocess_cmds
	echo "using $(boost_toolset_$(host_os)) : : $($(package)_cxx) : <cxxflags>\"$($(package)_cxxflags) $($(package)_cppflags)\" <linkflags>\"$($(package)_ldflags)\" <archiver>\"$(boost_archiver_$(host_os))\" <striper>\"$(host_STRIP)\"  <ranlib>\"$(host_RANLIB)\" <rc>\"$(host_WINDRES)\" : ;" > $(package)_source_dir/user-config.jam
endef

define $(package)_config_cmds
	# Absolute path to bootstrap.sh
	$(package)_source_dir/bootstrap.sh --without-icu --with-libraries=chrono,filesystem,system,thread,test
endef

define $(package)_build_cmds
	# Absolute path to b2
	$(package)_source_dir/b2 -d2 -j2 -d1 --prefix=$(package)_staging_prefix_dir $($(package)_config_opts) stage
endef

define $(package)_stage_cmds
	# Absolute path to b2
	$(package)_source_dir/b2 -d0 -j4 --prefix=$(package)_staging_prefix_dir $($(package)_config_opts) install
endef
