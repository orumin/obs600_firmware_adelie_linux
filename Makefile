ARCH := powerpc
CROSS_COMPILE := powerpc-unknown-linux-gnu-
MKFS := mkfs.ext4
LZMA := /usr/bin/lzma
MKIMAGE := /usr/bin/mkimage

#KERN_VER := 5.4.5
KERN_VER := 4.19.63

IMAGE_ROOT := $(abspath ./image_root)
DISTS_DIR := $(abspath ./dists)
DIST_FILES_DIR := $(DISTS_DIR)/files

INSTALL_MOD_PATH := $(IMAGE_ROOT)

KERNEL_SOURCE_DIR := ./kernel
BUILD_DIR := ./build
SCRIPTS_DIR := $(abspath ./scripts)

ADELIE_LINUX_URL := https://distfiles.adelielinux.org/adelie/1.0/iso/rc1
ADELIE_LINUX_TARBALL := adelie-rootfs-ppc-1.0-rc1-20200206.txz
TARBALL_URL := $(ADELIE_LINUX_URL)/$(ADELIE_LINUX_TARBALL)
TARBALL_PATH := $(DISTS_DIR)/$(ADELIE_LINUX_TARBALL)

CONFIG_FILE := $(DISTS_DIR)/config-$(KERN_VER)-obs600

KERNEL := $(BUILD_DIR)/vmlinux.bin.gz
INITRD_NAME := initrd
INITRD := $(BUILD_DIR)/$(INITRD_NAME)
INITRD_COMP := $(BUILD_DIR)/$(INITRD_NAME).lzma
DTB := $(BUILD_DIR)/obs600.dtb
UIMAGE := uImage.initrd.obs600

JOBS := $(shell nproc)

NAME := "Adélie Linux for obs600"

.PHONY: all distfiles kernel dtb initrd uImage clean dist-clean clean-all

all: uImage
kernel: $(KERNEL)
dtb: $(DTB)
distfiles: $(TARBALL_PATH)
initrd: $(INITRD_COMP)
uImage: $(UIMAGE)


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

$(TARBALL_PATH):
	curl -L $(TARBALL_URL) -o $@

$(INITRD): kernel distfiles
	if [ ! -e $@ ]; then \
		fallocate -l 510MiB $(INITRD) && \
		$(MKFS) $(INITRD); \
	fi
	@mkdir -p $(IMAGE_ROOT)
	sudo mount -o loop $(INITRD) $(IMAGE_ROOT)
	if [ ! -e $(IMAGE_ROOT)/patched ]; then \
		sudo $(SCRIPTS_DIR)/build_image.sh $(IMAGE_ROOT) $(DIST_FILES_DIR) $(TARBALL_PATH) && \
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

clean:
	$(RM) -rf $(KERNEL) $(DTB) $(INITRD_COMP) $(UIMAGE)

dist-clean:
	$(RM) -rf $(ADELIE_LINUX_TARBALL)

clean-kernel:
	make ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNEL_SOURCE_DIR) clean
	$(RM) -rf $(KERNEL)

clean-initrd:
	$(RM) -rf $(INITRD)

clean-all: clean dist-clean clean-kernel clean-initrd
