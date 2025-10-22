// lib/widgets/save_action_icon.dart
import 'package:flutter/material.dart';
import '../services/saves_service.dart';
import 'save_picker_bottom_sheet.dart';

class SaveActionIcon extends StatelessWidget {
  final String businessId;
  const SaveActionIcon({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: SavesService.listsStream(businessId),
      builder: (context, snap) {
        final lists = snap.data ?? const <String>[];
        final isSaved = lists.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _openSheet(context, lists),
            child: Tooltip(
              message: 'Save',
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBFF),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: const Color(0xFF201E50),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSheet(BuildContext context, List<String> current) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          SavePickerBottomSheet(businessId: businessId, current: current),
    );
  }
}
