#!/usr/bin/env python3
"""Builds puzzle levels 2-5 for Küşt from the free Lichess puzzle database.

The database (CC0, about 5 million rated and tagged puzzles) is
https://database.lichess.org/#puzzles. Each row has a start position, a
solution line and theme tags such as "fork", "pin" or "mateIn2".

For every level this script
  1. picks the puzzles with the level's theme, a good rating deviation and
     plenty of plays and likes,
  2. spreads them over the level's rating window so the level gets harder as
     you go (one puzzle per rating slice),
  3. re-checks every puzzle with python-chess (legal moves, real checkmate
     for mate puzzles) and drops any that fail,
  4. adds every other checkmating move as an accepted answer, so "any mate
     counts" like on Lichess,
  5. writes assets/puzzles/levelN.json in the format the app loads.

Needs:  pip install chess      and the zstd command line tool (sudo apt install zstd)

    python3 tools/build_puzzles.py --db ~/Downloads/lichess_db_puzzle.csv.zst
"""

import argparse
import csv
import io
import json
import random
import subprocess
import sys
from pathlib import Path

try:
    import chess
except ImportError:  # pragma: no cover - friendly message for the user
    sys.exit("python-chess is missing. Run:  pip install chess")

# level -> (Lichess theme tag, theme name the app shows, rating window)
LEVELS = {
    2: ("mateIn2", "mateIn2", (900, 1400)),
    3: ("fork", "fork", (1000, 1500)),
    4: ("pin", "pin", (1100, 1600)),
    5: ("endgame", "endgame", (1200, 1700)),
}

# Themes that make a puzzle confusing for a casual player.
AVOID = {"veryLong", "long", "mix", "quietMove", "zugzwang", "enPassant"}

SLOT_RESERVOIR = 30  # candidates kept per rating slice while streaming


def open_rows(path):
    """Yields the CSV rows of the database, decompressing .zst on the fly."""
    if path.suffix == ".zst":
        proc = subprocess.Popen(
            ["zstd", "-dc", str(path)], stdout=subprocess.PIPE, text=True
        )
        yield from csv.DictReader(proc.stdout)
        if proc.wait() != 0:
            print(
                "\nWARNING: zstd could not read the whole file. The download is "
                "probably incomplete; download it again.\n",
                file=sys.stderr,
            )
    else:
        with open(path, newline="") as handle:
            yield from csv.DictReader(handle)


def slice_of(rating, window, slices):
    low, high = window
    if rating < low or rating >= high:
        return None
    return min(slices - 1, (rating - low) * slices // (high - low))


def gather(args):
    """One pass over the database, keeping a few candidates per rating slice."""
    rng = random.Random(args.seed)
    pools = {lv: [[] for _ in range(args.per_level)] for lv in LEVELS}
    seen = {lv: [0] * args.per_level for lv in LEVELS}
    rows = 0

    for row in open_rows(Path(args.db)):
        rows += 1
        if rows % 500000 == 0:
            print(f"  read {rows:,} puzzles...", flush=True)
        try:
            rating = int(row["Rating"])
            deviation = int(row["RatingDeviation"])
            popularity = int(row["Popularity"])
            plays = int(row["NbPlays"])
        except (KeyError, ValueError, TypeError):  # also a row cut off mid-line
            continue
        if deviation > args.max_deviation or popularity < args.min_popularity:
            continue
        if plays < args.min_plays:
            continue

        if not (row.get("Themes") and row.get("Moves") and row.get("FEN")):
            continue
        themes = set(row["Themes"].split())
        if themes & AVOID:
            continue
        moves = row["Moves"].split()
        # moves[0] is the opponent's move that creates the puzzle.
        if len(moves) - 1 > args.max_plies:
            continue

        for level, (tag, _name, window) in LEVELS.items():
            if tag not in themes:
                continue
            index = slice_of(rating, window, args.per_level)
            if index is None:
                continue
            # Reservoir sampling: every candidate of a slice is equally likely
            # to be kept, whatever the order of the file.
            seen[level][index] += 1
            pool = pools[level][index]
            entry = (row["PuzzleId"], row["FEN"], moves, rating, themes)
            if len(pool) < SLOT_RESERVOIR:
                pool.append(entry)
            else:
                j = rng.randrange(seen[level][index])
                if j < SLOT_RESERVOIR:
                    pool[j] = entry

    print(f"read {rows:,} puzzles in total")
    return pools


def prepare(fen, moves):
    """Applies the opponent's setup move. Returns (board, solution) or None."""
    board = chess.Board(fen)
    try:
        board.push_uci(moves[0])
    except ValueError:
        return None
    solution = moves[1:]
    check = board.copy()
    for uci in solution:
        try:
            check.push_uci(uci)
        except ValueError:
            return None
    return board, solution


def mating_alternatives(board, solution):
    """Other lines that end in checkmate with a different final move."""
    probe = board.copy()
    for uci in solution[:-1]:
        probe.push_uci(uci)
    final = probe.copy()
    final.push_uci(solution[-1])
    if not final.is_checkmate():
        return []
    lines = []
    for move in probe.legal_moves:
        if move.uci() == solution[-1]:
            continue
        probe.push(move)
        mate = probe.is_checkmate()
        probe.pop()
        if mate:
            lines.append(solution[:-1] + [move.uci()])
    return lines


def to_puzzle(entry, theme_name, level, rng):
    puzzle_id, fen, moves, rating, themes = entry
    prepared = prepare(fen, moves)
    if prepared is None:
        return None
    board, solution = prepared
    if not solution or len(solution) % 2 == 0:
        # The solver makes the first and the last move: an odd number of plies.
        return None
    if theme_name.startswith("mateIn"):
        end = board.copy()
        for uci in solution:
            end.push_uci(uci)
        if not end.is_checkmate():
            return None
    out = {
        "fen": board.fen(),
        "moves": solution,
        "rating": rating,
        "theme": theme_name,
    }
    alternatives = mating_alternatives(board, solution)
    if alternatives:
        out["alternatives"] = alternatives
    return out


def build_level(level, pool, args, rng):
    _tag, theme_name, window = LEVELS[level]
    chosen = []
    leftovers = []
    for candidates in pool:
        rng.shuffle(candidates)
        picked = None
        for entry in candidates:
            puzzle = to_puzzle(entry, theme_name, level, rng)
            if puzzle is None:
                continue
            if picked is None:
                picked = puzzle
            else:
                leftovers.append(puzzle)
        if picked is not None:
            chosen.append(picked)
    # Empty slices are topped up from the spare puzzles of the other slices.
    rng.shuffle(leftovers)
    while len(chosen) < args.per_level and leftovers:
        chosen.append(leftovers.pop())

    chosen.sort(key=lambda p: p["rating"])
    for number, puzzle in enumerate(chosen, start=1):
        puzzle["id"] = f"l{level}-{number:03d}"
    return {"level": level, "puzzles": chosen}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--db", required=True, help="lichess_db_puzzle.csv or .csv.zst")
    parser.add_argument("--out-dir", default="assets/puzzles")
    parser.add_argument("--levels", default="2,3,4,5", help="e.g. 2,3")
    parser.add_argument("--per-level", type=int, default=20)
    parser.add_argument("--max-plies", type=int, default=5, help="solver moves x2 - 1")
    parser.add_argument("--min-popularity", type=int, default=90)
    parser.add_argument("--min-plays", type=int, default=1000)
    parser.add_argument("--max-deviation", type=int, default=90)
    parser.add_argument("--seed", type=int, default=7)
    args = parser.parse_args()

    wanted = [int(x) for x in args.levels.split(",") if x.strip()]
    for level in wanted:
        if level not in LEVELS:
            sys.exit(f"unknown level {level}; choose from {sorted(LEVELS)}")
    for level in list(LEVELS):
        if level not in wanted:
            del LEVELS[level]

    print("reading the database (a minute or two)...")
    pools = gather(args)

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    rng = random.Random(args.seed)
    for level in sorted(LEVELS):
        data = build_level(level, pools[level], args, rng)
        count = len(data["puzzles"])
        path = out_dir / f"level{level}.json"
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(data, handle, indent=2, ensure_ascii=False)
        ratings = [p["rating"] for p in data["puzzles"]]
        span = f"{min(ratings)}-{max(ratings)}" if ratings else "none"
        note = "" if count >= args.per_level else "  <- fewer than wanted, lower --min-plays"
        print(f"level {level} ({LEVELS[level][1]}): {count} puzzles, rating {span} -> {path}{note}")


if __name__ == "__main__":
    main()
