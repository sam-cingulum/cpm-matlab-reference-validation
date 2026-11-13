#!/usr/bin/env python3
"""Archive genuine original MathWorks R2026b V9 artifacts by verified local bytes.

Usage: python3 archive_v9_source_bytes.py /path/to/v9_download_root
The download root has v9_run_<run-id> subdirectories. Does not modify source.
"""
import gzip
import hashlib
import sys
from pathlib import Path

RUN_IDS = ('43342252905', '43342287513', '43342291721')
FILES = ('first_callback_v9_original_clean.json',
         'first_callback_v9_self_consistency.json',
         'first_callback_v9_cpu_and_vendor_fingerprint.txt')


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def main():
    assert len(sys.argv) == 2, 'pass downloaded original run directory'
    root = Path(sys.argv[1]).resolve()
    target = Path(__file__).resolve().parent / 'source_runs'
    for run_id in RUN_IDS:
        src_dir = root / ('v9_run_' + run_id)
        assert src_dir.is_dir(), f'missing original {src_dir}'
        dest = target / run_id
        dest.mkdir(parents=True, exist_ok=True)
        lines = []
        for name in FILES:
            data = (src_dir / name).read_bytes()
            compressed = dest / (name + '.gz')
            with compressed.open('wb') as stream:
                with gzip.GzipFile(filename='', mode='wb', fileobj=stream,
                                   mtime=0, compresslevel=9) as encoded:
                    encoded.write(data)
            archive = compressed.read_bytes()
            assert gzip.decompress(archive) == data
            lines.append(sha(data) + '  ORIGINAL ' + name)
            lines.append(sha(archive) + '  GZIP_SHA256 ' + name + '.gz')
        (dest / 'ORIGINAL_AND_ARCHIVED_SHA256.txt').write_text('\n'.join(lines) + '\n')
        print(run_id, lines[0])


if __name__ == '__main__':
    main()
