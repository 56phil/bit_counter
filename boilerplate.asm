    stp     fp, lr, [sp, #-16]!     ; preserve
    stp     x27, x28, [sp, #-16]!   ; preserve
    stp     x25, x26, [sp, #-16]!   ; preserve
    stp     x23, x24, [sp, #-16]!   ; preserve
    stp     x21, x22, [sp, #-16]!   ; preserve
    stp     x19, x20, [sp, #-16]!   ; preserve
    add     fp, sp, #96             ; define stack frame
 
    ldp     x19, x20, [sp], #16     ; restore
    ldp     x21, x22, [sp], #16     ; restore
    ldp     x23, x24, [sp], #16     ; restore
    ldp     x25, x26, [sp], #16     ; restore
    ldp     x27, x28, [sp], #16     ; restore
    ldp     fp, lr, [sp], #16       ; restore
    ret                             ; return
