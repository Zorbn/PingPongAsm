nasm -f win64 -o PingPong.obj PingPong.asm && link PingPong.obj /subsystem:windows /libpath:c:\lib64 /out:PingPong.exe /entry:Start kernel32.lib user32.lib gdi32.lib msvcrt.lib
