#### PingPongAsm
##### Made with Assembly (NASM) and Windows API (Win32).

###### Controls:
- W: Move up.
- S: Move down.

###### Note:
It seems like using WinAPI isn't a great way to do real-time rendering.
The game attempts to run at 60fps, but seems kind of inconsistent. I could use
another API for better graphical performance (something like OpenGL), but that
would increase the code size and I would also likely want to use a seperate
library for window creation, which would complicate things further. So, for
the sake of simplicity, this project only uses WinAPI.
