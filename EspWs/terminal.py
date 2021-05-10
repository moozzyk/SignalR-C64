import serial

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


def parse_command(command):
    lower_case_command = command.lower()
    for cmd, cmd_id in command_map.items():
        if lower_case_command.startswith(cmd):
            return (cmd_id, command[len(cmd):])
    raise ValueError("Unknown command")


def serialize_command(cmd_id, args):
    if (len(args)) > 254:
        raise ValueError("Command too long")
    return bytes([len(args) + 1, cmd_id]) + args.encode('utf-8')


def write_and_wait(s, command):
    cmd_id, args = parse_command(command)
    payload = serialize_command(cmd_id, args)
    s.write(payload)
    result = s.readline().decode('utf-8').strip()
    print(result)
    if 'ERROR' in result or 'WS' in result or 'DATA' in result:
        read(s)


def read(s):
    print(s.readline().decode('utf-8').strip())


def main():
    s = serial.Serial('/dev/cu.usbserial-1420', 1200)
    while True:
        command = input('> ')
        if command == '':
            break
        try:
            if command == '>':
                read(s)
            else:
                write_and_wait(s, command.strip())
        except ValueError as err:
            print(f"""Terminal: {err}""")
    s.close()


if __name__ == '__main__':
    main()
