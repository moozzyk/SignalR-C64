SOURCES = main.s rs-232.s signalr-client.s esp-client.s
PROGRAM = app.prg

CC    = cl65
FLAGS = -t c64 -u __EXEHDR__ -C c64-asm.cfg -m $(PROGRAM).map -g -Ln $(PROGRAM).lbl

.PHONY: all clean assets
all: assets $(PROGRAM)

$(PROGRAM): $(SOURCES)
	$(CC) $(FLAGS) -o $@ $(SOURCES)

clean:
	$(RM) $(PROGRAM) $(PROGRAM).map $(PROGRAM).lbl