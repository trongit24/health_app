import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class AiService {
  static const String _defaultApiKey = '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';
  static const String _apiKeyPrefsKey = 'gemini_api_key';

  static const List<String> _geminiModelFallbacks = [
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-pro',
    'gemini-pro',
  ];

  String _apiKey = _defaultApiKey;
  bool _initialized = false;

  // Singleton pattern
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  Future<void> initialize() async {
    try {
      _apiKey = _defaultApiKey;
      _initialized = true;
    } catch (e) {
      debugPrint('[AiService] initialize() error: $e');
    }
  }

  Future<void> updateApiKey(String newKey) async {
    _apiKey = newKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyPrefsKey, newKey);
    } catch (e) {}
  }

  bool get hasValidKey => _apiKey.isNotEmpty;
  bool get isReady => _initialized;

  Future<String?> _tryGenerateContent(String prompt) async {
    if (!hasValidKey) {
      throw Exception('Bạn chưa nhập API Key. Hãy nhập API Key của Gemini hoặc Groq.');
    }

    // 1. Nếu API Key bắt đầu bằng "gsk_" -> Dùng GROQ API (Llama 3 - Miễn phí và siêu tốc)
    if (_apiKey.startsWith('gsk_')) {
      debugPrint('[AiService] Detected Groq API Key. Using Groq...');
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Lỗi Groq API: ${response.statusCode} - ${response.body}');
      }
    }
    
    // 2. Nếu API Key bắt đầu bằng "sk-or-" -> Dùng OPENROUTER API (Miễn phí)
    if (_apiKey.startsWith('sk-or-')) {
      debugPrint('[AiService] Detected OpenRouter API Key...');
      final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'google/gemini-pro', // Dùng model miễn phí trên openrouter
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Lỗi OpenRouter API: ${response.statusCode} - ${response.body}');
      }
    }

    // 3. Mặc định: Dùng Google Gemini API (Key bắt đầu bằng AIza...)
    debugPrint('[AiService] Using Gemini API...');
    dynamic lastError;
    for (final modelName in _geminiModelFallbacks) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
          generationConfig: GenerationConfig(temperature: 0.9, maxOutputTokens: 800),
        );
        final response = await model.generateContent([Content.text(prompt)]);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text;
        }
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError is GenerativeAIException) {
      throw lastError;
    } else {
      throw Exception(lastError.toString());
    }
  }

  Future<String?> testConnection() async {
    try {
      await _tryGenerateContent('Chào, trả lời "Thành công" bằng tiếng Việt.');
      return null;
    } on GenerativeAIException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String> getAdvice(String userMessage) async {
    if (!isReady) return 'Đang khởi tạo...';
    if (!hasValidKey) return '⚠️ API Key không hợp lệ.';

    try {
      final prompt = '''Bạn là một chuyên gia tâm lý học và một người bạn đồng hành ảo trong ứng dụng chăm sóc sức khỏe tinh thần tên là SoulFlow. 
Dưới đây là chia sẻ của người dùng:
"$userMessage"

Hãy phân tích cảm xúc của họ một cách ngắn gọn, đưa ra một lời khuyên chân thành, ấm áp và động viên. Giữ câu trả lời ngắn gọn, dưới 3 đoạn văn, ngôn từ thân thiện, dễ hiểu bằng tiếng Việt.''';

      final responseText = await _tryGenerateContent(prompt);
      return responseText ?? 'Xin lỗi, AI không trả về kết quả.';
    } on GenerativeAIException catch (e) {
      return '❌ Lỗi API Gemini: ${e.message}\n\nHãy tạo lại API Key mới tại aistudio.google.com';
    } catch (e) {
      return '❌ Lỗi: ${e.toString().replaceAll("Exception: ", "")}';
    }
  }
}
