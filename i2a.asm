.text
.align 8
.global _main

_main:
    stp     fp, lr, [sp, #-16]!     ; preserve
    stp     x27, x28, [sp, #-16]!   ; preserve
    stp     x25, x26, [sp, #-16]!   ; preserve
    stp     x23, x24, [sp, #-16]!   ; preserve
    stp     x21, x22, [sp, #-16]!   ; preserve
    stp     x19, x20, [sp, #-16]!   ; preserve
    add     fp, sp, #96             ; define stack frame

    adrp    x19, s_bitcount@page    ; set x19 to string pointed to by s_bitcount
    ldr     x0, =value              ; load the number
    bl      bitCount                ; count set bits in number
    cmp     x0, #1                  ; only one bit set?
    b.eq    only_one                ; yessir
    mov     x20, x0                 ; save count for later

    mov     x1, x19                 ; copy string address
    mov     x2, #10                 ; set x2 to the length of the current string
    bl      print                   ; print the string to the screen

    mov     x0, x20                 ; retrive bit count
    bl      printUInt

    add     x1, x19, #9             ; point to next string section
    mov     x2, #13                 ; set x2 to the length of the string
    bl      print                   ; print the string to the screen

    ldr     x0, =value              ; load the sample
    bl      printUInt               ; print number

    add     x1, x19, #22            ; point to next string section
    mov     x2, #2                  ; set x2 to the length of the string
    bl      print                   ; print the string to the screen

end_program:
    ldp     x19, x20, [sp], #16     ; restore
    ldp     x21, x22, [sp], #16     ; restore
    ldp     x23, x24, [sp], #16     ; restore
    ldp     x25, x26, [sp], #16     ; restore
    ldp     x27, x28, [sp], #16     ; restore
    ldp     fp, lr, [sp], #16       ; restore

    mov X0, xzr                     ; set the exit code to 0
    mov x16,#1                      ; return control to supervisor
    svc #0xffff                     ; call supervisor

only_one:
    add     x1, x19, #24            ; point to next string section
    mov     x2, #29                 ; size
    bl      print
    b       end_program

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Will count the number of set bits in X0
;Result X0 will contain the number of set bits after calling this routine
.align 8
bitCount:
    stp     fp, lr, [sp, #-16]!     ; preserve
    stp     x27, x28, [sp, #-16]!   ; preserve
    stp     x25, x26, [sp, #-16]!   ; preserve
    stp     x23, x24, [sp, #-16]!   ; preserve
    stp     x21, x22, [sp, #-16]!   ; preserve
    stp     x19, x20, [sp, #-16]!   ; preserve
    add     fp, sp, #96             ; define stack frame

    mov     x19, x0                 ; move bits to be counted to x19
    mov     x0, xzr                 ; x0 is used to count the set bits, initialize it to 0

bitCount_loop:
    cmp     x19, xzr                ; if x19 is 0 then there's no more set bits and we should return
    beq     bitCount_Exit           ; break when there's no more set bits
    add     x0, x0, #1              ; increment the bit counter, everytimne we hit the loop a bit is set
    sub     x20, x19, #1            ; n &= n-1 this is the Kernighan algorithm, to count bits efficiently
    and     x19, x19, x20           ; (where x0 = n and x1 = n-1)
    b.ne    bitCount_loop           ; x19 is not 0 yet, so there are still be set bits in the value x19

bitCount_Exit:
    ldp     x19, x20, [sp], #16     ; restore
    ldp     x21, x22, [sp], #16     ; restore
    ldp     x23, x24, [sp], #16     ; restore
    ldp     x25, x26, [sp], #16     ; restore
    ldp     x27, x28, [sp], #16     ; restore
    ldp     fp, lr, [sp], #16       ; restore
    ret                             ; return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Print value in x0 as an unisgned int to STDOUT
;; x19 radix
;; x20 digit string index
;; x21 work register, starts with subject for printing
;; x22 work register, quotient
;; x23 remainder
;; 
printUInt:
    stp     fp, lr, [sp, #-16]!     ; preserve
    stp     x27, x28, [sp, #-16]!   ; preserve
    stp     x25, x26, [sp, #-16]!   ; preserve
    stp     x23, x24, [sp, #-16]!   ; preserve
    stp     x21, x22, [sp, #-16]!   ; preserve
    stp     x19, x20, [sp, #-16]!   ; preserve
    sub     sp, sp, #128            ; move stack pointer down 128 bytes, space for digit string
    add     fp, sp, #224            ; define frame

    mov     x19, #10                ; x19 will contain the divisor (10) used in udiv and msub
    mov     x20, xzr                ; x20 counts the number of digits stored on stack
    mov     x21, x0                 ; move input parameter to work register
    mov     x24, sp                 ; copy stack pointer for writing string

    cmp     x0, xzr                ; if x21 is zero then the division algorith will not work
    b.eq    printUInt_Zero          ; we set the value on the stack to 0

printUInt_Count:
    add     x20, x20, #1            ; increment the digit counter/index (x20)
    udiv    x22, x21, x19           ; divide x21 by 10, x22 gets quotient
    msub    x23, x22, x19, x21      ; obtain the remainder (x23) and the Quotient (x22)
    add     w23, w23, #48           ; add 48 to the number, turning it into an ASCII char 0-9
    strb    w23, [x24, x20]         ; build string on the stack one byte at a time
    cmp     x22, xzr                ; done?
    b.eq    printUInt_print         ; yessir
    mov     x21, x22                ; copy the Quotient (x22) into x21 which is the new value to divide by 10
    b       printUInt_Count         ; if x21 is not yet zero than there's more digits to extract

;; Using the stack guarantees that the digits are printed start with the most significant digit
printUInt_print:
    add     x20, x20, #1            ; increment the digit counter/index (x20)
    add     x1, sp, x20             ; sp + string length
printUInt_print_loop:
    cmp     x20, #1                 ; done?
    b.eq    printUInt_exit          ; all done
    sub     x20, x20, #1            ; decrement index
    add     x1, sp, x20             ; digit index + sp = address
    mov     x2, #1                  ; string length
    bl      print                   ; digit to STDOUT
    b       printUInt_print_loop    ; once more to the breach

printUInt_exit:
    add     sp, sp, #128            ; return string work area
    ldp     x19, x20, [sp], #16     ; restore
    ldp     x21, x22, [sp], #16     ; restore
    ldp     x23, x24, [sp], #16     ; restore
    ldp     x25, x26, [sp], #16     ; restore
    ldp     x27, x28, [sp], #16     ; restore
    ldp     fp, lr, [sp], #16       ; restore
    ret                             ; return

printUInt_Zero:                     ; this is the exceptional case when x21 is 0 then we need to push this ourselves to the stack
    mov     w21, #0x030             ; move "0" to w21
    add     x20, x20, #1            ; increment the digit counter/index (x20)
    strb    w21, [sp, x20]          ; push digit so that it can be printed to the screen
    b       printUInt_print
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Print the message addressed by X1 to STDOUT
;; X1 is string ptr
;; X2 is string length
print:                              ; print procedure
    ; stp     fp, lr, [sp, #-16]!     ; preserve
    ; stp     x27, x28, [sp, #-16]!   ; preserve
    ; stp     x25, x26, [sp, #-16]!   ; preserve
    ; stp     x23, x24, [sp, #-16]!   ; preserve
    ; stp     x21, x22, [sp, #-16]!   ; preserve
    ; stp     x19, x20, [sp, #-16]!   ; preserve
    ; add     fp, sp, #96             ; define frame

    mov     x0, #1                  ; write to STDOUT
    mov     x16, #4                 ; system code for write
    svc     #0xffff                 ; supervisor call

    ; ldp     x19, x20, [sp], #16     ; restore
    ; ldp     x21, x22, [sp], #16     ; restore
    ; ldp     x23, x24, [sp], #16     ; restore
    ; ldp     x25, x26, [sp], #16     ; restore
    ; ldp     x27, x28, [sp], #16     ; restore
    ; ldp     fp, lr, [sp], #16       ; restore
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.data
.align 8

s_bitcount:     .ascii  "There are bits set in .\nThere is one bit set in one.\n"

value = 0x8000
