# Copyright (C) Silver Lining Networks
#
# Modified to create Silver Lining packages
#
# Copyright (C) firmware-ng contributors
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public
# License as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA
#

BUILD_DIR = build

OWRT_DIST_SVN_PATH = openwrt/tags/8.09.1
OWRT_DIST_LOCAL_PATH = openwrt-build
OWRT_DIST_SVN_REV = 16279

OWRT_PKG_SVN_PATH = openwrt/packages
OWRT_PKG_LOCAL_PATH = openwrt-packages-build
OWRT_PKG_SVN_REV = 17505

ROBIN_SVN_PATH = https://svn2.hosted-projects.com/ansanto/robin-mesh/tags/test/current
ROBIN_LOCAL_PATH = robin-build
ROBIN_SVN_REV = 644

PATCHES_PATH = patches

ROBIN_PKG_LIST = libs/libmatrixssl-nothread net/nodogsplash net/robin-mesh-chilli net/wget-matrix utils/scanparser utils/start-stop-daemon/ utils/xxd

SLN_PKG_LIST = silverlining

PACKAGE_LIST = net/fping net/iputils net/mii-tool net/olsrd libs/uclibc++ lang/perl

ROBIN_BUILD_VER = $(shell if [ -d .svn ]; then \
				if which svn > /dev/null; then \
					svn info | grep "Rev:" | sed -e '1p' -n | awk '{print "r"$$4}'; \
				fi \
			 else \
				if [ -d .git ]; then \
					git_rev=`git log --grep="git-svn-id" -n1 --format=short | grep commit | awk '{print $$2}'`; \
					git svn find-rev $$git_rev | awk '{print "r"$$1"g"}'; \
				fi; \
			 fi)

ifeq ($(ROBIN_BUILD_VER),)
ROBIN_BUILD_VER = unknown
endif

all: owrt_checkout robin_checkout build_fw

owrt_checkout:
	svn co -r $(OWRT_DIST_SVN_REV) svn://svn.openwrt.org/$(OWRT_DIST_SVN_PATH) $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)
	svn co -r $(OWRT_PKG_SVN_REV) svn://svn.openwrt.org/$(OWRT_PKG_SVN_PATH) $(BUILD_DIR)/$(OWRT_PKG_LOCAL_PATH)
	cd $(BUILD_DIR) && touch $@

robin_checkout:
	svn co $(ROBIN_SVN_PATH) $(BUILD_DIR)/$(ROBIN_LOCAL_PATH)
	svn update -r $(ROBIN_SVN_REV) $(BUILD_DIR)/$(ROBIN_LOCAL_PATH)
	cd $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/package && \
		$(foreach PACKAGE, $(ROBIN_PKG_LIST), ln -sf ../../$(ROBIN_LOCAL_PATH)/openwrt-packages/$(PACKAGE) .;)
	cd $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/package && $(foreach PACKAGE, $(PACKAGE_LIST), ln -sf ../../$(OWRT_PKG_LOCAL_PATH)/$(PACKAGE) .;)
	cd $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/package && ln -sf ../../$(ROBIN_LOCAL_PATH)/robin-mesh .
	cd $(BUILD_DIR)/$(ROBIN_LOCAL_PATH) && patch -l -p0 < ../../$(PATCHES_PATH)/early-jffs2-format.patch
	cd $(BUILD_DIR)/$(ROBIN_LOCAL_PATH)/robin-mesh/files/etc/init.d/ && chmod +x done jffs2-format
	cd $(BUILD_DIR) && touch $@

sln_setup:
	cd $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/package && \
		$(foreach PACKAGE, $(SLN_PKG_LIST), ln -sf ../../package/$(PACKAGE) .;)


apply_patches:
	cp $(PATCHES_PATH)/600-fix-sc-cal-ch-timer.patch $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/package/madwifi/patches
	patch -l -p0 < $(PATCHES_PATH)/perl.patch

standard_config: apply_patches sln_setup
	cp $(BUILD_DIR)/$(ROBIN_LOCAL_PATH)/default-config $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/.config
	echo "CONFIG_PACKAGE_scanparser=y" >> $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/.config
	echo "CONFIG_PACKAGE_sln=m" >> $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/.config
	echo "CONFIG_PACKAGE_kmod-sln=m" >> $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/.config
	echo "CONFIG_PACKAGE_microperl=m" >> $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/.config
	cp $(PATCHES_PATH)/config-default-small-8_09 $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/target/linux/atheros/config-default
	$(shell echo $(ROBIN_BUILD_VER) > $(BUILD_DIR)/$(ROBIN_LOCAL_PATH)/robin-mesh/files/etc/robin_build_version)

build_fw: standard_config
	cd $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH) && make

build_fw_dev: standard_config
	# checkout trunk/packages
	$(MAKE) -C $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/packages/debug/config-options/ OWRT_DIST_LOCAL_PATH=$(PWD)/$(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH) all
	find $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/packages/ -name '*~' | xargs rm -rf
	cd $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH) && make

build_robin_kernel: owrt_checkout robin_checkout
	cp $(BUILD_DIR)/$(ROBIN_LOCAL_PATH)/atheros-config-default $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH)/target/linux/atheros/config-default
	cd $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH) && make target/linux-clean && make target/linux-install

clean:
	cd $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH) && make clean
	rm -rf $(BUILD_DIR)/robin_checkout $(BUILD_DIR)/$(ROBIN_LOCAL_PATH)

distclean: clean
	rm -rf $(BUILD_DIR)/owrt_checkout $(BUILD_DIR)/$(OWRT_DIST_LOCAL_PATH) $(BUILD_DIR)/$(OWRT_PKG_LOCAL_PATH)
	rm -rf $(BUILD_DIR)/owrt_patches $(BUILD_DIR)/owrt_config

