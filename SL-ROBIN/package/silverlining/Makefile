# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile 8659 2007-09-07 08:34:51Z nico $

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=sln
PKG_VERSION:=0.20
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/sln
  SUBMENU:=Netfilter Extensions
  TITLE:=Silver Lining conntrack and nat helpers
  DEPENDS:=@LINUX_2_6 +kmod-ipt-nat
  MAINTAINER:=fred@redhotpenguin.com
  FILES:=$(PKG_BUILD_DIR)/nf_nat_sl.$(LINUX_KMOD_SUFFIX) $(PKG_BUILD_DIR)/nf_conntrack_sl.$(LINUX_KMOD_SUFFIX)
  AUTOLOAD:=$(call AutoLoad,70,sln)
endef

define KernelPackage/sln/description
 Silver Lining conntrack and nat helpers
 Includes:
 - nf_nat_sl
 - nf_conntrack_sl
endef

EXTRA_KCONFIG:= \
	CONFIG_NF_NAT_SL=m \
	CONFIG_NF_CONNTRACK_SL=m


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
