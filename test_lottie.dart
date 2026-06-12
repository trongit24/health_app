import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://fonts.gstatic.com/s/e/notoemoji/latest/1f62d/lottie.json');
  final res = await http.get(url);
  print('Status: \${res.statusCode}');
}
