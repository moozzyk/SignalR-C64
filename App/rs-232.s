.export open_rs232, close_rs232, get_rs232, send_rs232

bauds:  .byte 8         ; 1200 bauds

; A - file id, not preserved
open_rs232:
        pha             ; keep file id for later use
        ldx #$02        ; device (2 - rs-232)
        ldy #$00        ; secondary number
        jsr $ffba       ; SETLFS

        lda #$01        ; size
        ldx #<bauds
        ldy #>bauds
        jsr $fdf9       ; SETNAM

        pla             ; file id
        jsr $ffc0       ; OPEN
        rts

; A - file id, not preserved
close_rs232:
        jsr $fdf9
        rts

; A - file id, not preserved
send_rs232:
        pha
        ldx #$02
        jsr $ffc9       ; CHKOUT
        pla
        jsr $ffd2
        jsr $ffcc       ; CLRCHN
        rts

get_rs232:
        ldx #$02
        jsr $ffc6       ; CHKIN
        jsr $ffcf       ; CHRIN
        jsr $ffe4       ; GETIN
        tax
        jsr $ffcc       ; CLRCHN
        txa
        rts

; cmd .text "WIFION"

; CHCKOUT - prepares a logical device for output
; PRINT
; CLRCHN - resets input/output to default devices (keyboard/screen)
; $f7/$f8 points to the input buffer
; $f9/$fa points to the output buffer
