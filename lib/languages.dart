import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

// Create a list of supported codes
Map<String, dynamic> instructions = {
  'ar': null,
  'da': null,
  'de': null,
  'en': null,
  'eo': null,
  'es': null,
  'es-ES': null,
  'fi': null,
  'fr': null,
  'he': null,
  'hu': null,
  'id': null,
  'it': null,
  'ja': null,
  'ko': null,
  'my': null,
  'nl': null,
  'no': null,
  'pl': null,
  'pt-BR': null,
  'pt-PT': null,
  'ro': null,
  'ru': null,
  'sl': null,
  'sv': null,
  'tr': null,
  'uk': null,
  'vi': null,
  'yo': null,
  'zh-Hans': null
};

// Create list of supported grammar
Map<String, dynamic> grammars = {
  'da': null,
  'fr': null,
  'hu': null,
  'ru': null,
};

// Create list of supported abbrevations
Map<String, dynamic> abbreviations = {
  'bg': null,
  'ca': null,
  'da': null,
  'de': null,
  'en': null,
  'es': null,
  'fr': null,
  'he': null,
  'hu': null,
  'lt': null,
  'nl': null,
  'ru': null,
  'sl': null,
  'sv': null,
  'uk': null,
  'vi': null
};

Map<String, dynamic> languages = {
  'supportedCodes': instructions.keys,
  'instructions': instructions,
  'grammars': grammars,
  'abbreviations': abbreviations
};

Future<void> loadLanguage(String language) async {
  if (instructions.keys.contains(language) && instructions[language] == null) {
    instructions[language] =
        await _load(language, "packages/osrm_text_instructions_dart/languages/translations/$language.json");
  }
  if (grammars.keys.contains(language) && grammars[language] == null) {
    grammars[language] = await _load(language, "packages/osrm_text_instructions_dart/languages/grammar/$language.json");
  }
  if (abbreviations.keys.contains(language) && abbreviations[language] == null) {
    abbreviations[language] =
        await _load(language, "packages/osrm_text_instructions_dart/languages/abbreviations/$language.json");
  }
}

Future<Map<String, dynamic>> _load(String language, String path) async {
  return jsonDecode(await rootBundle.loadString(path));
}
