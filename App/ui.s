.export ui_draw_chat_window

ui_draw_chat_window:
            lda #$00
            sta $d020
            sta $d021
            lda #$20
            ldx #$00
:           sta $400,x
            sta $500,x
            sta $600,x
            sta $700,x
            inx
            bne :-

            lda #$40
            ldx #40
:           sta $76f,x
            dex
            bne :-

            rts

curr_line:  .byte 0