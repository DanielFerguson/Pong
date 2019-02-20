format binary as 'img' ; FASM will export ASM as IMG

; TODO NOTES
; - Setup Inputs for Buttons
; - Rework DrawPaddels to create both paddels
; - Rework DrawPadells to move
; - Movement Check for Paddels (Set Y Movement Limits)
; - Create arena outline
; - Document Register Usage in Notes Section
; // DOING // - Up movement for P1
; // COMPLETE // - Convert Framerate to 60 (Change WAIT)
; // COMPLETE // - Down movement for P1
; // COMPLETE // - Update 'dumb' timer to 'smart' timer

; ----- NOTES -----
; // Global //
; Pin 1: +3.3v
;
; // Frames Per Second (Wait) //
; For ~60FPS, we will need to wait 1666.6 microseconds
; Hex: $682
;
; // Outputs //
; Pin 12 / GPIO18: Player 1 DOWN
; Pin 33 / GPIO19: Player 1 UP
;
; // Inputs  //
; Pin 19 / GPIO10: Player 1 DOWN
; Pin 23 / GPIO11: Player 1 UP
; Pin 32 / GPIO12: Player 2 UP
; Pin 33 / GPIO13: Player 2 DOWN
;
; // Registers
; Register 4 (r4):
; Register 5 (r5):
; Register 6 (r6):

; ----- SETUP -----
BASE = $3F000000
org $0000
mov sp,$1000           ; Initialise Stack Pointer

; Set Raspberry Pi to be Single Core
mrc p15,0,r0,c0,c0,5  ; R0 = Multiprocessor Affinity Register (MPIDR)
ands r0,3             ; R0 = CPU ID (Bits 0..1)
bne CoreLoop          ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

; Setup Screen Output (using FBinit8)
mov r0,BASE
bl FB_Init

and r0,$3FFFFFFF      ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
str r0,[FB_POINTER]   ; Store Frame Buffer Pointer Physical Address

mov r7,r0             ; Back-up a copy of the screen address + channel number

; Raspberry Pi Setup
GPIO_OFFSET = $200000
mov r0,BASE
orr r0,GPIO_OFFSET    ; Gives base address for GPIOs

; Setup Inputs
ldr r1,[r0,#4] ;read function register for GPIO 10 - 19
bic r1,r1,#27  ;bit clear  27 = 9 * 3    = read access
str r1,[r0,#4] ;10 input

; Setup Outputs
  ; LED 1 (P1 DOWN)
ldr r10,[r0,#4]  ; LED 1 (GPIO18)
orr r10, $1000000  ;set bit 24
str r10,[r0,#4] ; GPIO18 output
  ; LED 2 (P1 UP)


;activate LED 1
mov r12,#1
lsl r12,#18  ;bit 18 to write to GPIO18

; ----- GAME SETUP -----
mov r4,#19              ; Starting X Ordinate
mov r5,#199             ; Starting Y Ordinate
mov r6,#255             ; Color for 8-bit (White)
mov r11,#80

bl InitialiseGame$

; ----- GAME LOOP -----
MainGame$:
  ; WAIT (0.5s)
  bl Wait

  ; INPUT CHECK / DRAW
  ldr r9,[r0,#52]       ; read gpios 0-31
  tst r9,#1024          ; use tst to check bit 10
    bne buttonDown      ; if == 0
  str r12,[r0,#28]
    b continue$         ; BUTTON NOT DOWN

  buttonDown:
    str r12,[r0,#40]    ; BUTTON DOWN
    bl DrawPaddle$
  continue$:

  ; WAIT (0.5s)
  bl Wait

  b MainGame$




; ----- LOOPS -----
Loop:
  b Loop ; Wait forever

InitialiseGame$:
  push {lr}
  push {r4-r7,r11}
  add r11,r5

  ; Draw Left Paddle
  DrawLeft$:
    push {r0-r3}
    mov r0,r7             ; Screen Address
    mov r1,r4             ; X Ordinate
    mov r2,r5             ; Y Ordiante
    mov r3,r6             ; Colour Setting
      bl drawpixel
    pop {r0-r3}

    ; Increment X and Test
    add r4,#1             ; X++
    cmp r4,#40
      bls DrawLeft$       ; If X<=220, DrawPixel

    ; Increment Y, Reset X
    mov r4,#19            ; Reset X
    add r5,#1             ; Y++
    cmp r5,r11            ; Y limit
      bls DrawLeft$       ; Draw next line

  pop {r4-r7,r11}
  pop {lr}
  bx lr

; Draw Paddels
DrawPaddle$:
  push {lr}
  push {r11}
  add r11,r5              ; Calculate Limit = Current Y + 80

  push {r4-r7}
  ; Clear the current Paddel
  DrawClear$:
    push {r0-r3}
    mov r0,r7             ; Screen Address
    mov r1,r4             ; X Ordinate
    mov r2,r5             ; Y Ordiante
    mov r3,#0             ; Colour Setting
      bl drawpixel
    pop {r0-r3}

    ; Increment X and Test
    add r4,#1             ; X++
    cmp r4,#40
      bls DrawClear$      ; If X<=220, DrawPixel

    ; Increment Y, Reset X
    mov r4,#19            ; Reset X
    add r5,#1             ; Y++
    cmp r5,r11            ; Y limit
      bls DrawClear$      ; Draw next line
  pop {r4-r7}
  pop {r11}

  add r5,#1

  push {r4-r7,r11}
  add r11,r5              ; Calculate Limit = Current Y + 80
  ; Draw the Paddel
  Draww$:
    push {r0-r3}
    mov r0,r7             ; Screen Address
    mov r1,r4             ; X Ordinate
    mov r2,r5             ; Y Ordiante
    mov r3,r6             ; Colour Setting
      bl drawpixel
    pop {r0-r3}

    ; Increment X and Test
    add r4,#1             ; X++
    cmp r4,#40
      bls Draww$          ; If X<=220, DrawPixel

    ; Increment Y, Reset X
    mov r4,#19            ; Reset X
    add r5,#1             ; Y++
    cmp r5,r11            ; Y limit
      bls Draww$          ; Draw next line

    ; Reset X at the end of function
    mov r4,#19
    pop {r4-r7,r11}
  pop {lr}
  bx lr                 ; Return

Wait:
  push {r0-r12}
  mov r0,BASE
  mov r1,$4000
  orr r1,$0110
  orr r1,$000A   ;TIMER_MICROSECONDS = 16666 = 1/60 of a Second
  push {lr}
    bl Delay
  pop {lr}
  pop {r0-r12}
  bx lr

CoreLoop:
 b CoreLoop ; Infinite loop for Cores 1-3

include "drawpixel.asm"
include "FBinit16.asm"
include "timer2_2Param.asm"