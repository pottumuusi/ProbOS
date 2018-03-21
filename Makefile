OUT_DIR := out
OUT_ISO := $(OUT_DIR)/iso
OUT_BOOT := $(OUT_ISO)/boot
OUT_GRUB := $(OUT_BOOT)/grub

SRC_DIR := src

src_w = $(wildcard $(SRC_DIR)/*.s)
obj_extension = $(src_w:.s=.o)
OBJ_OUT = $(subst src/,out/,$(obj_extension))

KERNEL_OUT := $(OUT_BOOT)/kernel.bin
GRUBCFG_OUT := $(OUT_GRUB)/grub.cfg
GRUBCFG_SRC := $(SRC_DIR)/grub.cfg

BOOTABLE_OUT := $(OUT_DIR)/probos.iso

ASM := nasm
ASM_FLAGS := -f elf64

LD_SCRIPT := $(SRC_DIR)/linker.ld
LDFLAGS := -n -T $(LD_SCRIPT)
LD := ld

.PHONY: all clean burn simulate iso

$(shell if [ ! -d $(OUT_GRUB) ] ; then mkdir -p $(OUT_GRUB) ; fi)

all: $(KERNEL_OUT) $(GRUBCFG_OUT)

$(BOOTABLE_OUT): $(KERNEL_OUT) $(GRUBCFG_OUT)
	$(shell grub-mkrescue -o $@ $(OUT_ISO))

$(OUT_DIR)/%.o: $(SRC_DIR)/%.s
	$(ASM) $(ASM_FLAGS) -o $@ $<

$(KERNEL_OUT): $(OBJ_OUT)
	$(LD) $(LDFLAGS) -o $@ $^

$(GRUBCFG_OUT): $(GRUBCFG_SRC)
	$(shell cp $< $@)

iso: $(BOOTABLE_OUT)

simulate: $(BOOTABLE_OUT)
	$(shell qemu-system-x86_64 -cdrom $(BOOTABLE_OUT))

burn: $(BOOTABLE_OUT)
	$(shell dvd+rw-format -blank=fast /dev/sr0)
	$(shell growisofs -dvd-compat -Z /dev/sr0=$(BOOTABLE_OUT))

clean:
	$(foreach a_file, $(OBJ_OUT) $(KERNEL_OUT) $(BOOTABLE_OUT), \
		$(shell if [ -f $(a_file) ] ; then rm $(a_file) ; fi) \
	)
	$(foreach a_dir, $(OUT_ISO), \
		$(shell if [ -d $(a_dir) ] ; then rm -rf $(a_dir) ; fi) \
	)
