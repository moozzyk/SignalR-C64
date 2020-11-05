.import open_rs232, close_rs232, send_rs232, get_rs232

file_id = $02

            lda #file_id
            ldx #$02        ; device (2 - rs-232)
            ldy #$00        ; secondary number
            jsr $ffba       ; SETLFS
            lda #$01        ; size
            ldx #<bauds
            ldy #>bauds
            jsr $ffbd ; $fdf9       ; SETNAM
            lda #file_id
            jsr $ffc0       ; OPEN

            ldx #file_id
            jsr $ffc9       ; CHKOUT

            lda #'?'
            jsr $ffd2
            lda #$0a
            jsr $ffd2

            ldx #file_id
            jsr $ffc6

            ldy #$00
t:          jsr $ffe4       ; GETIN
            cmp #$00
            beq t
            sta $400,y
            iny
            jmp t

            rts

bauds:  .byte 8         ; 1200 baud