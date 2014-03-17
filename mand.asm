; mand.asm - A Mandelbrot set generator
;
; The MIT License (MIT)
;
; Copyright (c) 2003, 2014 Mika Rantanen
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.


P286
.MODEL small
.STACK

.DATA
   Re     DD   -3.0      ; Left
   Im     DD   -1.5      ; Top
   D      DD    0.015

.CODE
   mov    ax,@DATA
   mov    ds,ax

   mov    ax,0A000h
   mov    es,ax
   xor    di,di

   mov    ax,13h         ; 320x200 pixels and 256 colors
   int    10h

   xor    ax,ax          ; Change the palette
   mov    dx,03c8h
   out    dx,al
   inc    dx
   xor    cx,cx
Pal1:                    ; Gray colors
   mov    al,cl
   shr    al,2
   out    dx,al
   out    dx,al
   out    dx,al
   inc    cx
   cmp    cx,192
   jnz    Pal1
   xor    cx,cx
Pal2:                    ; Blue colors
   mov    al,48
   mov    ah,cl
   shr    ah,1
   sub    al,ah
   out    dx,al
   out    dx,al
   mov    al,48
   shr    ah,1
   sub    al,ah
   out    dx,al
   inc    cx
   cmp    cx,64
   jnz    Pal2

   finit                 ; Initialize the floating-point unit
   fld1                  ; 1
   fadd   st,st          ; 2
   fadd   st,st          ; 4
   fld    D              ; D, 4
   fld    Im             ; Im, D, 4

   mov    cx,200         ; 200 rows
LoopY:
   push   cx
   fld    Re             ; Re, Im, D, 4

   mov    cx,320         ; 320 columns
LoopX:
   push   cx
   fld    st(1)          ; Im, Re, Im, D, 4
   fld    st(1)          ; Re, Im, Re, Im, D, 4

   mov    cx,255
Mandelbrot:
   fld    st(1)          ; Im, Re, Im, Re, Im, D, 4
   fmul   st(2),st       ; Im, Re, Im^2, Re, Im, D, 4
   fld    st(1)          ; Re, Im, Re, Im^2, Re, Im, D, 4
   fmul   st(2),st       ; Re, Im, Re^2, Im^2, Re, Im, D, 4

   fmulp  st(1)          ; Re*Im, Re^2, Im^2, Re, Im, D, 4
   fld    st             ; Re*Im, Re*Im, Re^2, Im^2, Re, Im, D, 4
   faddp  st(1)          ; 2(Re*Im), Re^2, Im^2, Re, Im, D, 4
   fadd   st,st(4)       ; 2(Re*Im)+Im, Re^2, Im^2, Re, Im, D, 4
   fxch   st(2)          ; Im^2, Re^2, 2(Re*Im)+Im, Re, Im, D, 4

   fld    st(1)          ; Re^2, Im^2, Re^2, 2(Re*Im)+Im, Re, Im, D, 4
   fsub   st,st(1)       ; Re^2-Im^2, Im^2, Re^2, 2(Re*Im)+Im, Re, Im, D, 4
   fadd   st,st(4)       ; Re^2-Im^2+Re, Im^2, Re^2, 2(Re*Im)+Im, Re, Im, D, 4
   fxch   st(2)          ; Re^2, Im^2, Re^2-Im^2+Re, 2(Re*Im)+Im, Re, Im, D, 4

   faddp  st(1)          ; Re^2+Im^2, Re^2-Im^2+Re, 2(Re*Im)+Im, Re, Im, D, 4
   fcomp  st(6)          ; Re^2-Im^2+Re, 2(Re*Im)+Im, Re, Im, D, 4
   fstsw  ax
   sahf
   jae    ExitMandelbrot
   dec    cx
   jnz    Mandelbrot

ExitMandelbrot:
   mov    es:[di],cl
   inc    di
   fcompp                ; Re, Im, D, 4
   fadd   st,st(2)       ; Re+D, Im, D, 4
   pop    cx
   dec    cx
   jnz    LoopX

   fstp   st             ; Im, D, 4
   fadd   st,st(1)       ; Im+D, D, 4
   pop    cx
   dec    cx
   jnz    LoopY

   mov    ah,1           ; Wait for a keypress
   int    21h
   mov    ax,03h
   int    10h
   mov    ah,04ch
   int    21h
END
