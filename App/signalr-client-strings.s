.export host, handshake

host:       .byte "ws://192.168.86.165:5000/chat", $0a, $00
handshake:  .byte "{", $22, "protocol", $22, ":", $22, "json", $22
            .byte ", ", $22, "version", $22, ":1}", $1e, $0a, $00