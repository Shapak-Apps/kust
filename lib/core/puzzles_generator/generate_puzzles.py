import argparse
import json
import random
import time

import chess
import chess.engine

MATE_VALUE = 100000
MIN_BEST_CP = 250
MIN_GAP_CP = 180
MIN_FORCED_GAP_CP = 150
MAX_USER_MOVES = 3


def cp_of(rel):
    if rel.is_mate():
        m = rel.mate()
        return MATE_VALUE - abs(m) * 10 if m > 0 else -MATE_VALUE + abs(m) * 10
    return rel.score(mate_score=MATE_VALUE)


def analyse_top(engine, board, seconds, lines):
    infos = engine.analyse(board, chess.engine.Limit(time=seconds), multipv=lines)
    results = []
    for info in infos:
        pv = info.get("pv")
        if not pv:
            continue
        results.append((pv[0], info["score"].relative))
    return results


def forced_gap(results):
    if len(results) < 2:
        return MATE_VALUE
    return cp_of(results[0][1]) - cp_of(results[1][1])


def build_line(engine, start):
    board = start.copy()
    line = []
    user_moves = 0
    while not board.is_game_over():
        if board.turn == start.turn:
            if user_moves >= MAX_USER_MOVES:
                return None
            results = analyse_top(engine, board, 0.3, 2)
            if not results:
                return None
            move, rel = results[0]
            value = cp_of(rel)
            if rel.is_mate() and rel.mate() <= 0:
                return None
            if user_moves > 0 and forced_gap(results) < MIN_FORCED_GAP_CP and not rel.is_mate():
                return None
            line.append(move.uci())
            board.push(move)
            user_moves += 1
            if board.is_checkmate():
                return line, user_moves, "mate"
        else:
            results = analyse_top(engine, board, 0.3, 2)
            if not results:
                return None
            if forced_gap(results) < MIN_FORCED_GAP_CP:
                return None
            move = results[0][0]
            line.append(move.uci())
            board.push(move)
            if board.is_checkmate():
                return None
    if user_moves == 0:
        return None
    last = analyse_top(engine, board, 0.3, 1)
    if last and cp_of(last[0][1]) >= 500 and user_moves >= 1 and board.turn == start.turn:
        return line, user_moves, "material"
    return None


def rating_for(kind, user_moves):
    if kind == "mate":
        return {1: 800, 2: 1000, 3: 1200}.get(user_moves, 1200)
    return 1000 + 100 * (user_moves - 1)


def theme_for(kind, user_moves):
    if kind == "mate":
        return f"mateIn{user_moves}"
    return "winMaterial"


def candidate_from(engine, board):
    results = analyse_top(engine, board, 0.25, 2)
    if len(results) < 2:
        return None
    best_rel = results[0][1]
    best_cp = cp_of(best_rel)
    if best_rel.is_mate():
        if best_rel.mate() <= 0:
            return None
    elif best_cp < MIN_BEST_CP:
        return None
    if forced_gap(results) < MIN_GAP_CP:
        return None
    return build_line(engine, board)


def mate_in_one(board):
    for move in board.legal_moves:
        board.push(move)
        mate = board.is_checkmate()
        board.pop()
        if mate:
            return move
    return None


def random_opening(board, plies, rng):
    for _ in range(plies):
        if board.is_game_over():
            break
        board.push(rng.choice(list(board.legal_moves)))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--engine", default="/tmp/sf/usr/games/stockfish")
    parser.add_argument("--out", default="assets/puzzles/level1.json")
    parser.add_argument("--target", type=int, default=40)
    parser.add_argument("--seconds", type=int, default=240)
    parser.add_argument("--seed", type=int, default=7)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    engine = chess.engine.SimpleEngine.popen_uci(args.engine)
    engine.configure({"Threads": 2, "Hash": 64})

    seen = set()
    puzzles = []
    started = time.time()

    while len(puzzles) < args.target and time.time() - started < args.seconds:
        board = chess.Board()
        random_opening(board, rng.randint(2, 6), rng)
        for _ in range(60):
            if board.is_game_over() or time.time() - started > args.seconds:
                break
            if board.legal_moves.count() >= 2:
                key = " ".join(board.fen().split()[:4])
                if key not in seen:
                    seen.add(key)
                    one = mate_in_one(board)
                    if one:
                        puzzles.append({
                            "fen": board.fen(),
                            "moves": [one.uci()],
                            "rating": 800,
                            "theme": "mateIn1",
                        })
                        print(f"found {len(puzzles)}: mateIn1 {board.fen()}", flush=True)
                        if len(puzzles) >= args.target:
                            break
                    found = None if one else candidate_from(engine, board)
                    if found:
                        line, user_moves, kind = found
                        puzzles.append({
                            "fen": board.fen(),
                            "moves": line,
                            "rating": rating_for(kind, user_moves),
                            "theme": theme_for(kind, user_moves),
                        })
                        print(f"found {len(puzzles)}: {theme_for(kind, user_moves)} {board.fen()}", flush=True)
                        if len(puzzles) >= args.target:
                            break
            if rng.random() < 0.5:
                board.push(rng.choice(list(board.legal_moves)))
            else:
                board.push(engine.play(board, chess.engine.Limit(time=0.03)).move)

    engine.quit()

    puzzles.sort(key=lambda p: p["rating"])
    for index, puzzle in enumerate(puzzles, start=1):
        puzzle["id"] = f"l1-{index:03d}"

    with open(args.out, "w") as handle:
        json.dump({"level": 1, "puzzles": puzzles}, handle, indent=2)
    print(f"wrote {len(puzzles)} puzzles to {args.out}")


if __name__ == "__main__":
    main()
