package=qrencode

qrencode_version=3.4.4
qrencode_download_path=https://github.com/fukuchi/libqrencode/archive/refs/tags/
qrencode_file_name=v3.4.4.tar.gz
qrencode_sha256_hash=ab7cdf84e3707573a39e116ebd33faa513b306201941df3f5e691568368d87bf

define qrencode_set_vars
	qrencode_config_opts=--disable-shared --without-tools --without-tests --disable-sdltest
	qrencode_config_opts += --disable-gprof --disable-gcov --disable-mudflap
	qrencode_config_opts += --disable-dependency-tracking --enable-option-checking
	qrencode_config_opts += --host=$(host) ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
	qrencode_config_opts_linux=--with-pic
	qrencode_config_opts_android=--with-pic

	qrencode_src_dir=$(BASEDIR)/qrencode-$(qrencode_version)
	qrencode_build_dir=$(BASEDIR)/work/build/$(host)/qrencode/$(qrencode_version)-$(package_id)
endef

define qrencode_preprocess_cmds
	echo "Fetching $(qrencode_file_name) from $(qrencode_download_path)"
	curl -LO $(qrencode_download_path)$(qrencode_file_name)

	tar -xzvf $(qrencode_file_name) -C /work/depends/

	if [ -d "/work/depends/qrencode-$(qrencode_version)" ]; then rm -rf /work/depends/qrencode-$(qrencode_version); fi
	mv /work/depends/libqrencode-$(qrencode_version) /work/depends/qrencode-$(qrencode_version)

	mkdir -p /work/depends/qrencode-$(qrencode_version)/use

	cp -f $(BASEDIR)/config.guess $(BASEDIR)/config.sub /work/depends/qrencode-$(qrencode_version)/use/
endef

define qrencode_config_cmds
	cd $(qrencode_src_dir) && autoreconf -i
	mkdir -p $(qrencode_build_dir)
	cd $(qrencode_build_dir) && $(qrencode_src_dir)/configure $(qrencode_config_opts)
endef

define qrencode_build_cmds
	cd $(qrencode_build_dir) && $(MAKE)
endef

define qrencode_stage_cmds
	cd $(qrencode_build_dir) && $(MAKE) DESTDIR=$(qrencode_staging_dir) install
endef

define qrencode_postprocess_cmds
	# Remove .la files from the correct staging directory
	rm -f $(qrencode_staging_dir)/usr/local/lib/*.la
endef
