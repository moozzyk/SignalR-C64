.export host, handshake

host:       .byte "ws://192.168.86.222:5000/chat"
handshake:  .byte "{", $22, "protocol", $22, ":", $22, "json", $22
            .byte ",", $22, "version", $22, ":1}", $1e
