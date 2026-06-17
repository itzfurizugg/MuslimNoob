import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final res1 = await http.get(Uri.parse('https://equran.id/api/v2/shalat/provinsi'));
  print(res1.body);
}
