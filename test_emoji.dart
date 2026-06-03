import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:emoji_picker_flutter/locales/default_emoji_set_locale.dart';
import 'package:flutter/material.dart';

void main() {
  final locales = [
    Locale('en'),
    Locale('ar')
  ];

  for(var loc in locales) {
    var emojis = getDefaultEmojiLocale(loc);
    for(var cat in emojis) {
      for(var e in cat.emoji) {
        if(e.emoji.contains('\u{1F1EE}') || e.emoji.contains('\u{1F1F1}') || e.emoji.contains('🏳️‍🌈') || e.emoji.contains('🏳️‍⚧️') || e.emoji.contains('🏴‍☠️')) {
          print('${loc.languageCode} -> ${e.emoji} : ${e.name}');
        }
      }
    }
  }
}
