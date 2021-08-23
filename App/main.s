.import signalr_init, signalr_run
.import data_buff
.import ui_draw_chat_window, print_message

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
fixstr:     sbc #$a0
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
            bpl next
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