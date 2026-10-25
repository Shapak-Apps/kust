/// The piece designs the board can be drawn with. Picked in settings and
/// used by every board in the app. Shaded is drawn by
/// `tools/pieces/make_pieces.py`; Graphite and Brushed are painted by
/// `tools/pieces/textured.html`, as images because their grain cannot be
/// drawn as a vector.
enum PieceSet {
  classic('Classic', ''),
  shaded('Shaded', 'shaded/'),
  graphite('Graphite', 'graphite/', textured: true),
  brushed('Brushed', 'brushed/', textured: true);

  const PieceSet(this.label, this._folder, {this.textured = false});

  final String label;
  final String _folder;

  /// Whether the pieces are images rather than vectors.
  final bool textured;

  /// The pieces in use when nothing is saved.
  static const PieceSet defaultSet = PieceSet.shaded;

  /// The set saved under [name], or the default for an unknown name.
  static PieceSet fromName(String? name) => PieceSet.values.firstWhere(
    (s) => s.name == name,
    orElse: () => defaultSet,
  );

  /// The asset of one piece: [color] is `w` or `b`, [role] one of `KQRBNP`.
  String asset(String color, String role) =>
      'assets/pieces/$_folder$color$role.${textured ? 'webp' : 'svg'}';

  /// Every piece of the set.
  List<String> get assets => [
    for (final color in const ['w', 'b'])
      for (final role in const ['K', 'Q', 'R', 'B', 'N', 'P'])
        asset(color, role),
  ];
}
