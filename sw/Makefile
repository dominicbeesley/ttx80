include		Makefile.defs

SSD_DIRS=test-boot rom
HOSTFS=~/hostfs

all::
	$(foreach a,$(SSD_DIRS), $(MAKE) -C $(a) all;)
	dfs form -80 $(BUILD)/ttx80.ssd
	dfs title $(BUILD)/ttx80.ssd "TTX80" 
	dfs opt4 -3 $(BUILD)/ttx80.ssd
	$(foreach inf, \
		$(shell find $(addsuffix /ssd_inc/, $(SSD_DIRS)) -type f -iname "*.inf") \
		$(shell find $(addsuffix /, $(addprefix BUILD/, $(SSD_DIRS))) -type f -iname "*.inf"), \
		dfs add $(BUILD)/ttx80.ssd $(inf); \
	)


hostfs:: all
	mkdir -p $(HOSTFS)/ttx80
	dfs read -i -d $(HOSTFS)/ttx80 $(BUILD)/ttx80.ssd

clean::
	$(foreach a,$(SSD_DIRS), $(MAKE) -C $(a) clean;)
	rm	$(BUILD)/ttx80.ssd