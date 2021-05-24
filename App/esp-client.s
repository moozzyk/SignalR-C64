.export esp_client_init, esp_client_poll, esp_client_start_wifi, esp_client_start_ws, esp_client_ws_send
.export data_buff

.import serial_open, serial_read

.include "esp-client-const.inc"

COMMAND_START_WIFI = 3
COMMAND_STOP_WIFI = 4
COMMAND_START_WEBSOCKET = 5
COMMAND_WEBSOCKET_SEND = 6

.macro reset_index
            lda #$00
            sta index
            lda #$ff
            sta remaining
.endmacro

esp_client_init:
            reset_index
            jsr serial_open
            ; workaround to a bug
            lda #$02
            sta garbage
            lda #COMMAND_STOP_WIFI
            jsr $ffd2
            lda #$00
            jsr $ffd2
            rts

esp_client_start_wifi:
            lda #COMMAND_START_WIFI
            jsr $ffd2
            lda #$00        ; arg length
            jsr $ffd2
            rts

esp_client_start_ws:
            lda #COMMAND_START_WEBSOCKET
            jmp send

esp_client_ws_send:
            lda #COMMAND_WEBSOCKET_SEND
            jmp send

; A - command
; X - arg length
send:
            jsr $ffd2
            txa
            jsr $ffd2
            ldy #$00
:           lda ($fb),y
            jsr $ffd2
            iny
            dex
            bne :-
            rts

;-------------------------------------------------------------------------------

; Y: 0 - continue
;    1 - DATA, data in recv_buff
;    2 - ERROR, description in recv_buff
;    3 - OK, no additional details in recv_buff
;    4 - WS, description in recv_buff
;
; X: data length (if Y != 0)
esp_client_poll:
            jsr serial_read
            cpx #$00
            bne handle_incoming
            ldy #RESULT_CONTINUE
            rts

handle_incoming:
            ;---- DEBUG - remove
            pha
            jsr to_screen_code
            ldx dbg_index
            sta $608,x
            inc dbg_index
            pla
            ;-----
            ldx garbage
            beq no_garbage
            dec garbage
            ldy #RESULT_CONTINUE
            rts

no_garbage:
            ldx index
            sta recv_buff,x
            inc index
            cpx #$01
            bne not_length
            inc remaining
not_length: dec remaining
            beq read_result
            ldy #RESULT_CONTINUE
            rts

read_result:
            reset_index
            dex
            ldy recv_buff
            rts

;--- DEBUG - remove (does not work well anyways)
to_screen_code:
    cmp #0
    beq exitconv
    cmp #32         ;' ' character
    beq exitconv
    cmp #33         ;! character
    beq exitconv
    cmp #42         ;* character
    beq exitconv
    cmp #48         ;numbers 0-9
    bcs numconv
conv:
    sec
    sbc #$40
    jmp exitconv
numconv:
    cmp #58
    bcc exitconv
    jmp conv
exitconv:
    rts
dbg_index:  .byte 0
;-----

garbage:    .byte 2 ; workaround for a bug
index:      .byte 0
recv_buff:  .byte 0 ; also a command id
remaining:  .byte 0
data_buff:  .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0



