; RUN: llc -mtriple=x86_64-unknown-unknown -mattr=sse2 < %s | FileCheck %s

; PR22428: https://llvm.org/bugs/show_bug.cgi?id=22428
; f1, f2, f3, and f4 should use an integer logic instruction.
; f9 and f10 should use an FP (SSE) logic instruction.
;
; f5, f6, f7, and f8 are less clear.
;
; For f5 and f6, we can save a register move by using an FP logic instruction,
; but we may need to calculate the relative costs of an SSE op vs. int op vs. 
; scalar <-> SSE register moves.
;
; For f7 and f8, the SSE instructions don't take immediate operands, so if we
; use one of those, we either have to load a constant from memory or move the
; scalar immediate value from an integer register over to an SSE register.
; Optimizing for size may affect that decision. Also, note that there are no
; scalar versions of the FP logic ops, so if we want to fold a load into a
; logic op, we have to load or splat a 16-byte vector constant.

; 1 FP operand, 1 int operand, int result

define i32 @f1(float %x, i32 %y) {
; CHECK-LABEL: f1:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %eax
; CHECK-NEXT:    andl %edi, %eax
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %and = and i32 %bc1, %y
  ret i32 %and
}

; Swap operands of the logic op.

define i32 @f2(float %x, i32 %y) {
; CHECK-LABEL: f2:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %eax
; CHECK-NEXT:    andl %edi, %eax
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %and = and i32 %y, %bc1
  ret i32 %and
}

; 1 FP operand, 1 constant operand, int result

define i32 @f3(float %x) {
; CHECK-LABEL: f3:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %eax
; CHECK-NEXT:    andl $1, %eax
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %and = and i32 %bc1, 1
  ret i32 %and
}

; Swap operands of the logic op.

define i32 @f4(float %x) {
; CHECK-LABEL: f4:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %eax
; CHECK-NEXT:    andl $2, %eax
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %and = and i32 2, %bc1
  ret i32 %and
}

; 1 FP operand, 1 integer operand, FP result

define float @f5(float %x, i32 %y) {
; CHECK-LABEL: f5:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %eax
; CHECK-NEXT:    andl %edi, %eax
; CHECK-NEXT:    movd %eax, %xmm0
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %and = and i32 %bc1, %y
  %bc2 = bitcast i32 %and to float
  ret float %bc2
}

; Swap operands of the logic op.

define float @f6(float %x, i32 %y) {
; CHECK-LABEL: f6:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %eax
; CHECK-NEXT:    andl %edi, %eax
; CHECK-NEXT:    movd %eax, %xmm0
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %and = and i32 %y, %bc1
  %bc2 = bitcast i32 %and to float
  ret float %bc2
}

; 1 FP operand, 1 constant operand, FP result

define float @f7(float %x) {
; CHECK-LABEL: f7:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %eax
; CHECK-NEXT:    andl $3, %eax
; CHECK-NEXT:    movd %eax, %xmm0
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %and = and i32 %bc1, 3
  %bc2 = bitcast i32 %and to float
  ret float %bc2
}

; Swap operands of the logic op.

define float @f8(float %x) {
; CHECK-LABEL: f8:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %eax
; CHECK-NEXT:    andl $4, %eax
; CHECK-NEXT:    movd %eax, %xmm0
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %and = and i32 4, %bc1
  %bc2 = bitcast i32 %and to float
  ret float %bc2
}

; 2 FP operands, int result

define i32 @f9(float %x, float %y) {
; CHECK-LABEL: f9:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %ecx
; CHECK-NEXT:    movd %xmm1, %eax
; CHECK-NEXT:    andl %ecx, %eax
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %bc2 = bitcast float %y to i32
  %and = and i32 %bc1, %bc2
  ret i32 %and
}

; 2 FP operands, FP result

define float @f10(float %x, float %y) {
; CHECK-LABEL: f10:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %eax
; CHECK-NEXT:    movd %xmm1, %ecx
; CHECK-NEXT:    andl %eax, %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %bc2 = bitcast float %y to i32
  %and = and i32 %bc1, %bc2
  %bc3 = bitcast i32 %and to float
  ret float %bc3
}

define float @or(float %x, float %y) {
; CHECK-LABEL: or:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %eax
; CHECK-NEXT:    movd %xmm1, %ecx
; CHECK-NEXT:    orl %eax, %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %bc2 = bitcast float %y to i32
  %and = or i32 %bc1, %bc2
  %bc3 = bitcast i32 %and to float
  ret float %bc3
}

define float @xor(float %x, float %y) {
; CHECK-LABEL: xor:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %eax
; CHECK-NEXT:    movd %xmm1, %ecx
; CHECK-NEXT:    xorl %eax, %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    retq

  %bc1 = bitcast float %x to i32
  %bc2 = bitcast float %y to i32
  %and = xor i32 %bc1, %bc2
  %bc3 = bitcast i32 %and to float
  ret float %bc3
}

; Make sure that doubles work too.

define double @doubles(double %x, double %y) {
; CHECK-LABEL: doubles:
; CHECK:       # BB#0:
; CHECK-NEXT:    movd %xmm0, %rax
; CHECK-NEXT:    movd %xmm1, %rcx
; CHECK-NEXT:    andq %rax, %rcx
; CHECK-NEXT:    movd %rcx, %xmm0
; CHECK-NEXT:    retq

  %bc1 = bitcast double %x to i64
  %bc2 = bitcast double %y to i64
  %and = and i64 %bc1, %bc2
  %bc3 = bitcast i64 %and to double
  ret double %bc3
}

