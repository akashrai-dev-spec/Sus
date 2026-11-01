import 'dart:math' as math;

class NameGenerator {
  NameGenerator._();

  static const List<String> colors = [
    '#9A0F28',
    '#C2410C',
    '#A16207',
    '#4D7C0F',
    '#0F766E',
    '#1D4ED8',
    '#6D28D9',
    '#BE185D',
  ];

  static const List<String> adjectives = [
    'Sneaky',
    'Quiet',
    'Rusty',
    'Lucky',
    'Sleepy',
    'Jumpy',
    'Bold',
    'Cosmic',
    'Salty',
    'Wily',
    'Brave',
    'Swift',
    'Clever',
    'Fierce',
    'Noble',
    'Shy',
    'Shadow',
    'Mighty',
    'Zesty',
    'Chill',
    'Breezy',
    'Golden',
    'Silent',
    'Daring',
    'Spicy',
    'Frosty',
    'Hyper',
    'Curious',
    'Sunny',
    'Electric',
  ];

  static const List<String> animals = [
    'Otter',
    'Fox',
    'Panda',
    'Moth',
    'Crow',
    'Gecko',
    'Lynx',
    'Yak',
    'Newt',
    'Hare',
    'Falcon',
    'Badger',
    'Wolf',
    'Raven',
    'Koala',
    'Tiger',
    'Hawk',
    'Viper',
    'Beaver',
    'Ferret',
    'Cheetah',
    'Panther',
    'Owl',
    'Bison',
    'Eagle',
    'Dolphin',
    'Bear',
    'Penguin',
    'Jaguar',
    'Raccoon',
  ];

  static String generateRandomName() {
    final rand = math.Random();
    final adj = adjectives[rand.nextInt(adjectives.length)];
    final ani = animals[rand.nextInt(animals.length)];
    final num = 10 + rand.nextInt(90);
    return '$adj $ani $num';
  }

  static String getRandomColor() {
    final rand = math.Random();
    return colors[rand.nextInt(colors.length)];
  }
}
