SOURCES = main.s rs-232.s signalr-client.s esp-client.s
ASCIIRES = esp-client-strings.s
PROGRAM = app.prg

CA    = ca65
CC    = cl65
FLAGS = -t c64 -u __EXEHDR__ -C c64-asm.cfg -m $(PROGRAM).map -g -Ln $(PROGRAM).lbl

.PHONY: all clean
all: $(PROGRAM)

$(ASCIIRES:.s=.o): $(ASCIIRES)
	$(CA) -t none $(ASCIIRES)

$(PROGRAM): $(SOURCES) $(ASCIIRES:.s=.o)
	$(CC) $(FLAGS) -o $@ $(SOURCES) $(ASCIIRES:.s=.o)

clean:
	$(RM) $(PROGRAM) $(PROGRAM).map $(PROGRAM).lbl $(SOURCES:.s=.o) $(ASCIIRES:.s=.o)