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

; state
READ_STATUS = 0
READ_DATA = 1
READ_ERROR = 2

RESULT_CONTINUE = 0
RESULT_DATA = 1
RESULT_ERROR = 2
RESULT_OK = 3

; Y: 0 - continue
;    1 - DATA, data in buffer
;    2 - ERROR, description in buffer
;    3 - OK, no additional details in buffer
; X: data length (if Y != 0)
esp_client_poll:
            jsr serial_read
            cpx #$00
            bne handle_incoming
            ldy #RESULT_CONTINUE
            rts

handle_incoming:
            ldx index
            sta buffer,x
            inc index
            ldy state
            cpy #READ_DATA
            beq read_data
            cmp #$0a
            beq read_line
            ldy #RESULT_CONTINUE
            rts

read_data:
            ; TODO: read_data
            rts

read_line:
            jsr reset_index
            cpy #READ_STATUS
            beq parse_status
            ldy #READ_STATUS
            sty state
            ldy #RESULT_ERROR   ; line and not status - must be an error
            rts

parse_status:
            lda buffer + 1      ; check the second letter due to a weird bug
            cmp #$4B            ; 'K'
            beq status_OK
            cmp #$52            ; 'R'
            beq status_error
            ldy #READ_DATA      ; status does not start with 'O' or 'E' - assuming 'DATA'
            sty state
            ldy #RESULT_DATA
            rts

status_OK:
            ldy #READ_STATUS
            sty state
            ldy #RESULT_OK
            rts

status_error:
            ldy #READ_ERROR
            sty state
            ldy #RESULT_CONTINUE
            rts

reset_index:
            lda #$00
            sta index
            rts

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



echo_off: .byte "echooff", $0a
start_wifi: .byte "wifion", $0a