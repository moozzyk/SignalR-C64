.export signalr_init, signalr_run
.import esp_client_init, esp_client_poll, esp_client_start_wifi

signalr_init:
            jsr esp_client_init
            jsr esp_client_start_wifi
            rts

signalr_run:
            jsr esp_client_poll
            rts