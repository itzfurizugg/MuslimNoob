import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final res = await http.post(
    Uri.parse('https://equran.id/api/v2/shalat/kabkota'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'provinsi': 'Jawa Barat'}),
  );
  print(res.body);
}
