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
; args
; Y: 0 - non-draining
; Y: 1 - draining

; return values:
; Y: 0 - continue
;    1 - DATA, data in recv_buff
;    2 - ERROR, description in recv_buff
;    3 - OK, no additional details in recv_buff
;    4 - WS, description in recv_buff
;
; X: data length (if Y != 0)
esp_client_poll:
            sty draining
            jsr serial_read
            ldy draining
            beq :+      ; are we draining?
            rts
:           cpx #$00
            bne handle_incoming
            ldy #RESULT_CONTINUE
            rts

handle_incoming:
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

draining:   .byte 0
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



