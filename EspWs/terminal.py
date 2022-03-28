import serial
import time

COMMAND_SET_SSID = 1
COMMAND_SET_PASS = 2
COMMAND_START_WIFI = 3
COMMAND_STOP_WIFI = 4
COMMAND_START_WEBSOCKET = 5
COMMAND_WEBSOCKET_SEND = 6

command_map = {
    "ssid$": COMMAND_SET_SSID,
    "pass$": COMMAND_SET_PASS,
    "wifion": COMMAND_START_WIFI,
    "wifioff": COMMAND_STOP_WIFI,
    "wsstart$": COMMAND_START_WEBSOCKET,
    "wssend$":  COMMAND_WEBSOCKET_SEND,
}

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


def drain(s):
    for _ in range(20):
        if s.inWaiting():
            s.read()
        else:
            time.sleep(0.05)


def parse_command(command):
    lower_case_command = command.lower()
    for cmd, cmd_id in command_map.items():
        if lower_case_command.startswith(cmd):
            return (cmd_id, command[len(cmd):])
    raise ValueError("Unknown command")


def serialize_command(cmd_id, args):
    if (len(args)) > 255:
        raise ValueError("Command too long")
    return bytes([cmd_id, len(args)]) + args.encode('utf-8')


def read_and_print_message(s):
    result_code = s.read()[0]
    length = s.read()[0]
    print(result_code_to_string[result_code])
    if length > 0:
        payload = s.read(length)
        print(payload)


def try_read_and_print_messages(s):
    while s.in_waiting > 0:
        read_and_print_message(s)


def write_and_wait(s, command):
    cmd_id, args = parse_command(command)
    payload = serialize_command(cmd_id, args)
    print(payload)
    s.write(payload)
    read_and_print_message(s)
    try_read_and_print_messages(s)


def main():
    s = serial.Serial('/dev/cu.usbserial-1420', 600)
    drain(s)
    while True:
        command = input('> ')
        if command == '':
            break
        try:
            if command == '>':
                if s.in_waiting > 0:
                    try_read_and_print_messages(s)
                else:
                    print("No data waiting")
            else:
                write_and_wait(s, command.strip())
        except ValueError as err:
            print(f"""Terminal: {err}""")
    s.close()


if __name__ == '__main__':
    main()
