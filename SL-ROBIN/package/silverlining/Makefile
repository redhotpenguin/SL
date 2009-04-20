# 
# Copyright (C) 2009 Silver Lining Networks
#
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=sln
PKG_VERSION:=0.20
PKG_RELEASE:=11

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk


define Package/sln
  SECTION:=net
  CATEGORY:=Network
  URL:=http://www.silverliningnetworks.com/
  DEPENDS:=+kmod-sln +microperl
  TITLE:=SLN Plugin
  MENU:=1
endef

define Package/sln/description
 This package contains the SLN helpers
endef



define KernelPackage/sln
  SUBMENU:=Netfilter Extensions
  TITLE:=Silver Lining conntrack and nat helpers
  DEPENDS:=@LINUX_2_6_23
  MAINTAINER:=fred@redhotpenguin.com
  FILES:=$(PKG_BUILD_DIR)/nf_nat_sl.$(LINUX_KMOD_SUFFIX) \
	 $(PKG_BUILD_DIR)/nf_conntrack_sl.$(LINUX_KMOD_SUFFIX) \
	$(LINUX_DIR)/lib/ts_kmp.$(LINUX_KMOD_SUFFIX)
  AUTOLOAD:=$(call AutoLoad,70,ts_kmp nf_conntrack_sl nf_nat_sl)
endef

define KernelPackage/sln/description
 Silver Lining conntrack and nat helpers
 Includes:
 - nf_nat_sl
 - nf_conntrack_sl
 - ts_kmp
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
	rm -rf $(PKG_INSTALL_DIR)
	mkdir -p $(PKG_INSTALL_DIR)/usr/bin/
	mkdir -p $(PKG_INSTALL_DIR)/etc/sl/
        mkdir -p $(PKG_INSTALL_DIR)/etc/init.d/
	$(MAKE) -C "$(LINUX_DIR)" \
		$(MAKE_OPTS) \
		modules
endef

define Package/sln/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/* $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/sl
	$(INSTALL_BIN) ./files/etc/sl/* $(1)/etc/sl/
        $(INSTALL_DIR) $(1)/etc/init.d
        $(INSTALL_BIN) ./files/etc/init.d/* $(1)/etc/init.d/
endef

define Package/sln/postinst
#!/bin/sh
# check to see if we are on a real system
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/sln enable
	/usr/bin/microperl /usr/bin/sl_cron
fi
exit
endef

$(eval $(call KernelPackage,sln))
$(eval $(call BuildPackage,sln))
