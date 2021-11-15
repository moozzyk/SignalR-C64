.export ui_init_chat_window, print_message
.export toggle_cursor, handle_key_press, clear_message
.export message_start_pos

BACKGROUND_COLOR=0
BORDER_COLOR = 0
TEXT_COLOR = 7
NAME_COLOR = 1

ui_init_chat_window:
            jsr set_colors
            jsr clear_screen
            lda $d018       ; set upper/lower case mode
            ora #$06
            sta $d018

            lda #$00        ; init incoming messages cursor
            sta target_pos + 1
            lda #$04
            sta target_pos + 2

            lda #$00
            sta target_color + 1
            lda #$d8
            sta target_color + 2

            lda #$40        ; draw separator
            ldx #$28
:           sta $76f,x
            dex
            bne :-

            lda #$00
            sta cursor_pos
            lda #$20
            sta blink
            rts

set_colors:
            lda #BACKGROUND_COLOR
            sta $d020
            lda #BORDER_COLOR
            sta $d021
            rts

clear_screen:
            ldx #$00
:           lda #$20
            sta $400,x
            sta $500,x
            sta $600,x
            sta $700,x
            lda #TEXT_COLOR
            sta $d800,x
            sta $d900,x
            sta $da00,x
            sta $db00,x
            inx
            bne :-
            rts

print_message:
            jsr scroll_if_needed
            lda #NAME_COLOR
            sta font_color + 1
            ldy #$00
            ldx #$00
next:       lda ($fd),y
            cmp #$ff
            beq end
            cmp #':'
            bne target_pos
            pha
            lda #TEXT_COLOR
            sta font_color + 1
            pla
target_pos: sta $400,x
font_color: lda #$00
target_color:
            sta $d800,x
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
max_col_pos = $db48

next_line:
            clc
            lda target_pos + 1
            adc #$28
            sta target_pos + 1
            lda target_pos + 2
            adc #$00
            sta target_pos + 2

            clc
            lda target_color + 1
            adc #$28
            sta target_color + 1
            lda target_color + 2
            adc #$00
            sta target_color + 2
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
            lda #<max_col_pos
            sta target_color + 1
            lda #>max_col_pos
            sta target_color + 2
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

cursor_pos: .byte 0
blink:      .byte $20
timer:      .byte 0

message_start_pos = $0798

toggle_cursor:
            dec timer
            bne :+
            lda #$14
            sta timer
            lda blink
            eor #$80
            sta blink
            ldy cursor_pos
            sta message_start_pos,y
:           rts

handle_key_press:
            beq exit
            ldy cursor_pos
            cmp #$0d
            beq exit
            cmp #$14
            beq handle_delete
            cmp #$20            ; skip control chars
            bcc exit
            cpy #$4f
            bcs exit
            pha
            jsr petscii_to_screen_code
            sta message_start_pos,y
            inc cursor_pos
            pla
exit:       rts

handle_delete:
            ldy cursor_pos
            beq :+
            dec cursor_pos
            pha
            lda #$20
            sta message_start_pos,y
            dey
            lda blink
            sta message_start_pos,y
            pla
:           rts

petscii_to_screen_code:     ; https://sta.c64.org/cbm64pettoscr.html
            cmp #$40
            bcc @exit

            cmp #$60
            bcs :+
            sec
            sbc #$40
            jmp @exit

:           cmp #$80
            bcs :+
            sec
            sbc #$20
            jmp @exit

:           cmp #$a0
            bcs :+
            clc
            adc #$40
            jmp @exit

:           cmp #$c0
            bcs :+
            sec
            sbc #$40
            jmp @exit

:           cmp #$ff
            bcs :+
            sec
            sbc #$80
            jmp @exit

:           lda #$5e

@exit:      rts

clear_message:
            lda #$20
            ldy #$00
            stx cursor_pos
:           sta message_start_pos,y
            iny
            cpy #$50
            bne :-
            rts
