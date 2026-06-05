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

  /// Performs offline sentiment analysis on a Vietnamese string.
  ///
  /// Cleans the text, tokenizes it using a phrase-matching greedy search to support
  /// compound words, and returns a double score strictly clamped between -5.0 and 5.0.
  double analyze(String text) {
    if (text.trim().isEmpty) return 0.0;

    // 1. Preprocess: Lowercase, remove typical punctuation for uniform matching
    String cleanText = text.toLowerCase();
    
    // Replace typical punctuation with spaces to separate syllables cleanly
    final punctuation = RegExp(r'[.,!?;:"“”()\[\]{}\-_\/\\]');
    cleanText = cleanText.replaceAll(punctuation, ' ');
    // Condense multiple spaces into one
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ');

    double totalScore = 0.0;
    int matchCount = 0;

    // 2. Greedy phrase matching: Sort lexicon keys by length in descending order.
    // This guarantees that compound phrases (e.g. 'mệt mỏi' or 'tuyệt vời') are matched
    // and consumed before single words (e.g. 'mệt' or 'vui') can interfere.
    final sortedKeywords = _lexicon.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final keyword in sortedKeywords) {
      // Use boundary-safe search to avoid partial matching inside non-related words.
      // E.g., we want to match 'vui' but not the 'vui' inside 'vui sướng' if 'vui sướng' is processed first.
      final escapedKeyword = RegExp.escape(keyword);
      final regex = RegExp('(^|\\s)$escapedKeyword(\\s|\$)');

      while (regex.hasMatch(cleanText)) {
        final double score = _lexicon[keyword] ?? 0.0;
        totalScore += score;
        matchCount++;

        // Consume the matched phrase by replacing it with a placeholder space
        // to prevent duplicate or sub-word matching.
        cleanText = cleanText.replaceFirst(regex, ' ');
        // Clean double spaces again
        cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ');
      }
    }

    // 3. Normalize score:
    // If no emotion terms are found, return 0.0 (neutral).
    if (matchCount == 0) return 0.0;

    // We clamp the sum score directly between -5.0 and 5.0
    return double.parse(totalScore.clamp(-5.0, 5.0).toStringAsFixed(2));
  }
}
