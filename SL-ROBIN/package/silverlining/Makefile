# 
# Copyright (C) 2009 Silver Lining Networks
#
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=sln
PKG_VERSION:=0.20
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/sln
  SUBMENU:=Netfilter Extensions
  TITLE:=Silver Lining conntrack and nat helpers
  DEPENDS:=@LINUX_2_6_23
  MAINTAINER:=fred@redhotpenguin.com
  FILES:=$(PKG_BUILD_DIR)/nf_nat_sl.$(LINUX_KMOD_SUFFIX) \
	 $(PKG_BUILD_DIR)/nf_conntrack_sl.$(LINUX_KMOD_SUFFIX) \
         $(LINUX_DIR)/lib/ts_kmp.$(LINUX_KMOD_SUFFIX) \
	 $(LINUX_DIR)/lib/ts_bm.$(LINUX_KMOD_SUFFIX) \
	 $(LINUX_DIR)/lib/ts_fsm.$(LINUX_KMOD_SUFFIX) 
  AUTOLOAD:=$(call AutoLoad,70,ts_kmp ts_bm ts_fsm nf_conntrack_sl nf_nat_sl)
endef

define KernelPackage/sln/description
 Silver Lining conntrack and nat helpers
 Includes:
 - nf_nat_sl
 - nf_conntrack_sl
 - ts_bm
 - ts_kmp
 - ts_fsm
endef

EXTRA_KCONFIG:= \
	CONFIG_NF_NAT_SL=m \
	CONFIG_NF_CONNTRACK_SL=m
	CONFIG_TEXTSEARCH=y \
	CONFIG_TEXTSEARCH_KMP \
	CONFIG_TEXTSEARCH_BM \
	CONFIG_TEXTSEARCH_FSM 

MAKE_OPTS:= \
	ARCH="$(LINUX_KARCH)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	SUBDIRS="$(PKG_BUILD_DIR)" \
	EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
	LINUXINCLUDE="-I$(LINUX_DIR)/include -I$(PKG_BUILD_DIR)/ -include linux/autoconf.h" \
	$(EXTRA_KCONFIG)


define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./files/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		$(MAKE_OPTS) \
		modules
endef

$(eval $(call KernelPackage,sln))
