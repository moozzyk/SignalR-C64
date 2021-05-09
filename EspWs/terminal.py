import serial


def write_and_wait(s, command):
    s.write(command.encode('utf-8'))
    s.write([10])
    result = s.readline().decode('utf-8').strip()
    print(result)
    if (result == 'ERROR'):
        print(s.readline().decode('utf-8').strip())


def main():
    s = serial.Serial('/dev/cu.usbserial-1420', 1200)
    while True:
        command = input('> ')
        if command == '':
            break
        write_and_wait(s, command)
    s.close()


if __name__ == '__main__':
    main()
