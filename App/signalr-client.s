.export signalr_init, signalr_run
.import esp_client_init, esp_client_poll, esp_client_start_wifi, esp_client_start_ws, esp_client_ws_send, data_buff
.import host, handshake

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
            cpy #RESULT_DATA
            beq on_data
            cpy #RESULT_OK
            beq ok_call
            cpy #RESULT_WS
            bne on_error        ; unexpected state
            lda data_buff
            cmp #$43            ; 'C' for 'Connected'
            beq ok_call
            jmp on_error
ok_call:    jsr $0000
exit:       rts

on_error:
            inc $400            ; DEBUG LOL
            lda #ERROR
            sta state
            rts

on_wifi_started:
            lda #<on_ws_connected
            sta ok_call + 1
            lda #>on_ws_connected
            sta ok_call + 2
            lda #<host
            sta $fb
            lda #>host
            sta $fc
            ldx #29    ; host arg length
            jmp esp_client_start_ws

on_ws_connected:
            lda #<handle_handshake
            sta ok_call + 1
            lda #>handle_handshake
            sta ok_call + 2
            lda #<handshake
            sta $fb
            lda #>handshake
            sta $fc
            ldx #39    ; payload length
            jmp esp_client_ws_send
            rts

handle_handshake:
            inc $400
            rts

on_data:
            inc $401
            rts

state:      .byte 0
