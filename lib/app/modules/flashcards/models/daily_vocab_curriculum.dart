/// Definition of a single Sub-Deck topic inside the fixed Daily Vocab CEFR curriculum.
class DailyVocabTopic {
  const DailyVocabTopic({
    required this.topicKey,
    required this.cefrLevel,
    required this.deckName,
    required this.deckDescription,
    required this.subDeckName,
    required this.subDeckDescription,
    this.targetCount = 50,
  });

  final String topicKey;
  final String cefrLevel;
  final String deckName;
  final String deckDescription;
  final String subDeckName;
  final String subDeckDescription;
  final int targetCount;
}

/// Summary metadata for a CEFR level Deck in the Daily Vocab curriculum.
class DailyVocabLevelInfo {
  const DailyVocabLevelInfo({
    required this.cefrLevel,
    required this.shortLabel,
    required this.deckName,
    required this.deckDescription,
  });

  final String cefrLevel;
  final String shortLabel;
  final String deckName;
  final String deckDescription;
}

/// Fixed 2,400-word everyday conversation curriculum: 4 CEFR Decks x 12 Sub-Decks x 50 words.
class DailyVocabCurriculum {
  const DailyVocabCurriculum._();

  static const int defaultWordsPerTopic = 50;

  static const List<DailyVocabLevelInfo> levels = <DailyVocabLevelInfo>[
    DailyVocabLevelInfo(
      cefrLevel: 'A1',
      shortLabel: 'A1 Pemula',
      deckName: 'A1 - Pemula (Daily Basics)',
      deckDescription:
          '~600 kata dasar percakapan sehari-hari untuk pemula (12 topik harian).',
    ),
    DailyVocabLevelInfo(
      cefrLevel: 'A2',
      shortLabel: 'A2 Dasar',
      deckName: 'A2 - Dasar (Everyday Life)',
      deckDescription:
          '~600 kosakata rutin harian untuk interaksi santai dan kebutuhan praktis.',
    ),
    DailyVocabLevelInfo(
      cefrLevel: 'B1',
      shortLabel: 'B1 Menengah',
      deckName: 'B1 - Menengah (Social & Work)',
      deckDescription:
          '~600 kosakata diskusi sosial, pekerjaan, dan situasi harian menengah.',
    ),
    DailyVocabLevelInfo(
      cefrLevel: 'B2',
      shortLabel: 'B2 Lanjutan',
      deckName: 'B2 - Mahir Harian (Fluency & Nuance)',
      deckDescription:
          '~600 kosakata natural, ekspresi multi-fungsi, dan nuansa percakapan lancar.',
    ),
  ];

  static const List<_TopicTemplate> _topicTemplates = <_TopicTemplate>[
    _TopicTemplate(
      slug: 'daily_routines',
      subDeckName: 'Daily Routines & Actions',
      descriptionsByLevel: <String, String>{
        'A1': 'Kata kerja dan aktivitas rutin dasar dari bangun hingga tidur.',
        'A2': 'Kebiasaan harian, tugas rumah, dan aktivitas waktu luang.',
        'B1': 'Manajemen rutinitas, produktivitas, dan kebiasaan sosial.',
        'B2': 'Ekspresi kebiasaan, gaya hidup modern, dan aktivitas spontan.',
      },
    ),
    _TopicTemplate(
      slug: 'people_family',
      subDeckName: 'People, Family & Relationships',
      descriptionsByLevel: <String, String>{
        'A1': 'Keluarga inti, sapaan dasar, dan kata ganti orang sehari-hari.',
        'A2': 'Hubungan pertemanan, tetangga, dan interaksi keluarga.',
        'B1': 'Dinamika hubungan sosial, kerja sama, dan komunitas.',
        'B2': 'Relasi interpersonal, empati, konflik, dan komitmen sosial.',
      },
    ),
    _TopicTemplate(
      slug: 'food_cooking',
      subDeckName: 'Food, Cooking & Dining',
      descriptionsByLevel: <String, String>{
        'A1': 'Nama makanan, minuman dasar, rasa umum, dan pesan makan.',
        'A2': 'Memasak sederhana, bahan dapur, dan makan di restoran.',
        'B1': 'Teknik memasak, preferensi diet, dan ulasan rasa makanan.',
        'B2': 'Kuliner kasual, etika makan, dan deskripsi cita rasa mendetail.',
      },
    ),
    _TopicTemplate(
      slug: 'home_places',
      subDeckName: 'Home, Objects & Places',
      descriptionsByLevel: <String, String>{
        'A1': 'Benda di sekitar rumah, ruangan dasar, dan lokasi umum.',
        'A2': 'Perabotan, lingkungan sekitar, dan tempat layanan publik.',
        'B1': 'Pengaturan tempat tinggal, fasilitas kota, dan perawatan rumah.',
        'B2': 'Arsitektur hunian, suasana ruang, dan kehidupan perkotaan.',
      },
    ),
    _TopicTemplate(
      slug: 'feelings_opinions',
      subDeckName: 'Feelings, Opinions & Personality',
      descriptionsByLevel: <String, String>{
        'A1': 'Perasaan dasar, sifat sederhana, dan suka atau tidak suka.',
        'A2': 'Emosi sehari-hari, kesan sederhana, dan karakter teman.',
        'B1': 'Mengungkapkan pendapat, sikap, persetujuan, dan keraguan.',
        'B2': 'Nuansa emosi halus, argumen persuasif, dan karakter mendalam.',
      },
    ),
    _TopicTemplate(
      slug: 'time_connectors',
      subDeckName: 'Time, Numbers & Connectors',
      descriptionsByLevel: <String, String>{
        'A1': 'Waktu, hari, angka, frekuensi dasar, dan penghubung sederhana.',
        'A2': 'Jadwal, durasi, urutan kejadian, dan kata sambung praktis.',
        'B1': 'Keterangan waktu relatif, penekanan, dan transisi percakapan.',
        'B2': 'Penanda wacana lisan, kontras ide, dan ketepatan konteks waktu.',
      },
    ),
    _TopicTemplate(
      slug: 'shopping_money',
      subDeckName: 'Shopping, Money & Services',
      descriptionsByLevel: <String, String>{
        'A1': 'Harga, belanja dasar, ukuran, warna, dan pembayaran.',
        'A2': 'Tawar-menawar ringan, pengembalian barang, dan transaksi bank.',
        'B1': 'Anggaran pribadi, layanan pelanggan, garansi, dan transaksi daring.',
        'B2': 'Negosiasi layanan, kebiasaan belanja bijak, dan keputusan finansial.',
      },
    ),
    _TopicTemplate(
      slug: 'travel_directions',
      subDeckName: 'Travel, Transport & Directions',
      descriptionsByLevel: <String, String>{
        'A1': 'Arah dasar, transportasi umum, dan lokasi jalan.',
        'A2': 'Pesan tiket, hotel, menanyakan rute, dan perjalanan singkat.',
        'B1': 'Kendala perjalanan, jadwal transit, dan rencana liburan.',
        'B2': 'Navigasi lancar, pengalaman wisata, dan situasi tak terduga.',
      },
    ),
    _TopicTemplate(
      slug: 'work_study',
      subDeckName: 'Work, Study & Meetings',
      descriptionsByLevel: <String, String>{
        'A1': 'Profesi dasar, benda kelas/kantor, dan aktivitas belajar.',
        'A2': 'Tugas harian kantor, jadwal kelas, dan komunikasi rekan.',
        'B1': 'Diskusi rapat, tenggat proyek, presentasi, dan umpan balik.',
        'B2': 'Kolaborasi profesional, pemecahan masalah, dan pencapaian karier.',
      },
    ),
    _TopicTemplate(
      slug: 'tech_communication',
      subDeckName: 'Technology & Communication',
      descriptionsByLevel: <String, String>{
        'A1': 'Ponsel, internet, pesan singkat, dan panggilan dasar.',
        'A2': 'Aplikasi harian, email santai, foto, dan kendala koneksi.',
        'B1': 'Media sosial, keamanan akun, panggilan video, dan fitur digital.',
        'B2': 'Budaya digital, etika komunikasi daring, dan alur kerja teknologi.',
      },
    ),
    _TopicTemplate(
      slug: 'health_emergencies',
      subDeckName: 'Health, Body & Emergencies',
      descriptionsByLevel: <String, String>{
        'A1': 'Bagian tubuh dasar, keluhan ringan, dan minta tolong.',
        'A2': 'Ke dokter, apotek, gejala umum, dan kebiasaan sehat.',
        'B1': 'Kebugaran, penanganan darurat ringan, dan pemulihan.',
        'B2': 'Kesehatan mental-fisik, situasi darurat, dan pencegahan medis.',
      },
    ),
    _TopicTemplate(
      slug: 'phrasal_multipos',
      subDeckName: 'Core Phrasal Verbs & Multi-POS Expressions',
      descriptionsByLevel: <String, String>{
        'A1': 'Ungkapan harian inti dan kata multi-fungsi paling sering dipakai.',
        'A2': 'Phrasal verb dasar percakapan dan kata serbaguna sehari-hari.',
        'B1': 'Phrasal verb populer dan kata multi-POS dalam obrolan alami.',
        'B2': 'Phrasal verb idiomatis, nuansa kolokial, dan ekspresi multi-POS.',
      },
    ),
  ];

  /// Complete list of 48 topics (4 CEFR decks x 12 sub-decks = 2,400 target words).
  static final List<DailyVocabTopic> allTopics = List<DailyVocabTopic>.unmodifiable(
    <DailyVocabTopic>[
      for (final level in levels)
        for (final template in _topicTemplates)
          DailyVocabTopic(
            topicKey: '${level.cefrLevel.toLowerCase()}_${template.slug}',
            cefrLevel: level.cefrLevel,
            deckName: level.deckName,
            deckDescription: level.deckDescription,
            subDeckName: template.subDeckName,
            subDeckDescription:
                template.descriptionsByLevel[level.cefrLevel] ?? '',
            targetCount: defaultWordsPerTopic,
          ),
    ],
  );

  /// Returns all 48 topics when [cefrLevel] is null/empty, or 12 topics for that CEFR level.
  static List<DailyVocabTopic> topicsForLevel(String? cefrLevel) {
    final normalized = cefrLevel?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) return allTopics;
    return allTopics
        .where((topic) => topic.cefrLevel == normalized)
        .toList(growable: false);
  }
}

class _TopicTemplate {
  const _TopicTemplate({
    required this.slug,
    required this.subDeckName,
    required this.descriptionsByLevel,
  });

  final String slug;
  final String subDeckName;
  final Map<String, String> descriptionsByLevel;
}
