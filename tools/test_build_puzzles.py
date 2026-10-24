"""Tests for build_puzzles.py.  Run from the project root:

    python3 -m unittest tools/test_build_puzzles.py
"""

import random
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import build_puzzles as b  # noqa: E402


class SliceTests(unittest.TestCase):
    def test_ratings_map_to_even_slices(self):
        self.assertEqual(b.slice_of(900, (900, 1400), 10), 0)
        self.assertEqual(b.slice_of(949, (900, 1400), 10), 0)
        self.assertEqual(b.slice_of(950, (900, 1400), 10), 1)
        self.assertEqual(b.slice_of(1399, (900, 1400), 10), 9)

    def test_outside_the_window_is_dropped(self):
        self.assertIsNone(b.slice_of(899, (900, 1400), 10))
        self.assertIsNone(b.slice_of(1400, (900, 1400), 10))


class PuzzleTests(unittest.TestCase):
    # Lichess puzzle 00008: the first move is the opponent's.
    ENTRY = (
        "00008",
        "r6k/pp2r2p/4Rp1Q/3p4/8/1N1P2R1/PqP2bPP/7K b - - 0 24",
        "f2g3 e6e7 b2b1 b3c1 b1c1 h6c1".split(),
        1800,
        {"mate", "mateIn2"},
    )

    def test_the_setup_move_is_applied(self):
        board, solution = b.prepare(self.ENTRY[1], self.ENTRY[2])
        self.assertEqual(len(solution), 5)
        self.assertTrue(board.piece_at(b.chess.G3).symbol() == "b")
        self.assertEqual(board.turn, b.chess.WHITE)

    def test_an_illegal_line_is_rejected(self):
        self.assertIsNone(b.prepare(self.ENTRY[1], ["f2g3", "e6g8"]))

    def test_an_even_number_of_plies_is_rejected(self):
        entry = ("x", self.ENTRY[1], self.ENTRY[2][:-1], 1500, {"fork"})
        self.assertIsNone(b.to_puzzle(entry, "fork", 3, random.Random(1)))

    def test_a_mate_puzzle_must_end_in_checkmate(self):
        entry = ("x", self.ENTRY[1], self.ENTRY[2][:4], 1500, {"mateIn2"})
        self.assertIsNone(b.to_puzzle(entry, "mateIn2", 2, random.Random(1)))

    def test_the_output_has_the_fields_the_app_reads(self):
        entry = ("x", self.ENTRY[1], self.ENTRY[2], 1800, {"fork"})
        puzzle = b.to_puzzle(entry, "fork", 3, random.Random(1))
        self.assertEqual(set(puzzle), {"fen", "moves", "rating", "theme"})
        self.assertEqual(puzzle["moves"], self.ENTRY[2][1:])
        self.assertEqual(puzzle["theme"], "fork")


class AlternativeTests(unittest.TestCase):
    def test_every_other_mating_move_is_accepted(self):
        board = b.chess.Board("6k1/5ppp/8/8/8/8/5PPP/RR4K1 w - - 0 1")
        self.assertEqual(
            b.mating_alternatives(board, ["a1a8"]), [["b1b8"]]
        )

    def test_nothing_is_added_when_the_line_does_not_mate(self):
        board = b.chess.Board("6k1/5ppp/8/8/8/8/5PPP/RR4K1 w - - 0 1")
        self.assertEqual(b.mating_alternatives(board, ["a1a2"]), [])


if __name__ == "__main__":
    unittest.main()
