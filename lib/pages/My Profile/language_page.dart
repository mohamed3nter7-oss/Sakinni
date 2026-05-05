import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:circle_flags/circle_flags.dart';

// Language Manager
class LanguageManager {
  static final LanguageManager _instance = LanguageManager._internal();
  factory LanguageManager() => _instance;
  LanguageManager._internal();

  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;
  bool get isRTL => _currentLanguage == 'ar';

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'en';
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }
}

// Translations
class AppTranslations {
  static Map<String, Map<String, String>> translations = {
    'language': {
      'en': 'Language',
      'ar': 'اللغة',
      'fr': 'Langue',
      'zh': '语言',
      'de': 'Sprache',
      'es': 'Idioma',
    },
  };

  static String get(String key, String lang) {
    return translations[key]?[lang] ?? translations[key]?['en'] ?? key;
  }
}

// Language class
class Language {
  final String name;
  final String code;
  final String nativeName;
  final String flagCode;

  Language({
    required this.name,
    required this.code,
    required this.nativeName,
    required this.flagCode,
  });
}

// Language Selection Screen
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String selectedLanguage = 'English';

  final List<Language> languages = [
    Language(
      name: 'United States',
      code: 'en',
      nativeName: '(English)',
      flagCode: 'us',
    ),
    Language(
      name: 'Egypt',
      code: 'ar',
      nativeName: '(العربية)',
      flagCode: 'eg',
    ),
    Language(
      name: 'France',
      code: 'fr',
      nativeName: '(Français)',
      flagCode: 'fr',
    ),
    Language(
      name: 'China',
      code: 'zh',
      nativeName: '(中文)',
      flagCode: 'cn',
    ),
    Language(
      name: 'Germany',
      code: 'de',
      nativeName: '(Deutsch)',
      flagCode: 'de',
    ),
    Language(
      name: 'Spain',
      code: 'es',
      nativeName: '(Español)',
      flagCode: 'es',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final currentLang = LanguageManager().currentLanguage;
    selectedLanguage = languages
        .firstWhere(
          (lang) => lang.code == currentLang,
          orElse: () => languages[0],
        )
        .name;
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageManager().currentLanguage;
    final isRTL = LanguageManager().isRTL;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(AppTranslations.get('language', lang)),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.blue),
              onPressed: () async {
                final selectedLang = languages.firstWhere(
                  (lang) => lang.name == selectedLanguage,
                );
                await LanguageManager().setLanguage(selectedLang.code);
                Navigator.pop(context, selectedLang.code);
              },
            ),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final language = languages[index];
            final isSelected = selectedLanguage == language.name;

            return InkWell(
              onTap: () {
                setState(() {
                  selectedLanguage = language.name;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleFlag(
                      language.flagCode,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        language.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      language.nativeName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}