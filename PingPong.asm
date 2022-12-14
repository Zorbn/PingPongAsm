bits 64
default rel

; WinApi definitions:
NULL                equ 0
CS_BYTEALIGNWINDOW  equ 2000h
CS_HREDRAW          equ 2
CS_VREDRAW          equ 1
CW_USEDEFAULT       equ 80000000h
IDC_ARROW           equ 7F00h
IDI_APPLICATION     equ 7F00h
IMAGE_CURSOR        equ 2
IMAGE_ICON          equ 1
LR_SHARED           equ 8000h
SW_SHOWNORMAL       equ 1
WS_EX_COMPOSITED    equ 2000000h
WS_BORDER           equ 800000h
WS_MINIMIZEBOX      equ 20000h
WS_CAPTION          equ 0C00000h
WS_SYSMENU          equ 080000h
WM_CREATE           equ 1
WM_DESTROY          equ 2
WM_PAINT            equ 0Fh
WM_KEYDOWN          equ 100h
WM_KEYUP            equ 101h
WM_TIMER            equ 113h
VK_W                equ 57h
VK_S                equ 53h
COLOR_WINDOW        equ 5
BLACKNESS           equ 42h

extern CreateWindowExA
extern DefWindowProcA
extern DispatchMessageA
extern ExitProcess
extern GetMessageA
extern GetModuleHandleA
extern IsDialogMessageA
extern LoadImageA
extern PostQuitMessage
extern RegisterClassExA
extern ShowWindow
extern TranslateMessage
extern UpdateWindow
extern BeginPaint
extern EndPaint
extern CreateSolidBrush
extern DeleteObject
extern FillRect
extern SetTimer
extern InvalidateRect

; Constants:
WindowWidth  equ 640
WindowHeight equ 480

global Start

section .data
    WindowName      db "PingPong", 0
    ClassName       db "Window", 0
    BackgroundColor dd 00362A28h
    ForegroundColor dd 00F2F8F8h
    PlayerX         dd 16
    PlayerY         dd 64
    PlayerSpeed     dd 6
    PlayerWidth     dd 16
    PlayerHeight    dd 64
    BallX           dd WindowWidth / 2
    BallY           dd WindowHeight / 2
    BallDirX        dd -1
    BallDirY        dd 1
    BallSpeed       dd 6
    BallSize        dd 16

section .bss
    alignb 8
    hInstance       resq 1
    BackgroundBrush resq 1
    ForegroundBrush resq 1
    PlayerDir       resd 1

section .text
Start:
    sub  rsp, 8 ; Align stack pointer to 16 bytes.

    sub  rsp, 32 ; Shadow.
    xor  ecx, ecx
    call GetModuleHandleA
    mov  qword [hInstance], rax
    add  rsp, 32

    call WinMain

    xor  ecx, ecx
    call ExitProcess

WinMain:
    push rbp
    mov  rbp, rsp
    sub  rsp, 136 + 8 ; 136 bytes for local variables, 8 bytes for padding.

    %define wc               rbp - 136 ; WNDCLASSEX structure, 80 bytes.
    %define wc.cbSize        rbp - 136 ; 4 bytes. Start on an 8 byte boundary.
    %define wc.style         rbp - 132
    %define wc.lpfnWndProc   rbp - 128
    %define wc.cbClsExtra    rbp - 120
    %define wc.cbWndExtra    rbp - 116
    %define wc.hInstance     rbp - 112
    %define wc.hIcon         rbp - 104
    %define wc.hCursor       rbp - 96
    %define wc.hbrBackground rbp - 88
    %define wc.lpszMenuName  rbp - 80
    %define wc.lpszClassName rbp - 72
    %define wc.hIconSm       rbp - 64  ; 8 bytes. End on an 8 byte boundary.

    %define msg          rbp - 56  ; MSG structure, 48 bytes.
    %define msg.hwnd     rbp - 56  ; 8 bytes. Start on an 8 byte boundary.
    %define msg.message  rbp - 48
    %define msg.Padding1 rbp - 44  ; 4 bytes. Natural alignment padding.
    %define msg.wParam   rbp - 40
    %define msg.lParam   rbp - 32
    %define msg.time     rbp - 24
    %define msg.py.x     rbp - 20
    %define msg.pt.y     rbp - 16
    %define msg.Padding2 rbp - 12  ; 4 bytes. Structure length padding.

    %define hWnd               rbp - 8   ; 8 bytes.

    sub rsp, 32 ; Shadow
    mov  ecx, dword [BackgroundColor]
    call CreateSolidBrush
    mov  qword [BackgroundBrush], rax
    add rsp, 32

    sub rsp, 32 ; Shadow
    mov  ecx, dword [ForegroundColor]
    call CreateSolidBrush
    mov  qword [ForegroundBrush], rax
    add rsp, 32

    mov dword [wc.cbSize], 80
    mov dword [wc.style], CS_HREDRAW | CS_VREDRAW | CS_BYTEALIGNWINDOW
    lea rax, [WndProc]
    mov qword [wc.lpfnWndProc], rax
    mov dword [wc.cbClsExtra], NULL
    mov dword [wc.cbWndExtra], NULL
    mov rax, qword [hInstance]
    mov qword [wc.hInstance], rax

    sub  rsp, 32 + 16                   ; Shadow + 2 parameters.
    xor  ecx, ecx
    mov  edx, IDI_APPLICATION
    mov  r8d, IMAGE_ICON
    xor  r9d, r9D
    mov  qword [rsp + 4 * 8], NULL
    mov  qword [rsp + 5 * 8], LR_SHARED
    call LoadImageA                     ; Large program icon.
    mov  qword [wc.hIcon], rax
    add  rsp, 32 + 16

    sub  rsp, 32 + 16                   ; Shadow + 2 parameters.
    xor  ecx, ecx
    mov  edx, IDC_ARROW
    mov  r8d, IMAGE_CURSOR
    xor  r9d, r9D
    mov  qword [rsp + 4 * 8], NULL
    mov  qword [rsp + 5 * 8], LR_SHARED
    call LoadImageA                     ; Cursor.
    mov  qword [wc.hCursor], rax
    add  rsp, 32 + 16

    mov qword [wc.hbrBackground], COLOR_WINDOW + 1
    mov qword [wc.lpszMenuName], NULL
    lea rax, [ClassName]
    mov qword [wc.lpszClassName], rax

    sub  rsp, 32 + 16 ; Shadow + 2 parameters.
    xor  ecx, ecx
    mov  edx, IDI_APPLICATION
    mov  r8d, IMAGE_ICON
    xor  r9d, r9D
    mov  qword [rsp + 4 * 8], NULL
    mov  qword [rsp + 5 * 8], LR_SHARED
    call LoadImageA ; Small program icon.
    mov  qword [wc.hIconSm], rax
    add  rsp, 32 + 16

    sub  rsp, 32 ; Shadow.
    lea  rcx, [wc]
    call RegisterClassExA
    add  rsp, 32

    sub  rsp, 32 + 64 ; Shadow + 8 parameters.
    mov  ecx, WS_EX_COMPOSITED
    lea  rdx, [ClassName]
    lea  r8, [WindowName]
    mov  r9d, WS_MINIMIZEBOX | WS_BORDER | WS_CAPTION | WS_SYSMENU
    mov  dword [rsp + 4 * 8], CW_USEDEFAULT
    mov  dword [rsp + 5 * 8], CW_USEDEFAULT
    mov  dword [rsp + 6 * 8], WindowWidth
    mov  dword [rsp + 7 * 8], WindowHeight
    mov  qword [rsp + 8 * 8], NULL
    mov  qword [rsp + 9 * 8], NULL
    mov  rax, qword [hInstance]
    mov  qword [rsp + 10 * 8], rax
    mov  qword [rsp + 11 * 8], NULL
    call CreateWindowExA
    mov  qword [hWnd], rax
    add  rsp, 96

    sub  rsp, 32 ; Shadow.
    mov  rcx, qword [hWnd]
    mov  edx, SW_SHOWNORMAL
    call ShowWindow
    add  rsp, 32

    sub  rsp, 32 ; Shadow.
    mov  rcx, qword [hWnd]
    call UpdateWindow
    add  rsp, 32

    .MessageLoop:
    sub  rsp, 32 ; Shadow.
    lea  rcx, [msg]
    xor  edx, edx
    xor  r8d, r8d
    xor  r9d, r9D
    call GetMessageA
    add  rsp, 32
    cmp  rax, 0
    je   .Done

    sub  rsp, 32           ; Shadow.
    mov  rcx, qword [hWnd]
    lea  rdx, [msg]
    call IsDialogMessageA  ; For keyboard strokes.
    add  rsp, 32
    cmp  rax, 0
    jne  .MessageLoop      ; Skip TranslateMessage and DispatchMessageA.

    sub  rsp, 32 ; Shadow.
    lea  rcx, [msg]
    call TranslateMessage
    add  rsp, 32

    sub  rsp, 32 ; Shadow.
    lea  rcx, [msg]
    call DispatchMessageA
    add  rsp, 32
    jmp  .MessageLoop

    .Done:
    mov   rsp, rbp ; Remove the stack frame.
    pop   rbp
    xor   eax, eax
    ret

WndProc:
    push rbp      ; Set up a stack frame.
    mov  rbp, rsp
    sub  rsp, 80  ; Reserve space for structures

    %define hWnd   rbp + 16 ; Assign names to the shadow space
    %define uMsg   rbp + 24 ; (shadow space is provided by the caller)
    %define wParam rbp + 32
    %define lParam rbp + 40

    %define ps                  rbp - 80 ; PAINTSTRUCT structure. 72 bytes
    %define ps.hdc              rbp - 80 ; 8 bytes. Start on an 8 byte boundary
    %define ps.fErase           rbp - 72 ; 4 bytes
    %define ps.rcPaint.left     rbp - 68 ; 4 bytes
    %define ps.rcPaint.top      rbp - 64 ; 4 bytes
    %define ps.rcPaint.right    rbp - 60 ; 4 bytes
    %define ps.rcPaint.bottom   rbp - 56 ; 4 bytes
    %define ps.Restore          rbp - 52 ; 4 bytes
    %define ps.fIncUpdate       rbp - 48 ; 4 bytes
    %define ps.rgbReserved      rbp - 44 ; 32 bytes
    %define ps.Padding          rbp - 12 ; 4 bytes. Structure length padding

    %define hdc                 rbp - 8  ; 8 bytes

    ; Store parameters in shadow.
    mov qword [hWnd], rcx
    mov qword [uMsg], rdx
    mov qword [wParam], r8
    mov qword [lParam], r9

    cmp qword [uMsg], WM_CREATE
    je WMCREATE

    cmp qword [uMsg], WM_DESTROY
    je WMDESTROY

    cmp qword [uMsg], WM_PAINT
    je WMPAINT

    cmp qword [uMsg], WM_KEYDOWN
    je WMKEYDOWN

    cmp qword [uMsg], WM_KEYUP
    je WMKEYUP

    cmp qword [uMsg], WM_TIMER
    je WMTIMER

    ; Handle default message if no specific message was caught.
    sub  rsp, 32            ; Shadow.
    mov  rcx, qword [hWnd]
    mov  rdx, qword [uMsg]
    mov  r8, qword [wParam]
    mov  r9, qword [lParam]
    call DefWindowProcA
    add  rsp, 32

    mov  rsp, rbp
    pop  rbp
    ret

; Args: x1, y1, x2, y2, hdc, brush.
%macro MPaintRect 6
    sub rsp, 32 + 16
    mov   ecx, %1
    mov   edx, %2
    mov   r8d, %3
    add   r8d, %1
    mov   r9d, %4
    add   r9d, %2
    mov rax, %5
    mov qword [rsp], rax
    mov rax, %6
    mov qword [rsp + 8], rax
    call  PaintRect
    add rsp, 32 + 16
%endmacro

PaintRect:
    push rbp      ; Setup stack frame.
    mov  rbp, rsp 
    sub  rsp, 16  ; Reserve space for 16 byte RECT.

    ; Create a RECT.
    %define pr rbp - 16
    %define pr.left rbp - 16
    %define pr.top rbp - 12
    %define pr.right rbp - 8
    %define pr.bottom rbp - 4

    mov dword[pr.left], ecx
    mov dword[pr.top], edx
    mov dword[pr.right], r8d
    mov dword[pr.bottom], r9d

    sub  rsp, 32
    mov  rcx, qword [rbp + 16] ; Skip first 16 bytes, 8 bytes for return address and 8 bytes for stored rbp.
    lea  rdx, [pr]
    mov  r8, qword [rbp + 24]
    call FillRect
    add  rsp, 32

    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret

WMPAINT:
    ; Move the player.
    mov eax, dword [PlayerDir]
    mul dword [PlayerSpeed]
    add dword [PlayerY], eax

    ; Move the ball.
    mov eax, dword [BallDirX]
    mul dword [BallSpeed]
    add dword [BallX], eax
    mov eax, dword [BallDirY]
    mul dword [BallSpeed]
    add dword [BallY], eax

    ; Bounce the ball against the bottom wall.
    mov eax, dword [BallY]
    add eax, dword [BallSize]
    cmp eax, WindowHeight
    jl .DontBottomBounce
    mov dword [BallDirY], -1
    .DontBottomBounce:

    ; Bounce the ball against the top wall.
    cmp dword [BallY], 0
    jg .DontTopBounce
    mov dword [BallDirY], 1
    .DontTopBounce:

    mov eax, dword [PlayerX]
    add eax, dword [PlayerWidth]
    cmp dword [BallX], eax
    jg .DontLeftBounce

    ; Bounce the ball against the player.
    mov eax, dword [BallY]
    add eax, dword [BallSize]
    cmp eax, dword [PlayerY]
    jl .DontLeftBounce

    mov eax, dword [PlayerY]
    add eax, dword [PlayerHeight]
    cmp eax, dword [BallY]
    jl .DontLeftBounce

    mov dword [BallDirX], 1
    .DontLeftBounce:

    ; Bounce the ball against the right wall.
    mov eax, dword [BallX]
    add eax, dword [BallSize]
    cmp eax, WindowWidth
    jl .DontRightBounce
    mov dword [BallDirX], -1
    .DontRightBounce:

    ; Reset the ball if it passes the player.
    mov eax, dword [BallX]
    add eax, dword [BallSize]
    cmp dword [PlayerX], eax
    jl .DontReset
    mov dword [BallX], WindowWidth / 2
    mov dword [BallY], WindowHeight / 2
    .DontReset:

    sub  rsp, 32 ; Shadow.
    mov  rcx, qword [hWnd]
    lea  rdx, [ps]
    call BeginPaint
    mov  qword [hdc], rax
    add  rsp, 32

    ; Paint the background and foreground.
    MPaintRect 0, 0, WindowWidth, WindowHeight, [hdc], [BackgroundBrush]
    MPaintRect [BallX], [BallY], [BallSize], [BallSize], [hdc], [ForegroundBrush]
    MPaintRect [PlayerX], [PlayerY], [PlayerWidth], [PlayerHeight], [hdc], [ForegroundBrush]

    sub  rsp, 32 ; Shadow
    mov  rcx, qword [hWnd]
    lea  rdx, [ps]
    call EndPaint
    add  rsp, 32

    jmp Return

WMKEYUP:
    ; Stop moving up.
    cmp qword [wParam], VK_W
    jne .NotUp
    cmp dword [PlayerDir], -1
    jne .NotUp
    mov dword [PlayerDir], 0
    .NotUp:

    ; Stop moving down.
    cmp qword [wParam], VK_S
    jne .NotDown
    cmp dword [PlayerDir], 1
    jne .NotUp
    mov dword [PlayerDir], 0
    .NotDown:

    jmp Return

WMKEYDOWN:
    ; Start moving up.
    cmp qword [wParam], VK_W
    jne .NotUp
    mov dword [PlayerDir], -1
    .NotUp:

    ; Start moving down.
    cmp qword [wParam], VK_S
    jne .NotDown
    mov dword [PlayerDir], 1
    .NotDown:

    jmp Return

WMCREATE:
    sub rsp, 32 ; Shadow
    mov rcx, qword [hWnd]
    mov rdx, 1
    mov r8d, 16
    mov r9, NULL
    call SetTimer
    add rsp, 32

    jmp Return

WMTIMER:
    ; Redraw the window.
    sub rsp, 32
    mov rcx, qword [hWnd]
    mov rdx, NULL
    mov r8d, 0
    call InvalidateRect
    add rsp, 32

    jmp Return

WMDESTROY:
    sub  rsp, 32 ; Shadow
    mov  rcx, qword [BackgroundBrush]
    call DeleteObject
    add  rsp, 32

    sub  rsp, 32 ; Shadow
    mov  rcx, qword [ForegroundBrush]
    call DeleteObject
    add  rsp, 32

    sub  rsp, 32 ; Shadow.
    xor  ecx, ecx
    call PostQuitMessage
    add  rsp, 32

    jmp Return

Return:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
