COMPONENT=GroupProjectAppC
CFLAGS+=-DDATARATE=1 -DMSG_POOL_SIZE=160 -DSINK_ADDRESS=1
# CFLAGS += -DTOSH_DATA_LENGTH=56               
# DCC2420_DEF_RFPOWER    According to the CC2420 data sheet, the chip has 8 discrete power levels: 0, -1, -3,  -5, -7, -10, -15, -25 dBm; the corresponding values of DCC2420_DEF_RFPOWER are 31, 27, 23, 19, 15, 11, 7, 3. 
CFLAGS += -I$(TOSDIR)/lib/printf -DNEW_PRINTF_SEMANTICS -Ddebug_printf -DCC2420_DEF_RFPOWER=31
BUILD_DEPS+=flocklab_embedded_image
SENSORBOARD=flocklab
PFLAGS+=-board=$(SENSORBOARD) -I$(TOSDIR)/sensorboards/$(SENSORBOARD)
include $(MAKERULES)

flocklab_embedded_image: exe
	@sed -i -n '1h;1!H;$${ g;s/<data>.*<\/data>/<data>#'"`base64 $(MAIN_EXE) | tr '\n' '#' | sed 's/\//\\\\\//g'`"'<\/data>/;s/#/\n/g;p}' flocklab.xml