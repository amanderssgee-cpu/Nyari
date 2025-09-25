import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';

/// Tiny helper for static strings.
/// Usage:  Text(tr(context, en: 'Search', id: 'Cari'));
String tr(BuildContext ctx, {required String en, required String id}) {
  final isIndo = ctx.read<LanguageProvider>().isIndo;
  return isIndo ? id : en;
}
