.export host, handshake

host:       .byte "ws://192.168.86.250:5000/chat"
            .byte 0
handshake:  .byte "{", $22, "protocol", $22, ":", $22, "messagepack", $22
            .byte ",", $22, "version", $22, ":1}", $1e
