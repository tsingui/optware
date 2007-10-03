###########################################################
#
# kernel-modules
#
###########################################################

ifeq ($(OPTWARE_TARGET), mssii)

MSSII_GPL_SOURCE_SITE=http://www.seagate.com/staticfiles/maxtor/en_us/downloads
MSSII_GPL_SOURCE=MSSII_3.1.2.src.tgz
# KERNEL_SOURCE_SITE=http://www.kernel.org/pub/linux/kernel/v2.6
# KERNEL_SOURCE=MSSII_3.1.2.src-kernel.tar.bz2
KERNEL_VERSION=2.6.12.6
KERNEL-MODULES_DIR=linux-$(KERNEL_VERSION)
KERNEL-MODULES_MAINTAINER=NSLU2 Linux <nslu2-linux@yahoogroups.com>
KERNEL-MODULES_DESCRIPTION=MSS II kernel modules
KERNEL-IMAGE_DESCRIPTION=MSS II kernel
KERNEL-MODULES_SECTION=kernel
KERNEL-MODULES_PRIORITY=optional
KERNEL-MODULES_DEPENDS=
KERNEL-MODULES_SUGGESTS=
KERNEL-MODULES_CONFLICTS=
KERNEL-MODULES=`find $(KERNEL-MODULES_IPK_DIR) -name *.ko`

#
# KERNEL-MODULES_IPK_VERSION should be incremented when the ipk changes.
#
KERNEL-MODULES_IPK_VERSION=1

#
# KERNEL-MODULES_CONFFILES should be a list of user-editable files
#KERNEL-MODULES_CONFFILES=/opt/etc/kernel-modules.conf /opt/etc/init.d/SXXkernel-modules

#
# KERNEL-MODULES_PATCHES should list any patches, in the the order in
# which they should be applied to the source code.
#
#KERNEL-MODULES_PATCHES = \
	$(MSSII_GPL_SOURCE_DIR)/arch-arm-Makefile.patch \

#
# If the compilation of the package requires additional
# compilation or linking flags, then list them here.
#
KERNEL-MODULES_CPPFLAGS=
KERNEL-MODULES_LDFLAGS=

MSSII_GPL_SOURCE_DIR=$(SOURCE_DIR)/mssii-kernel-modules
KERNEL_BUILD_DIR=$(BUILD_DIR)/kernel-modules

KERNEL-MODULES_IPK_DIR=$(BUILD_DIR)/kernel-modules-$(KERNEL_VERSION)-ipk
KERNEL-MODULES_IPK=$(BUILD_DIR)/kernel-modules_$(KERNEL_VERSION)-$(KERNEL-MODULES_IPK_VERSION)_$(TARGET_ARCH).ipk

KERNEL-IMAGE_IPK_DIR=$(BUILD_DIR)/mssii-kernel-image-$(KERNEL_VERSION)-ipk
KERNEL-IMAG_IPK=$(BUILD_DIR)/mssii-kernel-image_$(KERNEL_VERSION)-$(KERNEL-MODULES_IPK_VERSION)_$(TARGET_ARCH).ipk

#
# This is the dependency on the source code.  If the source is missing,
# then it will be fetched from the site using wget.
#
$(DL_DIR)/$(MSSII_GPL_SOURCE):
	$(WGET) -P $(DL_DIR) $(MSSII_GPL_SOURCE_SITE)/$(MSSII_GPL_SOURCE) || \
	$(WGET) -P $(DL_DIR) $(SOURCES_NLO_SITE)/$(MSSII_GPL_SOURCE)

#
# The source code depends on it existing within the download directory.
# This target will be called by the top level Makefile to download the
# source code's archive (.tar.gz, .bz2, etc.)
#
kernel-modules-source: $(DL_DIR)/$(MSSII_GPL_SOURCE) $(KERNEL-MODULES_PATCHES)

$(KERNEL_BUILD_DIR)/.configured: \
$(DL_DIR)/$(MSSII_GPL_SOURCE) $(KERNEL-MODULES_PATCHES) \
$(MSSII_GPL_SOURCE_DIR)/defconfig make/mssii-kernel-modules.mk
	$(MAKE) u-boot-mkimage
	rm -rf $(BUILD_DIR)/$(KERNEL-MODULES_DIR) $(KERNEL_BUILD_DIR)
	mkdir -p $(KERNEL_BUILD_DIR)
	tar -xOvzf $(DL_DIR)/$(MSSII_GPL_SOURCE) kernel.tar.bz2 | \
		tar -C $(KERNEL_BUILD_DIR) -xjvf -
	if test -n "$(KERNEL-MODULES_PATCHES)" ; \
		then cat $(KERNEL-MODULES_PATCHES) | \
		patch -d $(BUILD_DIR)/$(KERNEL-MODULES_DIR) -p1 ; \
	fi
#	if test "$(BUILD_DIR)/$(KERNEL-MODULES_DIR)" != "$(KERNEL_BUILD_DIR)" ; \
		then mv $(BUILD_DIR)/$(KERNEL-MODULES_DIR) $(KERNEL_BUILD_DIR) ; \
	fi
	touch $@

kernel-modules-unpack: $(KERNEL_BUILD_DIR)/.configured

KERNEL-MODULES-FLAGS = ARCH=arm EXTRAVERSION=.6-arm1 ROOTDIR=$(KERNEL_BUILD_DIR) CROSS_COMPILE=$(TARGET_CROSS)

#
# This builds the actual binary.
#
$(KERNEL_BUILD_DIR)/.built: $(KERNEL_BUILD_DIR)/.configured
	rm -f $@
#	$(MAKE) -C $(KERNEL_BUILD_DIR) $(KERNEL-MODULES-FLAGS) clean
	cp  $(MSSII_GPL_SOURCE_DIR)/defconfig $(KERNEL_BUILD_DIR)/.config;
	$(MAKE) -C $(KERNEL_BUILD_DIR) $(KERNEL-MODULES-FLAGS) oldconfig
	PATH=$(HOST_STAGING_PREFIX)/bin:$$PATH \
	$(MAKE) -C $(KERNEL_BUILD_DIR) $(KERNEL-MODULES-FLAGS) uImage modules
	touch $@

kmod: $(KERNEL_BUILD_DIR)/.built
	rm -rf $(KERNEL-MODULES_IPK_DIR)* $(BUILD_DIR)/kernel-modules_*_$(TARGET_ARCH).ipk
	rm -rf $(KERNEL-MODULES_IPK_DIR)/lib/modules
	mkdir -p $(KERNEL-MODULES_IPK_DIR)/lib/modules
	$(MAKE) -C $(KERNEL_BUILD_DIR) $(KERNEL-MODULES-FLAGS) \
		INSTALL_MOD_PATH=$(KERNEL-MODULES_IPK_DIR) modules_install

#
# This is the build convenience target.
#
kernel-modules: $(KERNEL_BUILD_DIR)/.built

#
# This rule creates a control file for ipkg.  It is no longer
# necessary to create a seperate control file under sources/kernel-modules
#
$(KERNEL-MODULES_IPK_DIR)/CONTROL/control:
	install -d $(@D)
	( \
	  echo "Package: kernel-modules"; \
	  echo "Architecture: $(TARGET_ARCH)"; \
	  echo "Priority: $(KERNEL-MODULES_PRIORITY)"; \
	  echo "Section: $(KERNEL-MODULES_SECTION)"; \
	  echo "Version: $(KERNEL_VERSION)-$(KERNEL-MODULES_IPK_VERSION)"; \
	  echo "Maintainer: $(KERNEL-MODULES_MAINTAINER)"; \
	  echo "Source: $(MSSII_GPL_SOURCE_SITE)/$(MSSII_GPL_SOURCE)"; \
	  echo "Description: $(KERNEL-MODULES_DESCRIPTION)"; \
	  echo -n "Depends: kernel-image"; \
	) >> $(KERNEL-MODULES_IPK_DIR)/CONTROL/control; \
	for m in $(KERNEL-MODULES); do \
	  m=`basename $$m .ko`; \
	  n=`echo $$m | sed -e 's/_/-/g' | tr '[A-Z]' '[a-z]'`; \
	  install -d $(KERNEL-MODULES_IPK_DIR)-$$n/CONTROL; \
	  rm -f $(KERNEL-MODULES_IPK_DIR)-$$n/CONTROL/control; \
          ( \
	    echo -n ", kernel-module-$$n" >> $(KERNEL-MODULES_IPK_DIR)/CONTROL/control; \
	    echo "Package: kernel-module-$$n"; \
	    echo "Architecture: $(TARGET_ARCH)"; \
	    echo "Priority: $(KERNEL-MODULES_PRIORITY)"; \
	    echo "Section: $(KERNEL-MODULES_SECTION)"; \
	    echo "Version: $(KERNEL_VERSION)-$(KERNEL-MODULES_IPK_VERSION)"; \
	    echo "Maintainer: $(KERNEL-MODULES_MAINTAINER)"; \
	    echo "Source: $(MSSII_GPL_SOURCE_SITE)/$(MSSII_GPL_SOURCE)"; \
	    echo "Description: $(KERNEL-MODULES_DESCRIPTION) $$m"; \
	    echo -n "Depends: "; \
            DEPS="$(KERNEL-MODULES_DEPENDS)"; \
	    for i in `grep "$$m.ko:" $(KERNEL-MODULES_IPK_DIR)/lib/modules/$(KERNEL_VERSION)/modules.dep|cut -d ":" -f 2`; do \
	      if test -n "$$DEPS"; \
	      then DEPS="$$DEPS,"; \
	      fi; \
	      j=`basename $$i .ko | sed -e 's/_/-/g' | tr '[A-Z]' '[a-z]'`; \
	      DEPS="$$DEPS kernel-module-$$j"; \
            done; \
            echo "$$DEPS";\
	    echo "Suggests: $(KERNEL-MODULES_SUGGESTS)"; \
	    echo "Conflicts: $(KERNEL-MODULES_CONFLICTS)"; \
	  ) >> $(KERNEL-MODULES_IPK_DIR)-$$n/CONTROL/control; \
	done
	echo "" >> $(KERNEL-MODULES_IPK_DIR)/CONTROL/control

$(KERNEL-IMAGE_IPK_DIR)/CONTROL/control:
	install -d $(@D)
	rm -f $(KERNEL-IMAGE_IPK_DIR)/CONTROL/control
	( \
	  echo "Package: kernel-image"; \
	  echo "Architecture: $(TARGET_ARCH)"; \
	  echo "Priority: $(KERNEL-MODULES_PRIORITY)"; \
	  echo "Section: $(KERNEL-MODULES_SECTION)"; \
	  echo "Version: $(KERNEL_VERSION)-$(KERNEL-MODULES_IPK_VERSION)"; \
	  echo "Maintainer: $(KERNEL-MODULES_MAINTAINER)"; \
	  echo "Source: $(MSSII_GPL_SOURCE_SITE)/$(MSSII_GPL_SOURCE)"; \
	  echo "Description: $(KERNEL-IMAGE_DESCRIPTION)"; \
	) >> $(KERNEL-IMAGE_IPK_DIR)/CONTROL/control

#
# This builds the IPK file.
#
# Binaries should be installed into $(KERNEL-MODULES_IPK_DIR)/opt/sbin or $(KERNEL-MODULES_IPK_DIR)/opt/bin
# (use the location in a well-known Linux distro as a guide for choosing sbin or bin).
# Libraries and include files should be installed into $(KERNEL-MODULES_IPK_DIR)/opt/{lib,include}
# Configuration files should be installed in $(KERNEL-MODULES_IPK_DIR)/opt/etc/kernel-modules/...
# Documentation files should be installed in $(KERNEL-MODULES_IPK_DIR)/opt/doc/kernel-modules/...
# Daemon startup scripts should be installed in $(KERNEL-MODULES_IPK_DIR)/opt/etc/init.d/S??kernel-modules
#
# You may need to patch your application to make it use these locations.
#
$(KERNEL_BUILD_DIR)/.ipkdone: $(KERNEL_BUILD_DIR)/.built
	rm -f $(BUILD_DIR)/kernel-modules_*_$(TARGET_ARCH).ipk
	rm -f $(BUILD_DIR)/kernel-module-*_$(TARGET_ARCH).ipk
	rm -f $(BUILD_DIR)/kernel-image_*_$(TARGET_ARCH).ipk
	# Package the kernel image first
	rm -rf $(KERNEL-IMAGE_IPK_DIR)* $(BUILD_DIR)/mssii-kernel-image_*_$(TARGET_ARCH).ipk
	$(MAKE) $(KERNEL-IMAGE_IPK_DIR)/CONTROL/control
	install -m 644 $(KERNEL_BUILD_DIR)/arch/arm/boot/zImage $(KERNEL-IMAGE_IPK_DIR)
	( cd $(BUILD_DIR); $(IPKG_BUILD) $(KERNEL-IMAGE_IPK_DIR) )
	# Now package the kernel modules
	rm -rf $(KERNEL-MODULES_IPK_DIR)* $(BUILD_DIR)/kernel-modules_*_$(TARGET_ARCH).ipk
	rm -rf $(KERNEL-MODULES_IPK_DIR)/lib/modules
	mkdir -p $(KERNEL-MODULES_IPK_DIR)/lib/modules
	$(MAKE) -C $(KERNEL_BUILD_DIR) $(KERNEL-MODULES-FLAGS) \
		INSTALL_MOD_PATH=$(KERNEL-MODULES_IPK_DIR) modules_install
	for m in $(KERNEL-MODULES); do \
	  m=`basename $$m .ko`; \
	  n=`echo $$m | sed -e 's/_/-/g' | tr '[A-Z]' '[a-z]'`; \
	  ( cd $(KERNEL-MODULES_IPK_DIR) ; install -D -m 644 `find . -iname $$m.ko` $(KERNEL-MODULES_IPK_DIR)-$$n/`find . -iname $$m.ko` ); \
	done
	$(MAKE) $(KERNEL-MODULES_IPK_DIR)/CONTROL/control
	for m in $(KERNEL-MODULES); do \
	  m=`basename $$m .ko`; \
	  n=`echo $$m | sed -e 's/_/-/g' | tr '[A-Z]' '[a-z]'`; \
	  cd $(BUILD_DIR); $(IPKG_BUILD) $(KERNEL-MODULES_IPK_DIR)-$$n; \
	done
	rm -f $(KERNEL-MODULES_IPK_DIR)/lib/modules/$(KERNEL_VERSION)/build
	rm -f $(KERNEL-MODULES_IPK_DIR)/lib/modules/$(KERNEL_VERSION)/source
	rm -rf $(KERNEL-MODULES_IPK_DIR)/lib/modules/$(KERNEL_VERSION)/kernel
	( cd $(BUILD_DIR); $(IPKG_BUILD) $(KERNEL-MODULES_IPK_DIR) )
	touch $@

#
# This is called from the top level makefile to create the IPK file.
#
kernel-modules-ipk: $(KERNEL_BUILD_DIR)/.ipkdone

#
# This is called from the top level makefile to clean all of the built files.
#
kernel-modules-clean:
	rm -f $(KERNEL_BUILD_DIR)/.built
	-$(MAKE) -C $(KERNEL_BUILD_DIR) clean

#
# This is called from the top level makefile to clean all dynamically created
# directories.
#
kernel-modules-dirclean:
	rm -rf $(BUILD_DIR)/$(KERNEL-MODULES_DIR) $(KERNEL_BUILD_DIR)
	rm -rf $(KERNEL-MODULES_IPK_DIR)* $(KERNEL-IMAGE_IPK_DIR)* 
	rm -f $(BUILD_DIR)/kernel-modules_*_armeb.ipk
	rm -f $(BUILD_DIR)/kernel-module-*_armeb.ipk
	rm -f $(BUILD_DIR)/kernel-image-*_armeb.ipk

endif
