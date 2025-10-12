import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/tts_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _ttsEnabled = true;
  bool _autoPlayEnabled = true;
  bool _welcomeCardEnabled = true;
  double _speechRate = 0.5;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _ttsService.onMuteChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _ttsService.onMuteChanged = null;
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
      _autoPlayEnabled = prefs.getBool('tts_auto_play') ?? true;
      _welcomeCardEnabled = prefs.getBool('welcome_card_enabled') ?? true;
      _speechRate = prefs.getDouble('tts_rate') ?? 0.5;
      _volume = prefs.getDouble('tts_volume') ?? 1.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', _ttsEnabled);
    await prefs.setBool('tts_auto_play', _autoPlayEnabled);
    await prefs.setBool('welcome_card_enabled', _welcomeCardEnabled);
    await prefs.setDouble('tts_rate', _speechRate);
    await prefs.setDouble('tts_volume', _volume);

    // Update TTS service
    await _ttsService.setRate(_speechRate);
    await _ttsService.setVolume(_volume);
  }

  Future<void> _testTTS() async {
    await _ttsService.speak(
      "This is a test of the text-to-speech settings. You should be able to hear this message clearly.",
      checkPreferences: false
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F8FA),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF265F7E),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF265F7E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTTSSection(),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTTSSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Text-to-Speech Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF265F7E),
              ),
            ),
          ),
          _buildSwitchTile(
            'Enable TTS',
            'Turn text-to-speech on or off',
            _ttsEnabled,
            (value) async {
              setState(() => _ttsEnabled = value);
              await _saveSettings();
            },
          ),
          _buildSwitchTile(
            'Auto-play on Navigation',
            'Automatically speak messages when entering screens',
            _autoPlayEnabled,
            (value) async {
              setState(() => _autoPlayEnabled = value);
              await _saveSettings();
            },
          ),
          _buildSwitchTile(
            'Welcome Card',
            'Show welcome message on home screen',
            _welcomeCardEnabled,
            (value) async {
              setState(() => _welcomeCardEnabled = value);
              await _saveSettings();
            },
          ),
          _buildSliderTile(
            'Speech Rate',
            'Adjust how fast the speech is',
            _speechRate,
            0.1,
            1.0,
            (value) async {
              setState(() => _speechRate = value);
              await _saveSettings();
            },
          ),
          _buildSliderTile(
            'Volume',
            'Adjust the speech volume',
            _volume,
            0.0,
            1.0,
            (value) async {
              setState(() => _volume = value);
              await _saveSettings();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testTTS,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Test TTS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E7E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _ttsService.isMuted ? Colors.grey[400] : const Color(0xFF1B5E7E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _ttsService.isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      await _ttsService.toggleMute();
                    },
                    tooltip: _ttsService.isMuted ? 'Unmute' : 'Mute',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF1B5E7E),
    );
  }

  Widget _buildSliderTile(String title, String subtitle, double value, double min, double max, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 10,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
            activeColor: const Color(0xFF1B5E7E),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF265F7E),
              ),
            ),
          ),
         const ListTile(
            leading: Icon(Icons.info, color: Color(0xFF1B5E7E)),
            title: Text('App Name'),
            subtitle: Text('Dementia Care'),
          ),
         const ListTile(
            leading: Icon(Icons.tag, color: Color(0xFF1B5E7E)),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
         const ListTile(
            leading: Icon(Icons.person, color: Color(0xFF1B5E7E)),
            title: Text('Developer'),
            subtitle: Text('brets corner'),
          ),
          const ListTile(
            leading: Icon(Icons.description, color: Color(0xFF1B5E7E)),
            title: Text('Description'),
            subtitle: Text(
              'A mood tracking tool designed to support emotional wellbeing and help users reflect on their emotional journey through memories and mood logging.'
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Color(0xFF1B5E7E)),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchUrl('https://example.com/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.article, color: Color(0xFF1B5E7E)),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchUrl('https://example.com/terms'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}