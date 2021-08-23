.export ui_draw_chat_window, print_message

ui_draw_chat_window:
            lda $d018        ; set upper/lower case mode
            ora #$06
            sta $d018
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

print_message:
            ldy #$00
:           lda ($fd),y
            cmp #$ff
            beq end
            sta $400,y
            iny
            bne :-
end:        rts

.macro lines_up addr
            .repeat 20, line
                lda addr + ((line + 1) * $28),x
                sta addr + (line * $28),x
            .endrepeat
.endmacro

scroll_up:
            ldx #$27
:           lines_up $400
            lines_up $d800
            dex
            beq *+5
            jmp :-
            rts


curr_line:  .byte 0