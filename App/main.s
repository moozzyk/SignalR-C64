.import signalr_init, signalr_run
.import data_buff
.import ui_init_chat_window, print_message, toggle_cursor
.import keyboard_open, keyboard_read

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
            cmp #$60
            bmi :+
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
            beq :+
            sta $500
:           rts