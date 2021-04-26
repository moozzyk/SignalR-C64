.export esp_client_init, esp_client_poll, esp_client_start_wifi, esp_client_start_ws
.export recv_buff

.import serial_open, serial_read
.import echo_off, start_wifi, start_ws

.include "esp-client-const.inc"

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
            jmp send

esp_client_start_ws:
            lda $fb
            pha
            lda $fc
            pha
            lda #<start_ws
            sta $fb
            lda #>start_ws
            sta $fc
            jsr send
            pla
            sta $fc
            pla
            sta $fb
            jmp send

send:
            ldy #$00
:           lda ($fb),y
            cmp #$00
            beq send_exit
            iny
            jsr $ffd2
            cmp #$0a
            bne :-
send_exit:  rts

;-------------------------------------------------------------------------------

; state
READ_STATUS = 0
READ_DATA = 1
READ_ERROR = 2
READ_WS = 3

; Y: 0 - continue
;    1 - DATA, data in recv_buff
;    2 - ERROR, description in recv_buff
;    3 - OK, no additional details in recv_buff
;    4 - WS, description in recv_buff
;
; X: data length (if Y != 0)
esp_client_poll:
            jsr serial_read
            cpx #$00
            bne handle_incoming
            ldy #RESULT_CONTINUE
            rts

handle_incoming:
            ldx index
            sta recv_buff,x
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
            cpy #READ_WS
            bne not_ws
            ldy #RESULT_WS
            jmp reset_status
not_ws:     ldy #RESULT_ERROR   ; not status, not ws - must be error
reset_status:
            lda #READ_STATUS
            sta state
            rts

parse_status:
            lda recv_buff + 1   ; check the second letter due to a weird bug
            cmp #$4B            ; 'K' (OK)
            beq status_OK
            cmp #$52            ; 'R' (ERROR)
            beq status_error
            cmp #$53            ; 'S' (WS)
            beq status_WS
            ldy #READ_DATA      ; assuming 'DATA'
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

status_WS:
            ldy #READ_WS
            sty state
            ldy #RESULT_CONTINUE
            rts

reset_index:
            lda #$00
            sta index
            rts

index:      .byte 0
state:      .byte READ_STATUS

recv_buff:  .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
