/// A premium, 100% offline, zero-dependency Vietnamese Sentiment Analyzer.
/// Uses a lexicon phrase-matching algorithm with support for multi-word compound terms
/// and customizable word lists.
class VietnameseSentimentService {
  // Singleton pattern for easy application-wide access
  static final VietnameseSentimentService _instance = VietnameseSentimentService._internal();
  factory VietnameseSentimentService() => _instance;
  VietnameseSentimentService._internal();

  /// Combined lexicon of Vietnamese emotional keywords with scores from -5.0 to 5.0.
  final Map<String, double> _lexicon = {
    // === Tích Cực (Positive) ===
    'tuyệt vời': 5.0,
    'tuyệt diệu': 5.0,
    'hoàn hảo': 5.0,
    'hạnh phúc': 5.0,
    'sung sướng': 4.5,
    'yêu thương': 4.0,
    'biết ơn': 4.5,
    'vui vẻ': 3.5,
    'hào hứng': 4.0,
    'phấn khởi': 4.0,
    'bình yên': 4.0,
    'an lành': 4.0,
    'thư giãn': 3.5,
    'dễ chịu': 3.0,
    'hài lòng': 3.0,
    'tự hào': 4.0,
    'hy vọng': 3.0,
    'tự tin': 3.5,
    'khỏe mạnh': 3.0,
    'tiến bộ': 3.0,
    'vui': 3.0,
    'thích': 2.5,
    'tốt': 2.5,
    'ổn': 2.0,

    // === Tiêu Cực (Negative) ===
    'tồi tệ': -5.0,
    'kinh khủng': -5.0,
    'tệ hại': -4.5,
    'đau khổ': -4.5,
    'tuyệt vọng': -5.0,
    'đau đớn': -4.5,
    'kiệt sức': -4.0,
    'cô đơn': -3.5,
    'thất vọng': -3.5,
    'chán nản': -3.5,
    'buồn bã': -3.5,
    'giận dữ': -3.5,
    'tức giận': -3.5,
    'mệt mỏi': -3.0,
    'áp lực': -2.5,
    'bực bội': -3.0,
    'lo lắng': -2.5,
    'lo âu': -2.5,
    'sợ hãi': -3.0,
    'buồn': -3.0,
    'tệ': -2.5,
    'mệt': -2.0,
    'khóc': -3.0,
    'đau': -2.0,
    'ghét': -3.0,
  };

  /// Allows developers to dynamically extend the lexicon with custom Vietnamese keywords
  /// or overwrite existing scores.
  void addCustomKeywords(Map<String, double> customKeywords) {
    customKeywords.forEach((word, score) {
      // Lowercase and trim key for uniform lookup
      _lexicon[word.toLowerCase().trim()] = score.clamp(-5.0, 5.0);
    });
  }

  /// Exposes a copy of the active lexicon database
  Map<String, double> get activeLexicon => Map.unmodifiable(_lexicon);

  // Ham thuc hien phan tich cam xuc (Sentiment Analysis) offline
  double analyze(String text) {
    if (text.trim().isEmpty) return 0.0;

    // 1. Tien xu ly chu: Chuyen sang chu thuong, xoa cac dau cau dac biet de so khop de dang hon
    String cleanText = text.toLowerCase();
    
    // Dung bieu thuc chinh quy xoa bo cac ky tu nhu cham, phay, cham hoi...
    final punctuation = RegExp(r'[.,!?;:"“”()\[\]{}\-_\/\\]');
    cleanText = cleanText.replaceAll(punctuation, ' ');
    // Rut gon cac khoang trang thua
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ');

    double totalScore = 0.0;
    int matchCount = 0;

    // 2. Thuat toan Greedy matching: Sap xep tu khoa tu dai den ngan
    // Dieu nay dam bao cac tu ghep (nhu 'tuyert voi') se duoc quet truoc cac tu don (nhu 'vui')
    final sortedKeywords = _lexicon.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final keyword in sortedKeywords) {
      // Bieu thuc chinh quy dam bao khop dung tu chu khong khop phan nho cua tu khac
      final escapedKeyword = RegExp.escape(keyword);
      final regex = RegExp('(^|\\s)$escapedKeyword(\\s|\$)');

      while (regex.hasMatch(cleanText)) {
        // Cong don diem tu dien cua tu khoa duoc phat hien
        final double score = _lexicon[keyword] ?? 0.0;
        totalScore += score;
        matchCount++;

        // Xoa tu da tim thay khoi chu de tranh viec trung lap hoac phan tich lai
        cleanText = cleanText.replaceFirst(regex, ' ');
        cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ');
      }
    }

    // 3. Tra ve ket qua:
    // Neu khong co tu cam xuc nao -> Tra ve 0.0 (Trung tinh)
    if (matchCount == 0) return 0.0;

    // Diem so cuoi cung se duoc gioi han tu -5.0 (tieu cuc nhat) den 5.0 (tich cuc nhat)
    return double.parse(totalScore.clamp(-5.0, 5.0).toStringAsFixed(2));
  }
}
