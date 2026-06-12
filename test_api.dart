import 'dart:convert';
import 'dart:io';

void main() async {
  var request = await HttpClient().getUrl(Uri.parse('https://text.pollinations.ai/Say%20hello?model=openai'));
  var response = await request.close();
  var body = await response.transform(utf8.decoder).join();
  print(response.statusCode);
  print(body);
}
