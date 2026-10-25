/// The piece designs the board can be drawn with. Picked in settings and
/// used by every board in the app. The shaded sets are drawn by
/// `tools/pieces/make_pieces.py`.
enum PieceSet {
  classic('Classic', ''),
  shaded('Shaded', 'shaded/'),
  neo('Neo', 'neo/'),
  modern('Modern', 'modern/');

  const PieceSet(this.label, this._folder);

  final String label;
  final String _folder;

  /// The pieces in use when nothing is saved.
  static const PieceSet defaultSet = PieceSet.shaded;

  /// The set saved under [name], or the default for an unknown name.
  static PieceSet fromName(String? name) => PieceSet.values.firstWhere(
    (s) => s.name == name,
    orElse: () => defaultSet,
  );

  /// The asset of one piece: [color] is `w` or `b`, [role] one of `KQRBNP`.
  String asset(String color, String role) =>
      'assets/pieces/$_folder$color$role.svg';

  /// Every piece of the set.
  List<String> get assets => [
    for (final color in const ['w', 'b'])
      for (final role in const ['K', 'Q', 'R', 'B', 'N', 'P'])
        asset(color, role),
  ];
}
