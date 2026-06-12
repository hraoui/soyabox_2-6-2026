#!/usr/bin/env python3
"""
Simple TCP listener to capture bytes sent to a receipt printer port (default 9100).
Saves each connection as /tmp/prints/print-<timestamp>.bin and prints a small hex preview.
Usage:
  python3 tools/print_listener.py --host 127.0.0.1 --port 9100 --outdir /tmp/prints
"""
import socket
import argparse
import time
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description='Print listener (capture ESC/POS bytes)')
    parser.add_argument('--host', default='127.0.0.1', help='Host to bind (default 127.0.0.1)')
    parser.add_argument('--port', type=int, default=9100, help='Port to bind (default 9100)')
    parser.add_argument('--outdir', default='/tmp/prints', help='Output directory (default /tmp/prints)')
    args = parser.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    print(f'Listening on {args.host}:{args.port}, saving into {outdir}')

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((args.host, args.port))
        s.listen(5)
        try:
            while True:
                conn, addr = s.accept()
                ts = int(time.time())
                fname = outdir / f'print-{ts}.bin'
                print(f'Connection from {addr}, saving to {fname}')
                with conn:
                    with open(fname, 'wb') as f:
                        while True:
                            data = conn.recv(4096)
                            if not data:
                                break
                            f.write(data)
                try:
                    size = fname.stat().st_size
                except Exception:
                    size = -1
                print(f'Saved {fname} ({size} bytes)')
                try:
                    with open(fname, 'rb') as f:
                        head = f.read(64)
                    print('Head (hex):', head.hex())
                except Exception as e:
                    print('Unable to read head:', e)
        except KeyboardInterrupt:
            print('\nStopped by user')


if __name__ == '__main__':
    main()
