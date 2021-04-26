.import signalr_init, signalr_run

main:
            sei
            lda #<irq
            sta $314
            lda #>irq
            sta $315
            lda #$01
            sta $d01a
            lda #$7f
            sta $dc0d
            lda #$44
            sta $d012
            lda #$1b
            sta $d011
            cli
            jsr signalr_init
            jmp *
irq:
            inc $d021
            jsr signalr_run
            dec $d021
            lda #$01
            sta $d019
            jmp $ea31
