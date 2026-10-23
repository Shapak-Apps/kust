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
    imagePath: 'assets/bots/Elizabeth.png',
  ),
  Bot(id: 'mark', name: 'Mark', elo: 700, imagePath: 'assets/bots/Mark.png'),
  Bot(id: 'apex', name: 'Apex', elo: 800, imagePath: 'assets/bots/Apex.png'),
  Bot(id: 'karl', name: 'Karl', elo: 1000, imagePath: 'assets/bots/Karl.png'),
  Bot(id: 'maya', name: 'Maya', elo: 1200, imagePath: 'assets/bots/Maya.png'),
  Bot(id: 'yura', name: 'Yura', elo: 1400, imagePath: 'assets/bots/Yura.png'),
];

const List<Bot> kTkmBots = [
  Bot(
    id: 'bahar',
    name: 'Bahar',
    elo: 400,
    imagePath: 'assets/bots/Bahar.png',
    isTkm: true,
  ),
  Bot(
    id: 'enejan',
    name: 'Enejan',
    elo: 1000,
    imagePath: 'assets/bots/Enejan.png',
    isTkm: true,
  ),
  Bot(
    id: 'berdi',
    name: 'Berdi',
    elo: 2000,
    imagePath: 'assets/bots/Berdi.png',
    isTkm: true,
  ),
];
