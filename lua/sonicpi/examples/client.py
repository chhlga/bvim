#!/usr/bin/env python3
"""
SonicPi Log Stream Client (Python)

Connect to the TCP streaming server and receive real-time log messages.
"""

import socket
import json
import sys

HOST = "127.0.0.1"
PORT = 8765


def main():
    print(f"Connecting to SonicPi stream at {HOST}:{PORT}...")

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((HOST, PORT))
        print("Connected! Listening for messages...\n")

        buffer = ""

        while True:
            data = sock.recv(4096).decode("utf-8")
            if not data:
                print("\nConnection closed by server")
                break

            buffer += data
            lines = buffer.split("\n")
            buffer = lines[-1]

            for line in lines[:-1]:
                if not line.strip():
                    continue

                try:
                    msg = json.loads(line)

                    address = msg.get("address_raw", "unknown")
                    timestamp = msg.get("timestamp", 0)
                    data_content = msg.get("data", {})

                    print(f"[{address}] @ {timestamp}")
                    print(f"  Data: {data_content}")
                    print()

                except json.JSONDecodeError as e:
                    print(f"Failed to decode JSON: {e}")
                    print(f"Raw line: {line[:100]}")

    except ConnectionRefusedError:
        print(f"Error: Could not connect to {HOST}:{PORT}")
        print("Make sure Neovim is running with a sonicpi file open")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n\nDisconnecting...")
    finally:
        sock.close()


if __name__ == "__main__":
    main()
