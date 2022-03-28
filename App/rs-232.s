.export serial_open, serial_read

file_id     = $05 ; file #
device_id   = $02 ; rs-232

serial_open:
            lda #file_id
            ldx #device_id
            ldy #$00        ; secondary number
            jsr $ffba       ; SETLFS
            lda #$01        ; file name size
            ldx #<bauds     ; file name vector lo
            ldy #>bauds     ; file name vector high
            jsr $ffbd       ; SETNAM
            jsr $ffc0       ; OPEN

            ldx #file_id
            jsr $ffc9       ; CHKOUT
            rts

bauds:      .byte 8         ; 8 - 1200 bauds, 7 - 600 bauds
                            ; USE 600 bauds for real C-64

serial_read:
            ldx #file_id
            jsr $ffc6       ; CHKIN

            ldx #$00
            ldy $29c        ; ridbs
            cpy $29b        ; ridbe
            beq empty
            ldx #$01
            jsr $ffe4
empty:      rts
