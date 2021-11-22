.import signalr_init, signalr_run, signalr_send
.import data_buff
.import ui_init_name_prompt, ui_show_connecting, ui_init_chat_window, ui_animate_connecting
.import print_message, toggle_cursor, handle_key_press, clear_message
.import keyboard_open, keyboard_read

.include "esp-client-const.inc"

name_start_pos = $4fb
max_name_length = $10
message_start_pos = $0798
max_message_length = $4f

MODE_DISCONNECTED = 0
MODE_CONNECTING = 1
MODE_CONNECTED = 2

main:
            lda #<name_start_pos
            sta cursor_pos
            lda #>name_start_pos
            sta cursor_pos + 1
            lda #max_name_length
            sta max_input_length
            lda #MODE_DISCONNECTED
            sta mode

            jsr keyboard_open
            jsr ui_init_name_prompt
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
            jmp *
irq:
            lda mode
            beq read_keys   ; mode MODE_DISCONNECTED
            jsr poll_signalr
            cmp #$02        ; Client status: CONNECTED
            beq :+          ; if not assume: CONNECTING
            jsr ui_animate_connecting
            jmp exit
:           lda mode
            cmp #MODE_CONNECTING
            bne read_keys
            inc mode
            jsr ui_init_chat_window
read_keys:  jsr poll_keyboard
exit:       lda #$01
            sta $d019
            jmp $ea31

mode:       .byte $00 ; 0 - input name, 1 - chat

poll_signalr:
            jsr signalr_run
            pha
            cpy #RESULT_DATA
            bne :+
            jsr handle_invocation
:           pla
            rts

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
            bne read
            inx             ; empty string
            rts
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
            rts
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
            lda cursor_pos
            sta $fd
            lda cursor_pos + 1
            sta $fe
            jsr toggle_cursor
            jsr keyboard_read
            ldx max_input_length
            jsr handle_key_press
            cpy #$00
            beq :+          ; ignore empty
            cmp #$0d
            bne :+
            lda mode
            beq allow_connect
            jsr send_message
            jsr clear_message
:           rts

allow_connect:
            inc mode
            sty name_len        ; Y contains length
            cpy #$00            ; empty name?
            beq name_saved
:           dey
            bmi name_saved
            lda ($fd),y
            jsr to_ascii
            sta name,y
            jmp :-

name_saved: lda #<message_start_pos
            sta cursor_pos
            lda #>message_start_pos
            sta cursor_pos + 1
            lda #max_message_length
            sta max_input_length
            jsr signalr_init
            jsr ui_show_connecting
            rts

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
            clc
            lda name_len
            adc #$a0
            sta message,y
            iny
            lda name_len
            beq name_written
            ldx #$00
:           lda name,x
            sta message,y
            iny
            inx
            cpx name_len
            bne :-

name_written:
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

name_len:   .byte $00
name:       .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
cursor_pos:
            .byte $00, $00
max_input_length:
            .byte $00