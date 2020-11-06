.import client_init, client_run

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
            jsr client_init
            jmp *
irq:
            inc $d021
            jsr client_run
            dec $d021
            lda #$01
            sta $d019
            jmp $ea31

index:      .byte 0