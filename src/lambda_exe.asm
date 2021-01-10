; Copyright 2020-2021 Andrew Malchuk. All rights reserved.
; This project is licensed under the terms of the MIT License.

format PE GUI
entry start

include 'win32a.inc'

; +--------------------------------------------+
; |                CODE SECTION                |
; +--------------------------------------------+

start:
  push    ebx esi edi

  invoke  CreateToolhelp32Snapshot, TH32CS_SNAPPROCESS, 0
  inc     eax
  jz      @f
  dec     eax
  mov     ebx, eax

  mov     [lppe.dwSize], sizeof.PROCESSENTRY32
  invoke  Process32First, ebx, lppe
  test    eax, eax
  jz      @f

.search:
  invoke  lstrcmpi, lppe.szExeFile, szProcess
  test    eax, eax
  jnz     .next
  jmp     .inject

.next:
  invoke  Process32Next, ebx, lppe
  test    eax, eax
  jnz     .search
  jmp     @f

.inject:
  invoke  CloseHandle, ebx
  test    eax, eax
  jz      @f

  invoke  OpenProcess, PROCESS_ALL_ACCESS, 0, [lppe.th32ProcessID]
  test    eax, eax
  jz      @f
  mov     ebx, eax

  invoke  GetFullPathName, szLibrary, MAX_PATH, szLibraryPath, 0
  test    eax, eax
  jz      @f
  mov     esi, eax

  invoke  VirtualAllocEx, ebx, 0, esi, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE
  test    eax, eax
  jz      @f
  mov     edi, eax

  invoke  WriteProcessMemory, ebx, eax, szLibraryPath, esi, 0
  test    eax, eax
  jz      @f

  invoke  CreateRemoteThread, ebx, 0, 0, [LoadLibrary], edi, 0, 0
  test    eax, eax
  jz      @f
  mov     esi, eax

  invoke  WaitForSingleObject, eax, INFINITE
  test    eax, eax
  jnz     @f

  invoke  CloseHandle, esi
  test    eax, eax
  jz      @f

  invoke  VirtualFreeEx, ebx, edi, 0, MEM_DECOMMIT
  test    eax, eax
  jz      @f

  invoke  CloseHandle, ebx
  test    eax, eax
  jz      @f
  invoke  Beep, 2EEh, 12Ch

@@:
  pop     edi esi ebx
  invoke  ExitProcess, 0

; +--------------------------------------------+
; |              OPTIONS SECTION               |
; +--------------------------------------------+

szProcess db 'hl.exe', 0
szLibrary db 'lambda.dll', 0
szLibraryPath rb MAX_PATH

TH32CS_SNAPPROCESS = 2h
INFINITE = 0FFFFFFFFh

struct PROCESSENTRY32
  dwSize              dd ?
  cntUsage            dd ?
  th32ProcessID       dd ?
  th32DefaultHeapID   dd ?
  th32ModuleID        dd ?
  cntThreads          dd ?
  th32ParentProcessID dd ?
  pcPriClassBase      dd ?
  dwFlags             dd ?
  szExeFile           rb MAX_PATH
ends

lppe PROCESSENTRY32

; +--------------------------------------------+
; |               IMPORT SECTION               |
; +--------------------------------------------+

data import
  dd 0, 0, 0, RVA kernel_name, RVA kernel_table
  dd 0, 0, 0, 0, 0

  kernel_name db 'kernel32.dll', 0

  kernel_table:
    Beep dd RVA _Beep
    CloseHandle dd RVA _CloseHandle
    CreateRemoteThread dd RVA _CreateRemoteThread
    CreateToolhelp32Snapshot dd RVA _CreateToolhelp32Snapshot
    ExitProcess dd RVA _ExitProcess
    GetFullPathName dd RVA _GetFullPathName
    LoadLibrary dd RVA _LoadLibrary
    OpenProcess dd RVA _OpenProcess
    Process32First dd RVA _Process32First
    Process32Next dd RVA _Process32Next
    VirtualAllocEx dd RVA _VirtualAllocEx
    VirtualFreeEx dd RVA _VirtualFreeEx
    WaitForSingleObject dd RVA _WaitForSingleObject
    WriteProcessMemory dd RVA _WriteProcessMemory
    lstrcmpi dd RVA _lstrcmpi
    dd 0

  ; kernel32.dll =>
  _Beep dw 0
    db 'Beep', 0
  _CloseHandle dw 0
    db 'CloseHandle', 0
  _CreateRemoteThread dw 0
    db 'CreateRemoteThread', 0
  _CreateToolhelp32Snapshot dw 0
    db 'CreateToolhelp32Snapshot', 0
  _ExitProcess dw 0
    db 'ExitProcess', 0
  _GetFullPathName dw 0
    db 'GetFullPathNameA', 0
  _LoadLibrary dw 0
    db 'LoadLibraryA', 0
  _OpenProcess dw 0
    db 'OpenProcess', 0
  _Process32First dw 0
    db 'Process32First', 0
  _Process32Next dw 0
    db 'Process32Next', 0
  _VirtualAllocEx dw 0
    db 'VirtualAllocEx', 0
  _VirtualFreeEx dw 0
    db 'VirtualFreeEx', 0
  _WaitForSingleObject dw 0
    db 'WaitForSingleObject', 0
  _WriteProcessMemory dw 0
    db 'WriteProcessMemory', 0
  _lstrcmpi dw 0
    db 'lstrcmpiA', 0
end data

; +--------------------------------------------+
; |             RESOURCES SECTION              |
; +--------------------------------------------+

data resource
  directory RT_ICON, icons, RT_GROUP_ICON, group_icons, RT_VERSION, versions

  resource icons, 1, LANG_NEUTRAL, icon_data
  resource group_icons, 1, LANG_NEUTRAL, main_icon
  resource versions, 1, LANG_NEUTRAL, version

  icon main_icon, icon_data, 'favicon.ico'
  versioninfo version, VOS_NT_WINDOWS32, VFT_APP, VFT2_UNKNOWN, LANG_NEUTRAL, 0, \
    'Comments', 'Lambda Core', \
    'FileDescription', 'OpenGL32 hooking library for GoldSource-based engine games', \
    'FileVersion', '1.0', \
    'InternalName', 'lambda', \
    'LegalCopyright', 'Copyright 2020-2021 Andrew Malchuk. All rights reserved.', \
    'OriginalFilename', 'lambda.exe', \
    'ProductName', 'Lambda Core', \
    'ProductVersion', '1.0'
end data

; +--------------------------------------------+
; |               FIXUPS SECTION               |
; +--------------------------------------------+

section '.reloc' fixups data readable discardable
