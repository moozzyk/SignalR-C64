.export echo_off, start_wifi, start_ws, ws_send

echo_off:   .byte "echooff", $0a
start_wifi: .byte "wifion", $0a
start_ws:   .byte "wsstart$", $00
ws_send:    .byte "wssend$", $00