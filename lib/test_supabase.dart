import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ryyahvjonscodfcmjaaf.supabase.co',
    anonKey: 'sb_publishable_gRefHEE_JHWhY7XoVIVjmg_6CsTB_xM',
  );
  
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase.from('tutorials').select();
    print("Tutorials:");
    print(response);
  } catch (e) {
    print("Error: $e");
  }
}
