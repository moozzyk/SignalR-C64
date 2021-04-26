.export signalr_init, signalr_run
.import esp_client_init, esp_client_poll, esp_client_start_wifi, esp_client_start_ws, recv_buff
.import host

.include "esp-client-const.inc"

DISCONNECTED = 0
CONNECTING = 1
CONNECTED = 2
ERROR = 9

signalr_init:
            lda #DISCONNECTED
            sta state
            jsr esp_client_init
            lda #<on_wifi_started
            sta ok_call + 1
            lda #>on_wifi_started
            sta ok_call + 2
            jsr esp_client_start_wifi
            rts

signalr_run:
            lda state
            cmp #ERROR
            beq exit
            jsr esp_client_poll
            cpy #RESULT_CONTINUE
            beq exit
            cpy #RESULT_ERROR
            beq on_error
            ; TODO handle RESULT_DATA
            cpy #RESULT_OK
            bne on_error
ok_call:    jsr $0000
exit:       rts

on_error:
            jsr print_buff
            lda #ERROR
            sta state
            rts

on_wifi_started:
            jsr print_buff
            lda #<on_ws_connected
            sta ok_call + 1
            lda #>on_ws_connected
            sta ok_call + 2
            lda #<host
            sta $fb
            lda #>host
            sta $fc
            jmp esp_client_start_ws

on_ws_connected:
            jsr print_buff

            rts

print_buff:
            ldy #$00
l:          lda recv_buff,y
            sbc #$40
            sta $400,y
            iny
            dex
            bne l
            rts

state:      .byte 0
