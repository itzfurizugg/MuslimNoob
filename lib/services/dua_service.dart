import 'dart:convert';
import 'package:http/http.dart' as http;

class DuaCategory {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  DuaCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });
}

class Dua {
  final int id;
  final int categoryId;
  final String title;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String? source;
  final int order;
  final String grup;

  Dua({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    this.source,
    required this.order,
    this.grup = '',
  });

  factory Dua.fromJson(Map<String, dynamic> json, int categoryId) => Dua(
    id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
    categoryId: categoryId,
    title: json['nama'] ?? '',
    arabicText: json['ar'] ?? '',
    transliteration: json['tr'] ?? '',
    translation: json['idn'] ?? '',
    source: json['tentang'],
    order: 0,
    grup: json['grup'] ?? '',
  );
}

class DuaService {
  static const String _baseUrl = 'https://equran.id/api/doa';
  static List<Dua>? _allDuasCache;
  static List<DuaCategory>? _categoriesCache;

  Future<void> _fetchAndCache() async {
    if (_allDuasCache != null) return;
    
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data is Map ? data['data'] ?? data : data;
      
      List<DuaCategory> categories = [];
      List<Dua> duas = [];
      int catId = 1;
      
      final Map<String, int> groupToCatId = {};
      
      for (var item in list) {
        final grupName = item['grup']?.toString() ?? 'Lainnya';
        if (!groupToCatId.containsKey(grupName)) {
           groupToCatId[grupName] = catId;
           categories.add(DuaCategory(
             id: catId, 
             name: grupName, 
             slug: grupName.toLowerCase().replaceAll(' ', '-'),
           ));
           catId++;
        }
        
        duas.add(Dua.fromJson(item, groupToCatId[grupName]!));
      }
      
      _categoriesCache = categories;
      _allDuasCache = duas;
    } else {
      throw Exception('Gagal memuat doa dari server');
    }
  }

  Future<List<DuaCategory>> getCategories() async {
    await _fetchAndCache();
    return _categoriesCache ?? [];
  }

  Future<List<Dua>> getDuasByCategory(int categoryId) async {
    await _fetchAndCache();
    return _allDuasCache?.where((d) => d.categoryId == categoryId).toList() ?? [];
  }
}