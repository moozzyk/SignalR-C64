.import signalr_init, signalr_run, signalr_send
.import data_buff
.import ui_init_chat_window, print_message, toggle_cursor, handle_key_press, clear_message
.import keyboard_open, keyboard_read
.import message_start_pos

.include "esp-client-const.inc"

main:
            jsr ui_init_chat_window
            jsr keyboard_open
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
            inc $d020
            jsr poll_signalr
            jsr poll_keyboard
            dec $d020
            lda #$01
            sta $d019
            jmp $ea31

poll_signalr:
            jsr signalr_run
            cpy #RESULT_DATA
            bne :+
            jsr handle_invocation
:           rts

handle_invocation:
            ; assume name and length is
            ; shorter than $fc
            lda #<message
            sta $fd
            lda #>message
            sta $fe
            jsr format_message
            jsr print_message
            rts

format_message:
            ldy #$00
            ldx #$00
            jsr read_param
            lda #':'
            sta ($fd),y
            iny
            lda #' '
            sta ($fd),y
            iny
            jsr read_param
            lda #$ff
            sta ($fd),y
            rts

args = data_buff + $11
read_param:
            lda args,x
            cmp #$d9
            bne fixstr
            inx
            lda args,x
            jmp read
fixstr:     sec
            sbc #$a0
            beq exit        ; empty string
read:       sta arg_len
            inx
next:       lda args,x
            cmp #$40
            bne :+
            sec
            sbc #$40
            jmp :++
:           cmp #$60
            bcc :+
            sec
            sbc #$60
:           sta ($fd),y
            iny
            inx
            dec arg_len
            bne next
exit:       rts
arg_len:    .byte 0

message:    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

poll_keyboard:
            jsr toggle_cursor
            jsr keyboard_read
            jsr handle_key_press
            cmp #$0d
            bne :+
            jsr send_message
            jsr clear_message
:           rts


send_message:
            jsr prepare_message
            tya
            tax
            lda #<message
            sta $fb
            lda #>message
            sta $fc
            jsr signalr_send
            rts

prepare_message:
            sty message         ; Y contains length, store temporarily
            ldx #$00
            ldy #$01
:           lda msg_header,x
            beq write_name
            sta message,y
            inx
            iny
            jmp :-
write_name:
            lda #$a3        ; hardcoded
            sta message,y
            iny
            lda #$41
            sta message,y
            iny
            lda #$42
            sta message,y
            iny
            lda #$43
            sta message,y
            iny

            lda #$d9
            sta message,y
            iny
            lda message     ; length
            sta message,y   ; assumes length less than 128
            iny
            ldx #$00
:           lda message_start_pos,x
            jsr to_ascii
            sta message,y
            iny
            inx
            cpx message
            bne :-
            lda #$90        ; 0x90 - 0-element array (StreamIds)
            sta message,y
            sty message     ; store payload length
            iny
            rts

to_ascii:
            cmp #$00
            bne :+
            clc
            adc #$40
            rts
:           cmp #$20
            bcs :+
            clc
            adc #$60
:           rts

msg_header:
            .byte $96,$01,$80,$a1,$c0,$a9,$42,$72,$6f,$61,$64,$63,$61,$73,$74,$92,$00