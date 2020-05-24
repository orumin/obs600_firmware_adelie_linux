#
# Building multifile firmware image for OBS600
#

# basic environment vars
ARCH := powerpc
CROSS_COMPILE := powerpc-unknown-linux-gnu-
MKFS_EXT4 := mkfs.ext4
MKFS_EXT2 := mke2fs
GZIP := /bin/gzip
CPIO := /bin/cpio
LZMA := /usr/bin/lzma
MKIMAGE := /usr/bin/mkimage

# target software version
#KERN_VER := 5.4.5
KERN_VER := 4.19.63
BUSYBOX_VER := 1.31.0

# PATH
IMAGE_ROOT := $(abspath ./image_root)
IMAGE_ROOT_CFBOOT := $(abspath ./image_root_cfboot)
DISTS_DIR := $(abspath ./dists)
DIST_FILES_DIR := $(DISTS_DIR)/files

INSTALL_MOD_PATH := $(IMAGE_ROOT)

KERNEL_SOURCE_DIR := ./kernel
BUILD_DIR := ./build
SCRIPTS_DIR := $(abspath ./scripts)

# original files
ADELIE_LINUX_URL := https://distfiles.adelielinux.org/adelie/1.0/iso/rc1
ADELIE_LINUX_TARBALL := adelie-rootfs-ppc-1.0-rc1-20200206.txz
ORIGINAL_ROOTFS_IMAGE_URL := $(ADELIE_LINUX_URL)/$(ADELIE_LINUX_TARBALL)
ORIGINAL_ROOTFS_IMAGE := $(DISTS_DIR)/$(ADELIE_LINUX_TARBALL)

CONFIG_FILE := $(DISTS_DIR)/config-$(KERN_VER)-obs600
INIT := $(DISTS_DIR)/init
FILES := $(shell find $(DIST_FILES_DIR) -type f)

# busybox binary
BUSYBOX_URL := https://busybox.net
BUSYBOX_DOWNLOAD_URL := $(BUSYBOX_URL)/downloads/binaries/$(BUSYBOX_VER)-defconfig-multiarch-musl/busybox-powerpc
BUSYBOX_BIN := $(DISTS_DIR)/busybox

# build targets
KERNEL := $(BUILD_DIR)/vmlinux.bin.gz
INITRD_NAME := initrd
INITRD := $(BUILD_DIR)/$(INITRD_NAME)
INITRD_COMP := $(BUILD_DIR)/$(INITRD_NAME).lzma
INITRAMFS_CFBOOT := $(BUILD_DIR)/initramfs-cfboot.img
DTB := $(BUILD_DIR)/obs600.dtb
UIMAGE := uImage.initrd.obs600
UIMAGE_CFBOOT := uImage.initrd-cfboot.obs600

JOBS := $(shell nproc)

NAME := "Adélie Linux for obs600"

.PHONY: all distfiles kernel dtb initrd uImage uImage-cfboot clean dist-clean clean-all

all: uImage
kernel: $(KERNEL)
dtb: $(DTB)
distfiles: $(ORIGINAL_ROOTFS_IMAGE) $(BUSYBOX_BIN) $(CONFIG_FILE) $(INIT) $(FILES)
initrd: $(INITRD_COMP)
uImage: $(UIMAGE)
uImage-cfboot: $(UIMAGE_CFBOOT)


$(KERNEL):
	cp $(CONFIG_FILE) $(KERNEL_SOURCE_DIR)/.config
	make ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNEL_SOURCE_DIR) uImage -j$(JOBS)
	make ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNEL_SOURCE_DIR) modules -j$(JOBS)
	cp $(KERNEL_SOURCE_DIR)/vmlinux.bin.gz $(BUILD_DIR)/

$(DTB): $(KERNEL)
	make ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNEL_SOURCE_DIR) obs600.dtb
ifeq ($(KERN_VER), 4.19.63)
	cp $(KERNEL_SOURCE_DIR)/arch/powerpc/boot/obs600.dtb $(BUILD_DIR)/
else
	cp $(KERNEL_SOURCE_DIR)/arch/powerpc/boot/dts/obs600.dtb $(BUILD_DIR)/
endif

$(BUSYBOX_BIN):
	curl -L $(BUSYBOX_DOWNLOAD_URL) -o $@

$(ORIGINAL_ROOTFS_IMAGE):
	curl -L $(ORIGINAL_ROOTFS_IMAGE_URL) -o $@

$(INITRD): kernel distfiles
	if [ ! -e $@ ]; then \
		fallocate -l 510MiB $@ && \
		$(MKFS_EXT4) $@; \
	fi
	@mkdir -p $(IMAGE_ROOT)
	sudo mount -o loop $@ $(IMAGE_ROOT)
	if [ ! -e $(IMAGE_ROOT)/patched ]; then \
		sudo $(SCRIPTS_DIR)/build_image.sh $(IMAGE_ROOT) $(DIST_FILES_DIR) $(ORIGINAL_ROOTFS_IMAGE) && \
		sudo touch $(IMAGE_ROOT)/patched; \
	fi; \
	ret=$$?; \
	if [ $$ret != 0 ]; then \
		sudo umount $(IMAGE_ROOT); \
		exit 1; \
	fi
	sudo make ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) INSTALL_MOD_PATH=$(INSTALL_MOD_PATH) -C $(KERNEL_SOURCE_DIR) modules_install; \
	sudo umount $(IMAGE_ROOT)

$(INITRD_COMP): $(INITRD)
	$(LZMA) -9 < $^ > $@

$(UIMAGE): $(DTB) $(INITRD_COMP)
	$(MKIMAGE) -n $(NAME) -A ppc -O linux -T multi -C gzip -d $(KERNEL):$(INITRD_COMP):$(DTB) $@

$(INITRAMFS_CFBOOT): distfiles
	mkdir -p $(IMAGE_ROOT_CFBOOT)
	sudo $(SCRIPTS_DIR)/build_image_cfboot.sh $(IMAGE_ROOT_CFBOOT) $(BUSYBOX_BIN) $(INIT)
	cd $(IMAGE_ROOT_CFBOOT) && \
		find . | $(CPIO) --quiet -H newc -o | $(GZIP) -9 -n > ../$@
	sudo rm -rf $(IMAGE_ROOT_CFBOOT)

$(UIMAGE_CFBOOT): $(DTB) $(INITRAMFS_CFBOOT)
	$(MKIMAGE) -n $(NAME) -A ppc -O linux -T multi -C gzip -d $(KERNEL):$(INITRAMFS_CFBOOT):$(DTB) $@

clean:
	$(RM) -rf $(KERNEL) $(DTB) $(INITRD_COMP) $(INITRAMFS_CFBOOT) $(UIMAGE) $(UIMAGE_CFBOOT)

dist-clean:
	$(RM) -rf $(ADELIE_LINUX_TARBALL)

clean-kernel:
	make ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNEL_SOURCE_DIR) clean
	$(RM) -rf $(KERNEL) $(DTB)

clean-initrd:
	$(RM) -rf $(INITRD) $(INITRD_COMP) $(INITRD_CFBOOT) $(INITRD_CFBOOT_COMP)

clean-all: clean dist-clean clean-kernel clean-initrd
