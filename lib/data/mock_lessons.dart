import 'package:flutter/material.dart';

class MockPhrase {
  const MockPhrase({
    required this.id,
    required this.original,
    required this.translation,
    this.pronunciation,
  });

  final String id;
  final String original;
  final String translation;
  final String? pronunciation;
}

class MockLesson {
  const MockLesson({
    required this.id,
    required this.title,
    required this.icon,
    required this.phrases,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<MockPhrase> phrases;
}

const mockLessons = <MockLesson>[
  MockLesson(
    id: 'greetings',
    title: 'Greetings',
    icon: Icons.waving_hand_rounded,
    phrases: [
      MockPhrase(
        id: 'g1',
        original: 'Kumusta',
        translation: 'Hello',
        pronunciation: 'koo-MOOS-tah',
      ),
      MockPhrase(
        id: 'g2',
        original: 'Magandang umaga',
        translation: 'Good morning',
        pronunciation: 'mah-gan-DAHNG oo-MAH-gah',
      ),
      MockPhrase(
        id: 'g3',
        original: 'Magandang gabi',
        translation: 'Good evening',
        pronunciation: 'mah-gan-DAHNG gah-BEE',
      ),
      MockPhrase(
        id: 'g4',
        original: 'Kumusta ka?',
        translation: 'How are you?',
        pronunciation: 'koo-MOOS-tah kah',
      ),
    ],
  ),
  MockLesson(
    id: 'common',
    title: 'Common phrases',
    icon: Icons.chat_bubble_outline_rounded,
    phrases: [
      MockPhrase(
        id: 'c1',
        original: 'Pakiusap',
        translation: 'Please',
        pronunciation: 'pah-kee-OO-sahp',
      ),
      MockPhrase(
        id: 'c2',
        original: 'Salamat',
        translation: 'Thank you',
        pronunciation: 'sah-LAH-mat',
      ),
      MockPhrase(
        id: 'c3',
        original: 'Pasensya na',
        translation: "I'm sorry",
        pronunciation: 'pah-SEN-shah nah',
      ),
      MockPhrase(
        id: 'c4',
        original: 'Hindi ko maintindihan',
        translation: "I don't understand",
        pronunciation: 'hin-DEE koh mah-in-tin-DEE-han',
      ),
      MockPhrase(
        id: 'c5',
        original: 'Oo / Hindi',
        translation: 'Yes / No',
        pronunciation: 'OH-oh / hin-DEE',
      ),
    ],
  ),
  MockLesson(
    id: 'help',
    title: 'Asking for help',
    icon: Icons.help_outline_rounded,
    phrases: [
      MockPhrase(
        id: 'h1',
        original: 'Pwede mo ba akong tulungan?',
        translation: 'Can you help me?',
        pronunciation: 'PWEH-de moh bah ah-kong too-LOO-ngan',
      ),
      MockPhrase(
        id: 'h2',
        original: 'Nasaan ang...?',
        translation: 'Where is...?',
        pronunciation: 'nah-sah-AHN ahng',
      ),
      MockPhrase(
        id: 'h3',
        original: 'Naliligaw ako',
        translation: 'I am lost',
        pronunciation: 'nah-lee-lee-GAW ah-ko',
      ),
      MockPhrase(
        id: 'h4',
        original: 'Tawagan ang pulis',
        translation: 'Call the police',
        pronunciation: 'tah-WAH-gan ahng poo-LEES',
      ),
    ],
  ),
  MockLesson(
    id: 'food',
    title: 'Food / ordering',
    icon: Icons.restaurant_rounded,
    phrases: [
      MockPhrase(
        id: 'f1',
        original: 'Yung bill po',
        translation: 'The check, please',
        pronunciation: 'yoong beel poh',
      ),
      MockPhrase(
        id: 'f2',
        original: 'Mesa para sa dalawa',
        translation: 'A table for two',
        pronunciation: 'MEH-sah pah-rah sah dah-lah-WAH',
      ),
      MockPhrase(
        id: 'f3',
        original: 'Pakiabot po ng menu',
        translation: 'The menu, please',
        pronunciation: 'pah-kee-AH-bot poh nahng meh-NOO',
      ),
      MockPhrase(
        id: 'f4',
        original: 'Walang sibuyas',
        translation: 'Without onion',
        pronunciation: 'WAH-lang see-BOO-yahs',
      ),
    ],
  ),
];

MockLesson? findLessonById(String id) {
  for (final lesson in mockLessons) {
    if (lesson.id == id) return lesson;
  }
  return null;
}
