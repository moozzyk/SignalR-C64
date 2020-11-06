.import serial_open, serial_read

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
            jsr serial_open
            lda #'?'
            jsr $ffd2
            lda #$0a
            jsr $ffd2
            jmp *
irq:
            inc $d021
            jsr serial_read
            cpx #$0
            beq continue
            ldy index
            sta $400,y
            inc index
continue:
            dec $d021
            lda #$01
            sta $d019
            jmp $ea31

index:      .byte 0