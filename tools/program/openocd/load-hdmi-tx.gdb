set pagination off
set confirm off
set remotetimeout 120
target extended-remote localhost:3333
monitor reset halt
load
set $pc = _start
monitor resume
disconnect
quit 0
