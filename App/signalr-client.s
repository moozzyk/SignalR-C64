.export signalr_init, signalr_run
.import esp_client_init, esp_client_poll, esp_client_start_wifi, recv_buff

.include "esp-client-const.inc"

DISCONNECTED = 0
CONNECTING = 1
CONNECTED = 2

signalr_init:
            lda #DISCONNECTED
            sta state
            jsr esp_client_init
            jsr esp_client_start_wifi
            rts

signalr_run:
            jsr esp_client_poll
            cpy #RESULT_CONTINUE
            beq exit

            ldy #$00
l:          lda recv_buff,y
            sbc #$40
            sta $400,y
            iny
            dex
            bne l

exit:       rts

state:      .byte 0
