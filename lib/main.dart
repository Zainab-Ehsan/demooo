import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed') || details.exceptionAsString().contains('overflowed by')) {
      debugPrint('Layout overflow auto-handled: ${details.exceptionAsString()}');
      return;
    }
    FlutterError.presentError(details);
  };
  runApp(const TawafApp());
}

class TawafApp extends StatelessWidget {
  const TawafApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B5E4B),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'Tawaf Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF7F4EC),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFFF7F4EC),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Domain model: Tawaf landmarks and supplications
// ---------------------------------------------------------------------------

const int kTotalLaps = 7;

class Landmark {
  const Landmark({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.description,
    required this.duaTitle,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.note,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final String description;
  final String duaTitle;
  final String arabic;
  final String transliteration;
  final String translation;
  final String note;
}

/// Landmarks in the order a pilgrim meets them during Tawaf
/// (counter-clockwise around the Kaaba, starting at the Black Stone).
/// They are spaced evenly: landmark i sits at lap fraction i / length.
const List<Landmark> kLandmarks = [
  Landmark(
    id: 'black_stone',
    nameEn: 'Hajr-e-Aswad (Black Stone)',
    nameAr: 'الحجر الأسود',
    description:
        'The starting and ending point of every circuit. Face the Black Stone and, '
        'if you can do so without harming others, touch or kiss it. Otherwise '
        'point toward it with your right hand (istilam) and say the Takbir.',
    duaTitle: 'Takbir at the Black Stone',
    arabic: 'بِسْمِ اللهِ وَاللهُ أَكْبَرُ',
    transliteration: "Bismillahi wallahu akbar",
    translation: 'In the name of Allah, and Allah is the Greatest.',
    note: 'Repeat this each time you pass the Black Stone.',
  ),
  Landmark(
    id: 'multazam',
    nameEn: 'Multazam & Kaaba Door',
    nameAr: 'الملتزم وباب الكعبة',
    description:
        'The wall between the Black Stone and the door of the Kaaba. Maqam '
        'Ibrahim is also in view on this side. In a crowd it is usually not '
        'possible to stop here, so make your dua while walking.',
    duaTitle: 'Dua of Ibrahim and Ismail',
    arabic: 'رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنتَ السَّمِيعُ الْعَلِيمُ',
    transliteration:
        "Rabbana taqabbal minna innaka antas-Sami'ul-'Alim",
    translation:
        'Our Lord, accept this from us. You are the All-Hearing, the All-Knowing. (Quran 2:127)',
    note: 'You may also make any personal dua in your own language.',
  ),
  Landmark(
    id: 'rukn_iraqi',
    nameEn: 'Rukn Iraqi',
    nameAr: 'الركن العراقي',
    description:
        'The northern corner of the Kaaba, after the door side. There is no '
        'ritual touching of this corner. Keep walking and remember Allah.',
    duaTitle: 'Seeking refuge',
    arabic:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الشَّكِّ وَالشِّرْكِ وَالشِّقَاقِ وَالنِّفَاقِ وَسُوءِ الْأَخْلَاقِ',
    transliteration:
        "Allahumma inni a'udhu bika minash-shakki wash-shirki wash-shiqaqi wan-nifaqi wa su'il-akhlaq",
    translation:
        'O Allah, I seek refuge in You from doubt, associating partners with You, discord, hypocrisy and bad character.',
    note:
        'Commonly recited here. No specific dua is obligatory; any dhikr or dua is fine.',
  ),
  Landmark(
    id: 'hijr_ismail',
    nameEn: 'Hijr Ismail (Hateem) & Mizab',
    nameAr: 'حِجر إسماعيل',
    description:
        'The semicircular wall on the north-west side. Always stay outside it: '
        'Tawaf goes around the Hijr, not through it. The golden Mizab '
        'ur-Rahmah (rain spout) is above this wall.',
    duaTitle: 'Forgiveness and mercy',
    arabic:
        'رَبِّ اغْفِرْ وَارْحَمْ وَتَجَاوَزْ عَمَّا تَعْلَمُ إِنَّكَ أَنْتَ الْأَعَزُّ الْأَكْرَمُ',
    transliteration:
        "Rabbighfir warham wa tajawaz 'amma ta'lam innaka antal-A'azzul-Akram",
    translation:
        'My Lord, forgive, have mercy and pardon what You know. You are the Most Mighty, the Most Noble.',
    note: 'A good place for heartfelt personal supplication.',
  ),
  Landmark(
    id: 'rukn_shami',
    nameEn: 'Rukn Shami',
    nameAr: 'الركن الشامي',
    description:
        'The western corner of the Kaaba, facing the direction of Ash-Sham. '
        'There is no ritual touching of this corner.',
    duaTitle: 'Glorification of Allah',
    arabic:
        'سُبْحَانَ اللهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللهُ وَاللهُ أَكْبَرُ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ',
    transliteration:
        "Subhanallahi walhamdulillahi wa la ilaha illallahu wallahu akbar wa la hawla wa la quwwata illa billah",
    translation:
        'Glory be to Allah, all praise is for Allah, there is no god but Allah, Allah is the Greatest, and there is no power or strength except with Allah.',
    note: 'Dhikr is recommended throughout Tawaf.',
  ),
  Landmark(
    id: 'west_wall',
    nameEn: 'Western Wall of the Kaaba',
    nameAr: 'الجدار الغربي',
    description:
        'The long wall between Rukn Shami and Rukn Yamani. Keep a steady pace '
        'and continue your remembrance and dua.',
    duaTitle: 'Dua for an accepted Umrah',
    arabic:
        'اللَّهُمَّ اجْعَلْهَا عُمْرَةً مَبْرُورَةً وَذَنْبًا مَغْفُورًا وَسَعْيًا مَشْكُورًا',
    transliteration:
        "Allahummaj'alha 'umratan mabrurah, wa dhanban maghfura, wa sa'yan mashkura",
    translation:
        'O Allah, make this an accepted Umrah, my sins forgiven, and my effort appreciated.',
    note: 'You may recite any Quran, dhikr or personal dua instead.',
  ),
  Landmark(
    id: 'rukn_yamani',
    nameEn: 'Rukn Yamani',
    nameAr: 'الركن اليماني',
    description:
        'The south-western corner, facing Yemen. Touch it with your right hand '
        'if you can without crowding or pushing. Do not kiss it, and do not '
        'gesture toward it if you cannot reach it.',
    duaTitle: 'Pardon and well-being',
    arabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدِّينِ وَالدُّنْيَا وَالْآخِرَةِ',
    transliteration:
        "Allahumma inni as'alukal-'afwa wal-'afiyata fid-dini wad-dunya wal-akhirah",
    translation:
        'O Allah, I ask You for pardon and well-being in my religion, this world and the Hereafter.',
    note: 'Followed by the well-known dua between the two corners.',
  ),
  Landmark(
    id: 'yamani_to_stone',
    nameEn: 'Between Rukn Yamani & Black Stone',
    nameAr: 'بين الركن اليماني والحجر الأسود',
    description:
        'The final stretch of each circuit. It is Sunnah to recite the dua '
        'below here, before you reach the Black Stone again.',
    duaTitle: 'Rabbana atina',
    arabic:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    transliteration:
        "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
    translation:
        'Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire. (Quran 2:201)',
    note: 'Recite it once on every circuit as you approach the Black Stone.',
  ),
];

int landmarkIndexFor(double fraction) {
  final n = kLandmarks.length;
  return (fraction * n).round() % n;
}

// ---------------------------------------------------------------------------
// Location abstraction
// ---------------------------------------------------------------------------

/// A position estimate relative to one lap around the Kaaba.
///
/// [lapFraction] is in the range 0.0 (inclusive) to 1.0
