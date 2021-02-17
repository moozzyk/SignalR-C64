.export esp_client_init, esp_client_poll, esp_client_start_wifi

.import serial_open, serial_read

esp_client_init:
            jsr serial_open
            rts

esp_client_poll:
            jsr serial_read
            cpx #$00
            beq :+
            jsr handle_incoming
:           rts

esp_client_start_wifi:
            lda #<start_wifi
            sta $fb
            lda #>start_wifi
            sta $fc
            jsr send_command
            rts

send_command:
            ldy #$00
:           lda ($fb),y
            iny
            jsr $ffd2
            cmp #$0a
            bne :-
            rts

read_status = 0
read_error = 1
read_data = 2
handle_incoming:
            ldy state
            beq read_status_line
            cpy #read_error
            beq read_error_line
; read_data

            rts

read_status_line:
            cmp #$0d    ; `\r` ?
            ldx index
            pha
            lsr
            lsr
            lsr
            lsr
            tay
            lda digits, y
            sta $400,x
            inx
            pla
            and #$0f
            tay
            lda digits, y
            sta $400,x
            inx
            inx
            stx index
            rts

digits:     .byte $30, $31, $32, $33, $34, $35, $36, $37
            .byte $38, $39, $01, $02, $03, $04, $05, $06

read_error_line:
;            rts
;            bne
;            jsr
            cmp #$0a
            cmp #$0d
            ldy index
            sbc #$40
            sta $400,y
            inc index
            rts
index:      .byte 0
state:      .byte read_status
buffer:     .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0



start_wifi: .byte "echo", $0a
; start_wifi: .byte "wifion", $0a