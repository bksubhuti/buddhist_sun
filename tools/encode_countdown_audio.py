#!/usr/bin/env python3
"""Encode a 2-hour countdown recording into the small m4a the app ships.

The recordings are two hours of silence with 14 short phrases (see
assets/text/announce-script.txt). The gaps carry a faint noise floor, which an
AAC encoder spends full bitrate on. This script finds the phrases, makes
everything between them digital silence, and encodes speech at a good bitrate,
so the silence costs almost nothing.

Usage:
  python3 tools/encode_countdown_audio.py INPUT.mp3 OUTPUT.m4a [--bitrate 48k]

Requires ffmpeg on the PATH.
"""

import argparse
import re
import subprocess
import sys

EXPECTED_PHRASES = 14
# Phrase start times (seconds into the file): 60, 50, 40, 30, 20, 10, 8, 6, 5,
# 4, 3, 2, 1 minutes left, then "time has passed" just before the 2 hour mark.
EXPECTED_STARTS = [7200 - m * 60 for m in (60, 50, 40, 30, 20, 10, 8, 6, 5, 4, 3, 2, 1)] + [7198]


def speech_intervals(path, noise_db, min_silence):
    out = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af",
         f"silencedetect=noise={noise_db}dB:d={min_silence}", "-f", "null", "-"],
        capture_output=True, text=True).stderr
    h, m, s = re.search(r"Duration: (\d+):(\d+):([\d.]+)", out).groups()
    duration = int(h) * 3600 + int(m) * 60 + float(s)
    starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", out)]
    ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", out)]
    # Speech runs from each silence end to the next silence start.
    if len(starts) == len(ends) + 1:  # file ends in silence that never closes
        ends.append(duration)
    intervals = []
    for i, end in enumerate(ends):
        nxt = starts[i + 1] if i + 1 < len(starts) else duration
        if nxt > end:
            intervals.append((end, nxt))
    if starts and starts[0] > 0:
        intervals.insert(0, (0.0, starts[0]))
    return intervals, duration


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("input")
    p.add_argument("output")
    p.add_argument("--bitrate", default="48k")
    p.add_argument("--noise-db", type=float, default=-45)
    p.add_argument("--min-silence", type=float, default=2.0)
    p.add_argument("--pad", type=float, default=0.3,
                   help="seconds kept around each phrase")
    args = p.parse_args()

    intervals, duration = speech_intervals(args.input, args.noise_db, args.min_silence)
    print(f"{len(intervals)} phrases found:")
    for (s, e) in intervals:
        print(f"  {s:8.1f}s  ({(7200 - s) / 60:5.1f} min left)  {e - s:4.1f}s long")
    if len(intervals) != EXPECTED_PHRASES:
        print(f"WARNING: expected {EXPECTED_PHRASES} phrases, found {len(intervals)}",
              file=sys.stderr)
    for s, _ in intervals:
        if min(abs(s - x) for x in EXPECTED_STARTS) > 10:
            print(f"WARNING: phrase at {s:.1f}s is not near an expected time",
                  file=sys.stderr)

    keep = "+".join(f"between(t,{max(0, s - args.pad):.3f},{e + args.pad:.3f})"
                    for s, e in intervals)
    gate = f"volume=0:enable='not({keep})'" if keep else "volume=0"
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-i", args.input, "-map_metadata", "-1",
         "-af", gate, "-ac", "1", "-c:a", "aac", "-b:a", args.bitrate, args.output],
        check=True)
    print(f"wrote {args.output}")


if __name__ == "__main__":
    main()
