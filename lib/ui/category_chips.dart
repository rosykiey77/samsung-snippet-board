import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../data/db.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

String categoryLabel(AppLocalizations l, int c) =>
    [l.categoryPersonal, l.categoryWork, l.categoryAccount, l.categoryChatTemplate][c];

const categoryIcons = [Icons.person_outline, Icons.work_outline, Icons.account_balance_outlined, Icons.chat_bubble_outline];

/// Pills kategori (ui-specs §3). Home: scroll horizontal + "Semua" (null). Editor: [wrap], tanpa "Semua".
class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key, required this.selected, required this.onSelected, this.wrap = false});

  final int? selected;
  final ValueChanged<int?> onSelected;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<OneUiColors>()!;
    final onSel = Theme.of(context).colorScheme.onPrimary;

    Widget chip(int? c) {
      final isSel = selected == c;
      return Semantics(
        label: 'Filter ${c == null ? l.categoryAll : categoryLabel(l, c)}',
        excludeSemantics: true,
        selected: isSel,
        button: true,
        child: FilterChip(
          selected: isSel,
          showCheckmark: false,
          // status terpilih tidak hanya lewat warna: titik → ikon check.
          avatar: isSel
              ? Icon(Icons.check, size: 18, color: onSel)
              : c == null
                  ? null
                  : Icon(Icons.circle, size: 8, color: colors.category[c]),
          label: Text(c == null ? l.categoryAll : categoryLabel(l, c)),
          labelStyle: isSel ? TextStyle(color: onSel) : null,
          onSelected: (_) {
            HapticFeedback.selectionClick();
            // Home: ketuk chip terpilih → kembali ke Semua. Editor: kategori wajib, abaikan.
            if (!isSel) {
              onSelected(c);
            } else if (!wrap && c != null) {
              onSelected(null);
            }
          },
        ),
      );
    }

    if (wrap) {
      return Wrap(spacing: OneUiSpace.s1, runSpacing: OneUiSpace.s1, children: [for (final c in Category.values) chip(c)]);
    }
    return SizedBox(
      height: OneUiSpace.s7,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: OneUiSpace.s2),
        itemCount: Category.values.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: OneUiSpace.s1),
        itemBuilder: (_, i) => Center(child: chip(i == 0 ? null : Category.values[i - 1])),
      ),
    );
  }
}
