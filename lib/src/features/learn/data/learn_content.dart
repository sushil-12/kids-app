import 'package:flutter/foundation.dart';

@immutable
class DailyStory {
  const DailyStory({
    required this.title,
    required this.story,
    required this.moral,
    required this.emoji,
    required this.date,
  });

  final String title;
  final String story;
  final String moral;
  final String emoji;
  final String date;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'story': story,
        'moral': moral,
        'emoji': emoji,
        'date': date,
      };

  factory DailyStory.fromJson(Map<String, dynamic> j) => DailyStory(
        title: j['title'] as String,
        story: j['story'] as String,
        moral: j['moral'] as String,
        emoji: j['emoji'] as String,
        date: j['date'] as String? ?? '',
      );
}

@immutable
class AbcLesson {
  const AbcLesson({
    required this.letter,
    required this.word,
    required this.emoji,
    required this.phonics,
    required this.miniStory,
  });

  final String letter;
  final String word;
  final String emoji;
  final String phonics;
  final String miniStory;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'letter': letter,
        'word': word,
        'emoji': emoji,
        'phonics': phonics,
        'miniStory': miniStory,
      };

  factory AbcLesson.fromJson(Map<String, dynamic> j) => AbcLesson(
        letter: j['letter'] as String,
        word: j['word'] as String,
        emoji: j['emoji'] as String,
        phonics: j['phonics'] as String,
        miniStory: j['miniStory'] as String,
      );
}

@immutable
class KidsPoem {
  const KidsPoem({
    required this.title,
    required this.poem,
    required this.topic,
    required this.emoji,
  });

  final String title;
  final String poem;
  final String topic;
  final String emoji;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'poem': poem,
        'topic': topic,
        'emoji': emoji,
      };

  factory KidsPoem.fromJson(Map<String, dynamic> j) => KidsPoem(
        title: j['title'] as String,
        poem: j['poem'] as String,
        topic: j['topic'] as String? ?? '',
        emoji: j['emoji'] as String,
      );
}

/// Offline fallback content — always available, no API key needed.
abstract final class LearnFallbacks {
  static const DailyStory story = DailyStory(
    title: 'The Little Cloud',
    story: 'Once upon a time, a little cloud floated high in the sky. '
        'She wanted to make the world below smile. '
        'She puffed herself up and made funny shapes — a rabbit, a duck, a hat! '
        'The children below laughed and pointed up at her. '
        'The cloud felt warm inside, even though clouds are usually cold. '
        'She learned that sharing joy is the best gift of all.',
    moral: 'Kindness and creativity can brighten anyone\'s day.',
    emoji: '☁️',
    date: 'offline',
  );

  static const List<AbcLesson> abcLessons = <AbcLesson>[
    AbcLesson(letter: 'A', word: 'Apple', emoji: '🍎', phonics: 'A says /æ/ — like in "and"', miniStory: 'Amy the Apple lived on a tall tree. She was round, red, and loved by all the bees!'),
    AbcLesson(letter: 'B', word: 'Ball', emoji: '⚽', phonics: 'B says /b/ — like in "big"', miniStory: 'Bobby the Ball liked to bounce all day. He rolled down the hill in the most fun way!'),
    AbcLesson(letter: 'C', word: 'Cat', emoji: '🐱', phonics: 'C says /k/ — like in "cup"', miniStory: 'Clara the Cat loved to curl and nap. She purred so loudly — just like a clap!'),
    AbcLesson(letter: 'D', word: 'Duck', emoji: '🦆', phonics: 'D says /d/ — like in "dog"', miniStory: 'Danny the Duck said quack all day. He splashed in puddles and swam away!'),
    AbcLesson(letter: 'E', word: 'Elephant', emoji: '🐘', phonics: 'E says /ɛ/ — like in "egg"', miniStory: 'Ella the Elephant had ears so wide. She fanned her friends when they played outside!'),
    AbcLesson(letter: 'F', word: 'Fish', emoji: '🐟', phonics: 'F says /f/ — like in "fun"', miniStory: 'Finn the Fish swam in the sea so blue. He made a wish and it came true!'),
    AbcLesson(letter: 'G', word: 'Giraffe', emoji: '🦒', phonics: 'G says /g/ — like in "go"', miniStory: 'Greta the Giraffe reached the tallest tree. She shared her leaves for everyone to see!'),
    AbcLesson(letter: 'H', word: 'House', emoji: '🏠', phonics: 'H says /h/ — like in "hop"', miniStory: 'Harry the House had a bright red door. Every friend was welcome — he had room for more!'),
    AbcLesson(letter: 'I', word: 'Ice Cream', emoji: '🍦', phonics: 'I says /ɪ/ — like in "it"', miniStory: 'Ivy the Ice Cream was cold and sweet. She was everyone\'s favourite summer treat!'),
    AbcLesson(letter: 'J', word: 'Jellyfish', emoji: '🪼', phonics: 'J says /dʒ/ — like in "jump"', miniStory: 'Jojo the Jellyfish glowed in the night. She lit up the ocean with colourful light!'),
    AbcLesson(letter: 'K', word: 'Kite', emoji: '🪁', phonics: 'K says /k/ — like in "kit"', miniStory: 'Kira the Kite flew way up high. She danced and twirled in the bright blue sky!'),
    AbcLesson(letter: 'L', word: 'Lion', emoji: '🦁', phonics: 'L says /l/ — like in "lap"', miniStory: 'Leo the Lion had a mane of gold. He was brave and kind and wonderfully bold!'),
    AbcLesson(letter: 'M', word: 'Moon', emoji: '🌙', phonics: 'M says /m/ — like in "map"', miniStory: 'Mia the Moon glowed soft and bright. She watched over children throughout the night!'),
    AbcLesson(letter: 'N', word: 'Nest', emoji: '🪺', phonics: 'N says /n/ — like in "nap"', miniStory: 'Nina the Nest was cosy and warm. She kept baby birds safe in every storm!'),
    AbcLesson(letter: 'O', word: 'Owl', emoji: '🦉', phonics: 'O says /ɒ/ — like in "on"', miniStory: 'Oliver the Owl was wise as could be. He answered questions from behind his tree!'),
    AbcLesson(letter: 'P', word: 'Penguin', emoji: '🐧', phonics: 'P says /p/ — like in "pat"', miniStory: 'Penny the Penguin waddled with glee. She slid on the ice — one, two, three!'),
    AbcLesson(letter: 'Q', word: 'Queen', emoji: '👑', phonics: 'Q says /kw/ — like in "quick"', miniStory: 'Quinn the Queen was kind and fair. She shared her crown for all to wear!'),
    AbcLesson(letter: 'R', word: 'Rainbow', emoji: '🌈', phonics: 'R says /r/ — like in "run"', miniStory: 'Ruby the Rainbow appeared after rain. She coloured the sky again and again!'),
    AbcLesson(letter: 'S', word: 'Sun', emoji: '☀️', phonics: 'S says /s/ — like in "sit"', miniStory: 'Sunny the Sun rose bright and gold. She warmed the world — brave and bold!'),
    AbcLesson(letter: 'T', word: 'Tiger', emoji: '🐯', phonics: 'T says /t/ — like in "top"', miniStory: 'Tara the Tiger had stripes so bright. She loved to play from morning to night!'),
    AbcLesson(letter: 'U', word: 'Umbrella', emoji: '☂️', phonics: 'U says /ʌ/ — like in "up"', miniStory: 'Uma the Umbrella kept everyone dry. She danced in the rain under a stormy sky!'),
    AbcLesson(letter: 'V', word: 'Violet', emoji: '🌸', phonics: 'V says /v/ — like in "van"', miniStory: 'Vera the Violet grew in the park. She bloomed in the morning and glowed in the dark!'),
    AbcLesson(letter: 'W', word: 'Whale', emoji: '🐋', phonics: 'W says /w/ — like in "wet"', miniStory: 'Wally the Whale sang songs so sweet. His music made every ocean wave beat!'),
    AbcLesson(letter: 'X', word: 'Xylophone', emoji: '🎵', phonics: 'X says /z/ — like in "xylophone"', miniStory: 'Xena the Xylophone rang ding and dong. Everyone danced along to her song!'),
    AbcLesson(letter: 'Y', word: 'Yak', emoji: '🐃', phonics: 'Y says /j/ — like in "yes"', miniStory: 'Yogi the Yak climbed mountains so tall. He yelled "yippee!" and never did fall!'),
    AbcLesson(letter: 'Z', word: 'Zebra', emoji: '🦓', phonics: 'Z says /z/ — like in "zip"', miniStory: 'Zara the Zebra had stripes black and white. She zoomed through the grasslands — what a sight!'),
  ];

  static const List<KidsPoem> poems = <KidsPoem>[
    KidsPoem(
      title: 'The Busy Bee',
      poem: 'The little bee flies from flower to flower,\nSipping sweet nectar hour by hour.\nBuzzing and humming a merry song,\nCarrying pollen the whole day long.',
      topic: 'Animals',
      emoji: '🐝',
    ),
    KidsPoem(
      title: 'The Rainy Day',
      poem: 'Pitter-patter, drops of rain,\nDancing down the windowpane.\nPuddles form on every street,\nSplashing under jumping feet.',
      topic: 'Seasons',
      emoji: '🌧️',
    ),
    KidsPoem(
      title: 'Counting Stars',
      poem: 'One star, two stars, shining bright,\nThree and four light up the night.\nFive and six and seven glow,\nEight and nine put on a show.',
      topic: 'Numbers',
      emoji: '⭐',
    ),
    KidsPoem(
      title: 'Rainbow Colors',
      poem: 'Red and orange, yellow too,\nThen comes green and after blue.\nIndigo and violet shine,\nSeven colors — all divine!',
      topic: 'Colors',
      emoji: '🌈',
    ),
    KidsPoem(
      title: 'My Garden',
      poem: 'Little seeds beneath the ground,\nWaking up without a sound.\nPushing through the muddy earth,\nSpring has given them new birth.',
      topic: 'Nature',
      emoji: '🌱',
    ),
  ];
}
