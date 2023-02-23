AS=ca65 -I ../includes
LD=ld65
INCS=$(wildcard ../../includes/*.inc) $(filter-out version-date.inc, $(wildcard *.inc))
DEPS=$(INCS) 

NAME=ttx80
OBJS_L=	$(NAME)_romheader $(NAME) $(NAME)_utils $(NAME)_vdu
ROMNO=0

include	../Makefile.defs

OBJS = $(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS_L)))

.PHONY: all clean

all::	$(BUILD)/$(NAME).rom

.PRECIOUS: $(ALLOBJS)

$(BUILD)/%.o: 	%.asm $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<


$(BUILD)/%.rom: $(OBJS) $(NAME).cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(NAME).cfg $(OBJS) $(LIBS)
	echo "$.$(NAME) FF8000 FF8000" >$@.inf
	da65 -S 0x8000 -v --comments 4 -o $@.da.asm $@
	../scripts/getsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).noi
	../scripts/bemsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).bem

	echo "R.$(basename $(notdir $@)) FFFF8000 FFFF8000" >$@.inf

ttx80.asm:testcard.mo15


clean::
	-rm $(BUILD)/*
