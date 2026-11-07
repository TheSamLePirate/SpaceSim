"""Read FSO's LZ41 resource files without changing installed game data."""
import ctypes
import struct
from pathlib import Path


def read_resource(path):
    data = Path(path).read_bytes()
    if data[:4] != b'LZ41':
        return data
    count, size, block_size = struct.unpack('<3I', data[-12:])
    offsets = struct.unpack(f'<{count}I', data[-12 - count * 4:-12])
    lib = ctypes.CDLL('/opt/homebrew/opt/lz4/lib/liblz4.dylib')
    decompress = lib.LZ4_decompress_safe
    decompress.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int, ctypes.c_int]
    decompress.restype = ctypes.c_int
    chunks = []
    for start, end in zip(offsets, offsets[1:]):
        output = ctypes.create_string_buffer(block_size)
        chunk = data[start:end]
        length = decompress(chunk, output, len(chunk), block_size)
        if length < 0:
            raise ValueError(f'LZ4 decode failed: {path}, offset {start}')
        chunks.append(output.raw[:length])
    result = b''.join(chunks)
    if len(result) != size:
        raise ValueError(f'Unexpected decoded size: {len(result)} != {size}')
    return result

if __name__ == '__main__':
    import sys
    sys.stdout.buffer.write(read_resource(sys.argv[1]))
