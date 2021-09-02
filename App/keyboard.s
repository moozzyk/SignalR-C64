.export keyboard_open, keyboard_read

file_id     = $07 ; file #
device_id   = $00 ; keyboard

keyboard_open:
            lda #file_id
            ldx #device_id
            ldy #$00        ; secondary number
            jsr $ffba       ; SETLFS
            jsr $ffc0       ; OPEN
            rts

keyboard_read:
            ldx #file_id
            jsr $ffc6       ; CHKIN
            ldx #$01
            jsr $ffe4
            rts