.export esp_client_init, esp_client_poll, esp_client_start_wifi
.export buffer

.import serial_open, serial_read

esp_client_init:
            lda #$00
            sta state
            sta index
            jmp serial_open

esp_client_start_wifi:
            lda #<start_wifi
            sta $fb
            lda #>start_wifi
            sta $fc
            jmp send_command

send_command:
            ldy #$00
:           lda ($fb),y
            iny
            jsr $ffd2
            cmp #$0a
            bne :-
            rts

;-------------------------------------------------------------------------------

READ_STATUS = 0
READ_DATA = 1
READ_ERROR = 2

RESULT_CONTINUE = 0
RESULT_DATA = 1
RESULT_ERROR = 2

; Y: 0 - continue
;    1 - error in buffer
;    2 - data in buffer
; X: data length (if Y != 0)
esp_client_poll:
            jsr serial_read
            cpx #$00
            bne handle_incoming
            ldy #RESULT_CONTINUE
            rts

handle_incoming:
            ldx index
            ldy state
            beq read_status_line
            cpy #READ_ERROR
            beq read_error_line
            ; TODO: read_data
exit_cont:
            ldy #$00
            rts

read_status_line:
            ldy #RESULT_CONTINUE
            cmp #$0d
            beq exit_cont   ; ignore `\r`
            cmp #$0a
            bne store_char
            inc state       ; optimistically assume OK - READ_DATA
            jsr status_OK
            beq reset_index
            inc state       ; READ_ERROR
            jmp reset_index

read_error_line:
            ldy #RESULT_CONTINUE
            cmp #$0d
            beq exit_cont
            cmp #$0a
            bne store_char
            ldy #RESULT_ERROR
            jmp reset_index

reset_index:
            lda #$00
            sta index
            rts

store_char:
            sta buffer, x
            inc index
            rts

; A: 0 - if status in buffer 'OK'
status_OK:
            lda buffer + 1  ; 'K'
            cmp #$4B
            bne :+
            lda buffer
            cmp #$4F        ; 'O'
            beq :+
            lda buffer
            cmp #$9F        ; 'O' - compensate for a bug where first byte comes corrupt for unknown reason
:           rts

index:      .byte 0
state:      .byte READ_STATUS
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