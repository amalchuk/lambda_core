; Copyright 2020-2021 Andrew Malchuk. All rights reserved.
; This project is licensed under the terms of the MIT License.

dw 0h                           ; reserved
dw 1h                           ; image type
dw 1h                           ; number of images

db 20h                          ; width
db 20h                          ; height
db 0h                           ; number of colors
db 0h                           ; reserved
dw 1h                           ; color planes
dw 20h                          ; bit depth
dd favicon_end - favicon_start  ; size
dd favicon_start                ; offset

favicon_start:
  file 'favicon.png'

favicon_end:
  ; end of file "favicon.png"
