.import signalr_init, signalr_run
.import ui_draw_chat_window

.include "esp-client-const.inc"

main:
            jsr ui_draw_chat_window
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
            cpy #RESULT_DATA
            bne :+
            jsr handle_invocation
:           dec $d021
            lda #$01
            sta $d019
            jmp $ea31

handle_invocation:
            inc $d021
            rts