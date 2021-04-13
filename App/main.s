.import signalr_init, signalr_run

main:
            sei
            lda #<irq
            sta $314
            lda #>irq
            sta $315
            lda #$01
            sta $d01a
            lda #$7f
            sta $dc0d
            lda #$44
            sta $d012
            lda #$1b
            sta $d011
            cli
            jsr signalr_init
            ldx #$00
:           lda t1,x
            sta $500,x
            lda t2,x
            sta $600,x
            inx
            cpx #$0a
            bne :-
            jmp *
irq:
            inc $d021
            jsr signalr_run
            dec $d021
            lda #$01
            sta $d019
            jmp $ea31

.macro  pure_ascii arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

        ; Bail out if next argument is empty
        .if     .blank ({arg1})
                .exitmacro
        .endif

        ; Check for a string
        .if     .match ({arg1}, "")

                ; Walk over all string chars
                .repeat .strlen (arg1), i
                        .byte .strat (arg1, i)
                .endrepeat

        ; Check for a number
        .elseif .match (.left (1, {arg1}), 0)

                ; Just output the number
                .byte        arg1

        ; Check for a character
        .elseif .match (.left (1, {arg1}), 'a')

                ; Just output the character
                .byte        arg1

        ; Anything else is an error
        .else
                .error  "scrcode: invalid argument type"
        .endif

        ; Call the macro recursively with the remaining args
        pure_ascii arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
.endmacro

t1: pure_ascii "AaB123!@#A"
t2: .byte "AaB123!@#A"
