.export client_init, client_run

.import serial_open, serial_read

client_init:
            jsr serial_open
            jsr send_command
            rts

client_run:
            jsr serial_read
            cpx #$00
            beq :+
            jsr handle_incoming
:           rts

handle_incoming:
            ldy index
            sbc #$40
            sta $400,y
            inc index
            rts
index:      .byte 0

send_command:
            ldx #$00
:           lda start_wifi, x
            inx
            jsr $ffd2
            cmp #$0a
            bne :-
            rts

start_wifi: .byte "wifion", $0a