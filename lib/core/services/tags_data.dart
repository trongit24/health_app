class TagsData {
  static const List<Map<String, String>> allTags = [
    {'emoji': '🧘', 'label': 'Tĩnh lặng', 'key': 'tag_calm'},
    {'emoji': '⚡', 'label': 'Căng thẳng', 'key': 'tag_stressed'},
    {'emoji': '🎉', 'label': 'Hào hứng', 'key': 'tag_excited'},
    {'emoji': '😴', 'label': 'Mệt mỏi', 'key': 'tag_tired'},
    {'emoji': '🧠', 'label': 'Tập trung', 'key': 'tag_focused'},
    {'emoji': '😟', 'label': 'Lo âu', 'key': 'tag_anxious'},
    {'emoji': '💖', 'label': 'Biết ơn', 'key': 'tag_grateful'},
    {'emoji': '🍀', 'label': 'Bình yên', 'key': 'tag_peaceful'},
    {'emoji': '😢', 'label': 'Buồn bã', 'key': 'tag_sad'},
    {'emoji': '👤', 'label': 'Cô đơn', 'key': 'tag_lonely'},
    {'emoji': '😞', 'label': 'Thất vọng', 'key': 'tag_disappointed'},
    {'emoji': '💔', 'label': 'Đau lòng', 'key': 'tag_hurt'},
    {'emoji': '😰', 'label': 'Bất an', 'key': 'tag_uneasy'},
    {'emoji': '🫙', 'label': 'Trống rỗng', 'key': 'tag_empty'},
    {'emoji': '😐', 'label': 'Bình thường', 'key': 'tag_okay'},
    {'emoji': '🍃', 'label': 'Thư giãn', 'key': 'tag_relaxed'},
    {'emoji': '😊', 'label': 'Vui vẻ', 'key': 'tag_happy'},
    {'emoji': '💪', 'label': 'Tự tin', 'key': 'tag_confident'},
    {'emoji': '🏃', 'label': 'Năng động', 'key': 'tag_energetic'},
    {'emoji': '✨', 'label': 'Hạnh phúc', 'key': 'tag_joyful'},
    {'emoji': '👑', 'label': 'Tự hào', 'key': 'tag_proud'},
  ];

  static List<Map<String, String>> getTagsForScore(int score) {
    switch (score) {
      case 1: // Rất buồn / Very Sad
        return [
          {'emoji': '😢', 'label': 'Buồn bã', 'key': 'tag_sad'},
          {'emoji': '👤', 'label': 'Cô đơn', 'key': 'tag_lonely'},
          {'emoji': '😞', 'label': 'Thất vọng', 'key': 'tag_disappointed'},
          {'emoji': '😴', 'label': 'Mệt mỏi', 'key': 'tag_tired'},
          {'emoji': '💔', 'label': 'Đau lòng', 'key': 'tag_hurt'},
        ];
      case 2: // Hơi buồn / A Bit Low
        return [
          {'emoji': '😟', 'label': 'Lo âu', 'key': 'tag_anxious'},
          {'emoji': '⚡', 'label': 'Căng thẳng', 'key': 'tag_stressed'},
          {'emoji': '😰', 'label': 'Bất an', 'key': 'tag_uneasy'},
          {'emoji': '😴', 'label': 'Mệt mỏi', 'key': 'tag_tired'},
          {'emoji': '🫙', 'label': 'Trống rỗng', 'key': 'tag_empty'},
        ];
      case 3: // Bình thường / Neutral
        return [
          {'emoji': '🧘', 'label': 'Tĩnh lặng', 'key': 'tag_calm'},
          {'emoji': '😐', 'label': 'Bình thường', 'key': 'tag_okay'},
          {'emoji': '🧠', 'label': 'Tập trung', 'key': 'tag_focused'},
          {'emoji': '🍀', 'label': 'Bình yên', 'key': 'tag_peaceful'},
          {'emoji': '🍃', 'label': 'Thư giãn', 'key': 'tag_relaxed'},
        ];
      case 4: // Vui vẻ / Cheerful
        return [
          {'emoji': '😊', 'label': 'Vui vẻ', 'key': 'tag_happy'},
          {'emoji': '💪', 'label': 'Tự tin', 'key': 'tag_confident'},
          {'emoji': '💖', 'label': 'Biết ơn', 'key': 'tag_grateful'},
          {'emoji': '🏃', 'label': 'Năng động', 'key': 'tag_energetic'},
          {'emoji': '🎉', 'label': 'Hào hứng', 'key': 'tag_excited'},
        ];
      case 5: // Rất hạnh phúc / Joyful & Happy
        return [
          {'emoji': '🎉', 'label': 'Hào hứng', 'key': 'tag_excited'},
          {'emoji': '✨', 'label': 'Hạnh phúc', 'key': 'tag_joyful'},
          {'emoji': '🍀', 'label': 'Bình yên', 'key': 'tag_peaceful'},
          {'emoji': '👑', 'label': 'Tự hào', 'key': 'tag_proud'},
          {'emoji': '💖', 'label': 'Biết ơn', 'key': 'tag_grateful'},
        ];
      default:
        return [];
    }
  }
}
