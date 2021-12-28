SOURCES = main.s rs-232.s signalr-client.s esp-client.s ui.s keyboard.s
ASCIIRES = signalr-client-strings.s
PROGRAM = signalrdemo.prg

CA    = ca65
CC    = cl65
FLAGS = -t c64 -u __EXEHDR__ -C c64-asm.cfg -m $(PROGRAM).map -g -Ln $(PROGRAM).lbl

.PHONY: all clean
all: $(PROGRAM)

%.o: %.s
	$(CA) -t none $<

$(PROGRAM): $(SOURCES) $(ASCIIRES:.s=.o)
	$(CC) $(FLAGS) -o $@ $(SOURCES) $(ASCIIRES:.s=.o)

clean:
	$(RM) $(PROGRAM) $(PROGRAM).map $(PROGRAM).lbl $(SOURCES:.s=.o) $(ASCIIRES:.s=.o) $(PROGRAM).d64

d64:
	c1541 -format "azure demo,00" d64 $(PROGRAM).d64 -write $(PROGRAM) "signalr demo"