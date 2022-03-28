import serial
import sys

COMMAND_START_WIFI = 3
COMMAND_START_WEBSOCKET = 5
COMMAND_WEBSOCKET_SEND = 6

RESULT_OK = 1
RESULT_ERROR = 2
RESULT_DATA = 3
RESULT_WS = 4

result_code_to_string = {
    RESULT_OK: "OK",
    RESULT_ERROR: "ERROR",
    RESULT_DATA: "DATA",
    RESULT_WS: "WS",
}


def serialize_command(cmd_id, args):
    if (len(args)) > 255:
        raise ValueError("Command too long")
    return bytes([cmd_id, len(args)]) + args.encode('utf-8')


def send(s, cmd_id, args):
    cmd = serialize_command(cmd_id, args)
    print(cmd)
    s.write(cmd)


def read_and_print_message(s):
    result_code = s.read()[0]
    length = s.read()[0]
    print(result_code_to_string[result_code])
    if length > 0:
        payload = s.read(length)
        print(payload)


def send_receive(s, cmd_id, args):
    send(s, cmd_id, args)
    read_and_print_message(s)


def main():
    if len(sys.argv) < 3:
        print('Usage python3 proptotype.py {server} {device} [{bauds}]\nExample: python3 proptotype.py 192.168.86.250:5000 /dev/cu.usbserial-1420')
        return 1
    server = sys.argv[1]
    device = sys.argv[2]
    bauds = int(sys.argv[3]) if len(sys.argv) > 3 else 600
    s = serial.Serial(device, bauds)
    send_receive(s, COMMAND_START_WIFI, "")
    send_receive(s, COMMAND_START_WEBSOCKET, f"ws://{server}/chat")
    send(s, COMMAND_WEBSOCKET_SEND,
         '{"protocol": "messagepack", "version": 1}\x1e')
    while True:
        if s.in_waiting > 0:
            read_and_print_message(s)


if __name__ == '__main__':
    main()
