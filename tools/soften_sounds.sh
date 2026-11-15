#!/bin/bash
# Softens the app's sounds, from the originals in tools/sounds_src into
# assets/sounds: highs rounded off (the click is what tires the ear in fast
# games), sharp peaks tamed, a tiny fade at both ends, and every sound brought
# to a calm, even level. Run again after changing an original.
set -e
cd "$(dirname "$0")/.."
src=tools/sounds_src
out=assets/sounds
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Target loudness (mean dB): moves quiet, results a little fuller.
target_for() {
  case "$1" in
    game-*|correct.wav) echo -30 ;;
    tenseconds.wav) echo -31 ;;
    *) echo -35 ;;
  esac
}

for f in "$src"/*.wav; do
  name=$(basename "$f")
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  fade_out=$(python3 -c "print(max(0.0, $dur - 0.05))")
  ffmpeg -hide_banner -loglevel error -y -i "$f" -af \
"highpass=f=90,lowpass=f=6500,highshelf=f=3500:g=-5,\
acompressor=threshold=-20dB:ratio=3:attack=2:release=80:makeup=1,\
afade=t=in:d=0.004,afade=t=out:st=$fade_out:d=0.05" \
    -ar 44100 -ac 1 -c:a pcm_s16le "$tmp/$name"
  mean=$(ffmpeg -hide_banner -i "$tmp/$name" -af volumedetect -f null - 2>&1 |
    awk '/mean_volume/ {print $5}')
  peak=$(ffmpeg -hide_banner -i "$tmp/$name" -af volumedetect -f null - 2>&1 |
    awk '/max_volume/ {print $5}')
  # Gain to reach the target, but never past a peak of -6 dB.
  gain=$(python3 -c "t=$(target_for "$name"); print(round(min(t - $mean, -6 - $peak), 2))")
  ffmpeg -hide_banner -loglevel error -y -i "$tmp/$name" -af "volume=${gain}dB" \
    -c:a pcm_s16le "$out/$name"
  echo "$name: gain ${gain} dB"
done
