.export signalr_init, signalr_run
.import esp_client_init, esp_client_poll, esp_client_start_wifi, buffer

signalr_init:
            jsr esp_client_init
            jsr esp_client_start_wifi
            rts

signalr_run:
            jsr esp_client_poll
            cpy #$00            ; TODO: make result codes common
            beq exit

            ldy #$00
l:          lda buffer,y
            sbc #$40
            sta $400,y
            iny
            dex
            bne l

exit:       rts
