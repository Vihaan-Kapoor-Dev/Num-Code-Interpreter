import sys
from pathlib import Path

def main() -> int:
    if len(sys.argv) != 3:
        print("usage: Num-Code-Compiler.py input.txt output.bin", file=sys.stderr)
        return 2
    src = Path(sys.argv[1]).read_text(encoding="utf-8")
    values = []
    for token in src.replace(",", " ").split():
        value = int(token, 10)
        if not 0 <= value <= 255:
            raise ValueError(f"byte out of range: {value}")
        values.append(value)
    Path(sys.argv[2]).write_bytes(bytes(values))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
