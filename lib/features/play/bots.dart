class Bot {
  final String id;
  final String name;
  final int elo;
  final String imagePath;
  final bool isTkm;

  const Bot({
    required this.id,
    required this.name,
    required this.elo,
    required this.imagePath,
    this.isTkm = false,
  });
}

const List<Bot> kInternationalBots = [
  Bot(
    id: 'elizabeth',
    name: 'Elizabeth',
    elo: 600,
    imagePath: 'assets/bots/Elizabeth.webp',
  ),
  Bot(id: 'mark', name: 'Mark', elo: 700, imagePath: 'assets/bots/Mark.webp'),
  Bot(id: 'apex', name: 'Apex', elo: 800, imagePath: 'assets/bots/Apex.webp'),
  Bot(id: 'karl', name: 'Karl', elo: 1000, imagePath: 'assets/bots/Karl.webp'),
  Bot(id: 'maya', name: 'Maya', elo: 1200, imagePath: 'assets/bots/Maya.webp'),
  Bot(id: 'yura', name: 'Yura', elo: 1400, imagePath: 'assets/bots/Yura.webp'),
];

const List<Bot> kTkmBots = [
  Bot(
    id: 'bahar',
    name: 'Bahar',
    elo: 400,
    imagePath: 'assets/bots/Bahar.webp',
    isTkm: true,
  ),
  Bot(
    id: 'enejan',
    name: 'Enejan',
    elo: 1000,
    imagePath: 'assets/bots/Enejan.webp',
    isTkm: true,
  ),
  Bot(
    id: 'berdi',
    name: 'Berdi',
    elo: 2000,
    imagePath: 'assets/bots/Berdi.webp',
    isTkm: true,
  ),
];
