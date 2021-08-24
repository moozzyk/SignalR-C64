.export ui_init_chat_window, print_message

ui_init_chat_window:
            lda #$00
            sta $d020
            sta $d021
            lda $d018        ; set upper/lower case mode
            ora #$06
            sta $d018
            lda #$00
            sta target_pos + 1
            lda #$04
            sta target_pos + 2
            lda #$20
            ldx #$00
:           sta $400,x
            sta $500,x
            sta $600,x
            sta $700,x
            inx
            bne :-

            lda #$40
            ldx #$28
:           sta $76f,x
            dex
            bne :-
            rts

print_message:
            jsr scroll_if_needed
            ldy #$00
            ldx #$00
next:       lda ($fd),y
            cmp #$ff
            beq end
target_pos: sta $400,x
            inx
            cpx #$28
            bne :+
            jsr next_line
            jsr scroll_if_needed
            ldx #$00
:           iny
            bne next
end:        jsr next_line
            rts

max_pos = $0748

next_line:
            clc
            lda target_pos + 1
            adc #$28
            sta target_pos + 1
            lda target_pos + 2
            adc #$00
            sta target_pos + 2
            rts

scroll_if_needed:
            lda target_pos + 1
            cmp #<(max_pos + $28)
            bne :+
            lda target_pos + 2
            cmp #>(max_pos + $28)
            bne :+
            jsr scroll_up
            lda #<max_pos
            sta target_pos + 1
            lda #>max_pos
            sta target_pos + 2
:           rts

.macro lines_up addr
            .repeat 21, line
                lda addr + ((line + 1) * $28),x
                sta addr + (line * $28),x
            .endrepeat
.endmacro

scroll_up:
            ldx #$27
:           lines_up $400
            lines_up $d800
            dex
            bmi *+5
            jmp :-
            lda #$20
            ldx #$27
:           sta max_pos,x
            dex
            bpl :-
            rts