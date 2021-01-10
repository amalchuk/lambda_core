; Copyright 2020-2021 Andrew Malchuk. All rights reserved.
; This project is licensed under the terms of the MIT License.

format PE DLL
entry DllMain

include 'win32a.inc'

; +--------------------------------------------+
; |         MACRO DEFINITIONS SECTION          |
; +--------------------------------------------+

macro double number {
  local ..value, ..high, ..low
  virtual at 0
    ..value dq number
    load ..high dword from 4
    load ..low dword from 0
  end virtual
  push ..high
  push ..low
}

; +--------------------------------------------+
; |                CODE SECTION                |
; +--------------------------------------------+

allocate:
  cmp       dword [.address], 0
  jz        .initialize

  @@:
    push    ecx
    push    0
    push    dword [.address]
    call    [HeapAlloc]
    ret

  .initialize:
    call    [GetProcessHeap]
    test    eax, eax
    jz      .error

    mov     dword [.address], eax
    jmp     @b

  .error:
    ret

  .address:
    dd 0


splicing:
  push      ebx edi ebp
  pushfd

  cld
  mov       ebx, ecx

  mov       ecx, ebx
  add       ecx, 5h
  call      allocate
  test      eax, eax
  jz        .finish

  push      edi
  mov       ecx, ebx
  mov       edi, eax
  rep       movsb
  sub       esi, ebx
  pop       edi

  mov       byte [eax + ebx], 0E9h
  mov       edx, esi
  sub       edx, eax
  sub       edx, 5h
  mov       dword [eax + ebx + 1], edx

  push      eax
  mov       ebp, esi
  and       ebp, 0FFFFF000h

  push      .protection
  push      PAGE_EXECUTE_READWRITE
  push      1000h
  push      ebp
  call      [VirtualProtect]

  mov       byte [esi], 0E9h
  mov       edx, edi
  sub       edx, esi
  sub       edx, 5h
  mov       dword [esi + 1], edx

  cmp       ebx, 5h
  jle       .cleanup

  mov       ecx, ebx
  sub       ecx, 5h

  mov       edi, esi
  add       edi, 5h
  mov       al, 90h
  rep       stosb

  .cleanup:
    push    .protection
    push    dword [.protection]
    push    1000h
    push    ebp
    call    [VirtualProtect]

    pop     eax

  .finish:
    popfd
    pop     ebp edi ebx
    ret

  .protection:
    dd ?


proc DetourFunction uses esi edi ecx, procedure, gateway, length
  mov       ecx, dword [length]
  add       ecx, 5h

  mov       edi, dword [gateway]
  mov       esi, dword [procedure]
  call      splicing
  ret
endp


proc hacked_glBegin mode
  cmp       [mode], GL_TRIANGLES
  je        .enable_wallhack
  cmp       [mode], GL_TRIANGLE_STRIP
  je        .enable_wallhack
  cmp       [mode], GL_TRIANGLE_FAN
  je        .enable_wallhack

  cmp       [mode], GL_QUADS
  je        .disable_wallhack
  cmp       [mode], GL_QUAD_STRIP
  je        .disable_wallhack
  cmp       [mode], GL_POLYGON
  je        .disable_wallhack

  @@:
    xor     eax, eax
    jmp     @f

  .enable_wallhack:
    cmp     [found_an_entity], 1
    je      @b
    mov     [found_an_entity], 1

    double  0.5
    double  0.0
    call    [glDepthRange]
    jmp     @b

  .disable_wallhack:
    cmp     [found_an_entity], 0
    je      @b
    mov     [found_an_entity], 0

    double  1.0
    double  0.0
    call    [glDepthRange]
    jmp     @b

  @@:
    push    [mode]
    call    [original_glBegin]
    ret
endp


proc hacked_glVertex3f x, y, z
  push      1.0
  push      1.0
  push      1.0
  call      [glColor3f]

  @@:
    push    [z]
    push    [y]
    push    [x]
    call    [original_glVertex3f]
    ret
endp


main:
  stdcall   DetourFunction, [glBegin], hacked_glBegin, 6h
  mov       [original_glBegin], eax

  stdcall   DetourFunction, [glVertex3f], hacked_glVertex3f, 6h
  mov       [original_glVertex3f], eax


proc DllMain hinstDLL, fdwReason, lpvReserved
  cmp       [fdwReason], DLL_PROCESS_ATTACH
  jne       @f

  invoke    DisableThreadLibraryCalls, [hinstDLL]
  test      eax, eax
  jz        @f

  invoke    CreateThread, 0, 0, main, 0, 0, 0
  test      eax, eax
  jz        @f
  invoke    CloseHandle, eax

  @@:
    mov     eax, TRUE
    ret
endp

; +--------------------------------------------+
; |              OPTIONS SECTION               |
; +--------------------------------------------+

; Global variables:
found_an_entity dd 0

; Original OpenGL functions:
original_glBegin dd ?
original_glVertex3f dd ?

; Primitives:
GL_TRIANGLES = 4h
GL_TRIANGLE_STRIP = 5h
GL_TRIANGLE_FAN = 6h
GL_QUADS = 7h
GL_QUAD_STRIP = 8h
GL_POLYGON = 9h

; +--------------------------------------------+
; |               IMPORT SECTION               |
; +--------------------------------------------+

data import
  dd 0, 0, 0, RVA kernel_name, RVA kernel_table
  dd 0, 0, 0, RVA opengl_name, RVA opengl_table
  dd 0, 0, 0, 0, 0

  kernel_name db 'kernel32.dll', 0
  opengl_name db 'opengl32.dll', 0

  kernel_table:
    CloseHandle dd RVA _CloseHandle
    CreateThread dd RVA _CreateThread
    DisableThreadLibraryCalls dd RVA _DisableThreadLibraryCalls
    GetProcessHeap dd RVA _GetProcessHeap
    HeapAlloc dd RVA _HeapAlloc
    VirtualProtect dd RVA _VirtualProtect
    dd 0

  opengl_table:
    glBegin dd RVA _glBegin
    glColor3f dd RVA _glColor3f
    glDepthRange dd RVA _glDepthRange
    glVertex3f dd RVA _glVertex3f
    dd 0

  ; kernel32.dll =>
  _CloseHandle dw 0
    db 'CloseHandle', 0
  _CreateThread dw 0
    db 'CreateThread', 0
  _DisableThreadLibraryCalls dw 0
    db 'DisableThreadLibraryCalls', 0
  _GetProcessHeap dw 0
    db 'GetProcessHeap', 0
  _HeapAlloc dw 0
    db 'HeapAlloc', 0
  _VirtualProtect dw 0
    db 'VirtualProtect', 0

  ; opengl32.dll =>
  _glBegin dw 0
    db 'glBegin', 0
  _glColor3f dw 0
    db 'glColor3f', 0
  _glDepthRange dw 0
    db 'glDepthRange', 0
  _glVertex3f dw 0
    db 'glVertex3f', 0
end data

; +--------------------------------------------+
; |               FIXUPS SECTION               |
; +--------------------------------------------+

section '.reloc' fixups data readable discardable
