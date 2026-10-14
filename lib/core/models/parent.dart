import 'package:flutter/foundation.dart';

import '../i18n/app_lang.dart';

/// Ported from `Parent` in packages/shared/src/types.
@immutable
class Parent {
  const Parent({
    required this.id,
    required this.phone,
    required this.name,
    required this.lang,
    required this.whatsappOptIn,
  });

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String,
      lang: AppLang.fromDb(json['lang'] as String? ?? 'fr'),
      whatsappOptIn: json['whatsapp_opt_in'] as bool? ?? true,
    );
  }

  final String id;
  final String phone;
  final String name;
  final AppLang lang;
  final bool whatsappOptIn;
}
