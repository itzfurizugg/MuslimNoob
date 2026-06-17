import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/login.dart';
import '../services/prayer_notif_service.dart';
import '../services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _email;
  String? _fullName;
  bool _isLoggingOut = false;
  String _selectedSound = 'default';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _loadData();
    _loadSound();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (mounted) {
      setState(() {
        _email = user?.email ?? '-';
        _fullName =
            user?.userMetadata?['full_name'] as String? ?? _email ?? '-';
      });
    }
  }

  Future<void> _loadSound() async {
    final sound = await PrayerNotifService.getSavedSound();
    if (mounted) setState(() => _selectedSound = sound);
  }

  Future<void> _logout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Keluar Akun',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Kamu yakin ingin keluar dari akun ini?',
              style: TextStyle(color: Color(0xFF555555), fontSize: 15),
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Keluar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoggingOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal logout: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<void> _updateName(String newName) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'full_name': newName}),
    );
    if (mounted) {
      setState(() {
        _fullName = newName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama berhasil diperbarui'),
          backgroundColor: Color(0xFF1A6B6B),
        ),
      );
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(email: newEmail),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan cek kotak masuk email baru untuk konfirmasi'),
          backgroundColor: Color(0xFF1A6B6B),
        ),
      );
    }
  }

  void _showEditBottomSheet(
    String title,
    String initialValue,
    Future<void> Function(String) onSave,
  ) {
    final controller = TextEditingController(text: initialValue);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Ubah $title',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Masukkan $title baru',
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF1A6B6B)),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final val = controller.text.trim();
                                  if (val.isEmpty || val == initialValue) {
                                    Navigator.pop(ctx);
                                    return;
                                  }
                                  setState(() => isLoading = true);
                                  try {
                                    await onSave(val);
                                    if (mounted) Navigator.pop(ctx);
                                  } catch (e) {
                                    setState(() => isLoading = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e is AuthException
                                                ? e.message
                                                : 'Terjadi kesalahan: $e',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A6B6B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Simpan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDummyEditDialog(String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Ubah $title',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Fitur ubah profil akan segera tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: TextStyle(color: Color(0xFF1A6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSoundPicker() {
    final options = PrayerNotifService.soundOptions;
    String tempSound = _selectedSound;
    final audioPlayer = AudioPlayer();
    String? playingSound;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return WillPopScope(
            onWillPop: () async {
              await audioPlayer.stop();
              await audioPlayer.dispose();
              return true;
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Suara Adzan',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pilih suara adzan. Tekan ikon play untuk mencoba.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ...options.entries.map((e) {
                    final isPlaying = playingSound == e.key;
                    return Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            value: e.key,
                            groupValue: tempSound,
                            activeColor: const Color(0xFF1A6B6B),
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => tempSound = val);
                              }
                            },
                          ),
                        ),
                        if (e.key != 'default')
                          IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.stop_circle_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: isPlaying
                                  ? Colors.redAccent
                                  : const Color(0xFF1A6B6B),
                              size: 32,
                            ),
                            onPressed: () async {
                              if (isPlaying) {
                                await audioPlayer.stop();
                                setSheetState(() => playingSound = null);
                              } else {
                                await audioPlayer.stop();
                                setSheetState(() => playingSound = e.key);

                                // Setup listener untuk reset state saat audio selesai
                                audioPlayer.onPlayerComplete.listen((_) {
                                  if (mounted) {
                                    setSheetState(() => playingSound = null);
                                  }
                                });

                                await audioPlayer.play(
                                  AssetSource('audio/${e.key}.mp3'),
                                );
                              }
                            },
                          ),
                      ],
                    );
                  }),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await audioPlayer.stop();
                            await audioPlayer.dispose();
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await audioPlayer.stop();
                            await audioPlayer.dispose();
                            await PrayerNotifService.saveSound(tempSound);
                            if (mounted) {
                              setState(() => _selectedSound = tempSound);
                            }
                            if (mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Suara diperbarui. Buka menu Jadwal untuk menyetel ulang alarm otomatis.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  duration: Duration(seconds: 4),
                                  backgroundColor: Color(0xFF1A6B6B),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A6B6B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Simpan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Setelan Aplikasi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 24),
            _actionTile(
              icon: Icons.music_note_outlined,
              label: 'Suara Adzan',
              subtitle:
                  PrayerNotifService.soundOptions[_selectedSound] ??
                  'Suara Bawaan',
              onTap: () {
                Navigator.pop(context);
                _showSoundPicker();
              },
            ),
            _actionTile(
              icon: Icons.notifications_active_outlined,
              label: 'Test Notifikasi',
              subtitle: 'Kirim notifikasi uji coba',
              onTap: () {
                PrayerNotifService().showTestNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Notifikasi dikirim... periksa bar notifikasi Anda',
                    ),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF1A6B6B),
                  ),
                );
              },
            ),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService().themeModeNotifier,
              builder: (context, currentMode, _) {
                String modeText;
                IconData modeIcon;
                switch (currentMode) {
                  case ThemeMode.dark:
                    modeText = 'Gelap';
                    modeIcon = Icons.dark_mode_rounded;
                    break;
                  case ThemeMode.light:
                    modeText = 'Terang';
                    modeIcon = Icons.light_mode_rounded;
                    break;
                  default:
                    modeText = 'Mengikuti Sistem';
                    modeIcon = Icons.brightness_auto_rounded;
                    break;
                }
                return _actionTile(
                  icon: modeIcon,
                  label: 'Tema Tampilan',
                  subtitle: modeText,
                  showArrow: false,
                  onTap: () {
                    Navigator.pop(context);
                    _showThemePicker();
                  },
                );
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Tema Tampilan',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16),
            _buildThemeOption(ctx, 'Mengikuti Sistem', ThemeMode.system, Icons.brightness_auto_rounded),
            _buildThemeOption(ctx, 'Terang', ThemeMode.light, Icons.light_mode_rounded),
            _buildThemeOption(ctx, 'Gelap', ThemeMode.dark, Icons.dark_mode_rounded),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext ctx, String label, ThemeMode mode, IconData icon) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeModeNotifier,
      builder: (context, currentMode, _) {
        final isSelected = currentMode == mode;
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final activeColor = isDark ? Colors.white : const Color(0xFF1A6B6B);
        
        return ListTile(
          onTap: () {
            ThemeService().setThemeMode(mode);
            Navigator.pop(ctx);
            _showSettingsSheet();
          },
          leading: Icon(icon, color: isSelected ? activeColor : Colors.grey),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : theme.colorScheme.onSurface,
            ),
          ),
          trailing: isSelected ? Icon(Icons.check_circle_rounded, color: activeColor) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profil Kamu',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showSettingsSheet,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.settings,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Avatar Card
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.cardColor,
                            border: Border.all(color: theme.cardColor, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _fullName != null && _fullName!.isNotEmpty
                                  ? _fullName![0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showDummyEditDialog('Foto Profil'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.cardColor, width: 3),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _fullName ?? '',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _email ?? '',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Info Section
              Text(
                'INFORMASI AKUN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodySmall?.color,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _actionTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Ubah Nama',
                      subtitle: _fullName,
                      onTap: () => _showEditBottomSheet(
                        'Nama',
                        _fullName ?? '',
                        _updateName,
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 20,
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                    _actionTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      subtitle: _email,
                      onTap: () => _showEditBottomSheet(
                        'Email',
                        _email ?? '',
                        _updateEmail,
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 20,
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Danger Zone
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _actionTile(
                  icon: Icons.logout_rounded,
                  label: 'Keluar Akun',
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  isLoading: _isLoggingOut,
                  onTap: _isLoggingOut ? null : _logout,
                  showArrow: false,
                ),
              ),

              SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Text(
                      'MuslimNoob v1.0 Release Version',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(
                      'Made by @itzfurizugg',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    bool showArrow = true,
    bool isLoading = false,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final finalIconColor = iconColor ?? (isDark ? Colors.white : const Color(0xFF1A6B6B));
    final finalTextColor = textColor ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: finalIconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: finalIconColor,
                      ),
                    )
                  : Icon(icon, color: finalIconColor, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: finalTextColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
