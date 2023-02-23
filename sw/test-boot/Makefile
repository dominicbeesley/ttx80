include		../Makefile.defs

all::$(BUILD)/MO78.bbc $(BUILD)/MO78.bbc.inf


$(BUILD)/%.bbc $(BUILD)/%.bbc.inf:%.bas
	basictool -2 -r -t $< $@
	echo B.MO78 FFFF1900 FFFF8023 > $@.inf


clean::
	-rm -f $(BUILD)/*.bbc
	-rm -f $(BUILD)/*.bbc.inf
