class AppFont {
  const AppFont(this.id, this.label, this.family);

  final String id;
  final String label;
  final String family;

  static const customId = 'custom';

  static const bundled = <AppFont>[
    AppFont('inter', 'Inter', 'Inter'),
    AppFont('open_sans', 'Open Sans', 'OpenSans'),
    AppFont('quicksand', 'Quicksand', 'Quicksand'),
    AppFont('lora', 'Lora', 'Lora'),
    AppFont('jetbrains_mono', 'JetBrains Mono', 'JetBrainsMono'),
  ];

  static AppFont? byId(String? id) {
    for (final f in bundled) {
      if (f.id == id) return f;
    }
    return null;
  }
}
