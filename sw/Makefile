include		Makefile.defs

SSD_DIRS=test-boot
HOSTFS=~/hostfs

all::
	$(foreach a,$(SSD_DIRS), $(MAKE) -C $(a) all;)
	dfs form -80 $(BUILD)/ttx80.ssd
	dfs title $(BUILD)/ttx80.ssd "TTX80" 
	dfs opt4 -3 $(BUILD)/ttx80.ssd
	dfs add $(BUILD)/ttx80.ssd $(shell find $(addsuffix /ssd_inc/, $(SSD_DIRS)) -type f -iname "*.inf")
	dfs add $(BUILD)/ttx80.ssd $(shell find $(addprefix BUILD/, $(SSD_DIRS)) -type f -iname "*.inf")

hostfs:: all
	mkdir -p $(HOSTFS)/ttx80
	dfs read -i -d $(HOSTFS)/ttx80 $(BUILD)/ttx80.ssd