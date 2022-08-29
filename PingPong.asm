bits 64
default rel

; WinApi definitions:
COLOR_WINDOW        equ 5
CS_BYTEALIGNWINDOW  equ 2000h
CS_HREDRAW          equ 2
CS_VREDRAW          equ 1
CW_USEDEFAULT       equ 80000000h
IDC_ARROW           equ 7F00h
IDI_APPLICATION     equ 7F00h
IMAGE_CURSOR        equ 2
IMAGE_ICON          equ 1
LR_SHARED           equ 8000h
NULL                equ 0
SW_SHOWNORMAL       equ 1
WM_DESTROY          equ 2
WM_PAINT            equ 0Fh
WS_EX_COMPOSITED    equ 2000000h
WS_OVERLAPPEDWINDOW equ 0CF0000h
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
extern BitBlt
extern CreateSolidBrush
extern FillRect

; Constants:
WindowWidth  equ 640
WindowHeight equ 480

global Start

section .data
    WindowName      db "PingPong", 0
    ClassName       db "Window", 0
    BackgroundColor dd 0A56E3Bh

section .bss
    alignb 8
    hInstance resq 1
    BackgroundBrush resq 1

section .text
Start:
    sub   rsp, 8 ; Align stack pointer to 16 bytes.

    sub   rsp, 32 ; Shadow.
    xor   ecx, ecx
    call  GetModuleHandleA
    mov   qword [hInstance], rax
    add   rsp, 32

    call  WinMain

    xor   ecx, ecx
    call  ExitProcess

WinMain:
    push  rbp
    mov   rbp, rsp
    sub   rsp, 136 + 8 ; 136 bytes for local variables, 8 bytes for padding.

    %define wc                 rbp - 136 ; WNDCLASSEX structure, 80 bytes.
    %define wc.cbSize          rbp - 136 ; 4 bytes. Start on an 8 byte boundary.
    %define wc.style           rbp - 132
    %define wc.lpfnWndProc     rbp - 128
    %define wc.cbClsExtra      rbp - 120
    %define wc.cbWndExtra      rbp - 116
    %define wc.hInstance       rbp - 112
    %define wc.hIcon           rbp - 104
    %define wc.hCursor         rbp - 96
    %define wc.hbrBackground   rbp - 88
    %define wc.lpszMenuName    rbp - 80
    %define wc.lpszClassName   rbp - 72
    %define wc.hIconSm         rbp - 64  ; 8 bytes. End on an 8 byte boundary.

    %define msg                rbp - 56  ; MSG structure, 48 bytes.
    %define msg.hwnd           rbp - 56  ; 8 bytes. Start on an 8 byte boundary.
    %define msg.message        rbp - 48
    %define msg.Padding1       rbp - 44  ; 4 bytes. Natural alignment padding.
    %define msg.wParam         rbp - 40
    %define msg.lParam         rbp - 32
    %define msg.time           rbp - 24
    %define msg.py.x           rbp - 20
    %define msg.pt.y           rbp - 16
    %define msg.Padding2       rbp - 12  ; 4 bytes. Structure length padding.

    %define hWnd               rbp - 8   ; 8 bytes.

    mov   ecx, dword [BackgroundColor]
    call  CreateSolidBrush
    mov   qword [BackgroundBrush], rax

    mov   dword [wc.cbSize], 80
    mov   dword [wc.style], CS_HREDRAW | CS_VREDRAW | CS_BYTEALIGNWINDOW
    lea   rax, [WndProc]
    mov   qword [wc.lpfnWndProc], rax
    mov   dword [wc.cbClsExtra], NULL
    mov   dword [wc.cbWndExtra], NULL
    mov   rax, qword [hInstance]
    mov   qword [wc.hInstance], rax

    sub   rsp, 32 + 16                   ; Shadow + 2 parameters.
    xor   ecx, ecx
    mov   edx, IDI_APPLICATION
    mov   r8d, IMAGE_ICON
    xor   r9d, r9D
    mov   qword [rsp + 4 * 8], NULL
    mov   qword [rsp + 5 * 8], LR_SHARED
    call  LoadImageA                     ; Large program icon.
    mov   qword [wc.hIcon], rax
    add   rsp, 32 + 16

    sub   rsp, 32 + 16                   ; Shadow + 2 parameters.
    xor   ecx, ecx
    mov   edx, IDC_ARROW
    mov   r8d, IMAGE_CURSOR
    xor   r9d, r9D
    mov   qword [rsp + 4 * 8], NULL
    mov   qword [rsp + 5 * 8], LR_SHARED
    call  LoadImageA                     ; Cursor.
    mov   qword [wc.hCursor], rax
    add   rsp, 32 + 16

    mov   qword [wc.hbrBackground], COLOR_WINDOW + 1
    mov   qword [wc.lpszMenuName], NULL
    lea   rax, [ClassName]
    mov   qword [wc.lpszClassName], rax

    sub   rsp, 32 + 16 ; Shadow + 2 parameters.
    xor   ecx, ecx
    mov   edx, IDI_APPLICATION
    mov   r8d, IMAGE_ICON
    xor   r9d, r9D
    mov   qword [rsp + 4 * 8], NULL
    mov   qword [rsp + 5 * 8], LR_SHARED
    call  LoadImageA ; Small program icon.
    mov   qword [wc.hIconSm], rax
    add   rsp, 32 + 16

    sub   rsp, 32 ; Shadow.
    lea   rcx, [wc]
    call  RegisterClassExA
    add   rsp, 32

    sub   rsp, 32 + 64 ; Shadow + 8 parameters.
    mov   ecx, WS_EX_COMPOSITED
    lea   rdx, [ClassName]
    lea   r8, [WindowName]
    mov   r9d, WS_OVERLAPPEDWINDOW
    mov   dword [rsp + 4 * 8], CW_USEDEFAULT
    mov   dword [rsp + 5 * 8], CW_USEDEFAULT
    mov   dword [rsp + 6 * 8], WindowWidth
    mov   dword [rsp + 7 * 8], WindowHeight
    mov   qword [rsp + 8 * 8], NULL
    mov   qword [rsp + 9 * 8], NULL
    mov   rax, qword [hInstance]
    mov   qword [rsp + 10 * 8], rax
    mov   qword [rsp + 11 * 8], NULL
    call  CreateWindowExA
    mov   qword [hWnd], rax
    add   rsp, 96

    sub   rsp, 32 ; Shadow.
    mov   rcx, qword [hWnd]
    mov   edx, SW_SHOWNORMAL
    call  ShowWindow
    add   rsp, 32

    sub   rsp, 32 ; Shadow.
    mov   rcx, qword [hWnd]
    call  UpdateWindow
    add   rsp, 32

    .MessageLoop:
    sub   rsp, 32 ; Shadow.
    lea   rcx, [msg]
    xor   edx, edx
    xor   r8d, r8d
    xor   r9d, r9D
    call  GetMessageA
    add   rsp, 32
    cmp   rax, 0
    je    .Done

    sub   rsp, 32           ; Shadow.
    mov   rcx, qword [hWnd]
    lea   rdx, [msg]
    call  IsDialogMessageA  ; For keyboard strokes.
    add   rsp, 32
    cmp   rax, 0
    jne   .MessageLoop      ; Skip TranslateMessage and DispatchMessageA.

    sub   rsp, 32 ; Shadow.
    lea   rcx, [msg]
    call  TranslateMessage
    add   rsp, 32

    sub   rsp, 32 ; Shadow.
    lea   rcx, [msg]
    call  DispatchMessageA
    add   rsp, 32
    jmp   .MessageLoop

    .Done:
    mov   rsp, rbp ; Remove the stack frame.
    pop   rbp
    xor   eax, eax
    ret

WndProc:
    push  rbp      ; Set up a stack frame.
    mov   rbp, rsp
    sub   rsp, 80  ; Reserve space for structures

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
    mov   qword [hWnd], rcx
    mov   qword [uMsg], rdx
    mov   qword [wParam], r8
    mov   qword [lParam], r9

    cmp   qword [uMsg], WM_DESTROY
    je    WMDESTROY

    cmp   qword [uMsg], WM_PAINT
    je    WMPAINT

DefaultMessage:
    sub   rsp, 32            ; Shadow.
    mov   rcx, qword [hWnd]
    mov   rdx, qword [uMsg]
    mov   r8, qword [wParam]
    mov   r9, qword [lParam]
    call  DefWindowProcA
    add   rsp, 32

    mov   rsp, rbp
    pop   rbp
    ret

; Args: x1, y1, x2, y2, hdc, brush.
%macro MPaintRect 6
    sub rsp, 32 + 16
    mov   ecx, %1
    mov   edx, %2
    mov   r8d, %3
    mov   r9d, %4
    mov rax, %5
    mov qword [rsp], rax
    mov rax, %6
    mov qword [rsp + 8], rax
    call  PaintRect
    add rsp, 32 + 16
%endmacro

%macro MPaintRectSized 6
    MPaintRect %1, %2, %1 + %3, %2 + %4, %5, %6
%endmacro

PaintRect:
    push  rbp      ; Setup stack frame.
    mov   rbp, rsp 
    sub   rsp, 16  ; Reserve space for 16 byte RECT.

    %define pr rbp - 16
    %define pr.left rbp - 16
    %define pr.top rbp - 12
    %define pr.right rbp - 8
    %define pr.bottom rbp - 4

    mov dword[pr.left], ecx
    mov dword[pr.top], edx
    mov dword[pr.right], r8d
    mov dword[pr.bottom], r9d

    sub   rsp, 32
    mov   rcx, qword [rbp + 16] ; Skip first 16 bytes, 8 bytes for return address and 8 bytes for stored rbp.
    lea   rdx, [pr]
    mov   r8, qword [rbp + 24]
    call  FillRect
    add   rsp, 32

    xor   rax, rax
    mov   rsp, rbp
    pop   rbp
    ret

WMPAINT:
    mov  rcx, qword [hWnd]
    lea  rdx, [ps]
    call BeginPaint
    mov  qword [hdc], rax

    MPaintRect      0, 0, 32, 64, [hdc], [BackgroundBrush]
    MPaintRect      64, 128, 256, 64, [hdc], [BackgroundBrush]
    MPaintRectSized 128, 256, 16, 16, [hdc], [BackgroundBrush]

    mov  rcx, qword [hWnd]
    lea  rdx, [ps]
    call EndPaint

    jmp Return

WMDESTROY:
    sub   rsp, 32 ; Shadow.
    xor   ecx, ecx
    call  PostQuitMessage
    add   rsp, 32

    jmp Return

Return:
    xor eax, eax
    mov rsp, rbp
    pop rbp
    ret
