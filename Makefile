COMPONENT=GroupProjectAppC
CFLAGS+=-DDATARATE=10 -DMSG_POOL_SIZE=120 -DSINK_ADDRESS=1
CFLAGS += -DTOSH_DATA_LENGTH=8
CFLAGS += -I$(TOSDIR)/lib/printf -DNEW_PRINTF_SEMANTICS -Ddebug_printf
BUILD_DEPS+=flocklab_embedded_image
SENSORBOARD=flocklab
PFLAGS+=-board=$(SENSORBOARD) -I$(TOSDIR)/sensorboards/$(SENSORBOARD)
include $(MAKERULES)

flocklab_embedded_image: exe
	@sed -i -n '1h;1!H;$${ g;s/<data>.*<\/data>/<data>#'"`base64 $(MAIN_EXE) | tr '\n' '#' | sed 's/\//\\\\\//g'`"'<\/data>/;s/#/\n/g;p}' flocklab.xml