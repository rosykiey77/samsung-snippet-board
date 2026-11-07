import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import '../app_scope.dart';
import '../data/db.dart';
import '../data/mask.dart';
import '../l10n/app_localizations.dart';
import '../platform/native_bridge.dart';
import 'category_chips.dart';
import 'theme.dart';
import 'variable_dialog.dart';

/// Quick Copy Card (ui-specs §2). Ketuk = salin. Haptic + konfirmasi sistem dari native `Copier`
/// (design-system §8), jadi Flutter hanya menampilkan state "Disalin" inline.
class SnippetCard extends StatefulWidget {
  const SnippetCard({super.key, required this.snippet, required this.onLongPress});

  final Snippet snippet;
  final VoidCallback onLongPress;

  @override
  State<SnippetCard> createState() => _SnippetCardState();
}

class _SnippetCardState extends State<SnippetCard> with WidgetsBindingObserver {
  bool _pressed = false, _copied = false, _revealed = false;
  Timer? _copiedTimer, _revealTimer;

  bool get _sensitive => widget.snippet.category == Category.account;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _copiedTimer?.cancel();
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _revealed) setState(() => _revealed = false);
  }

  Future<void> _copy() async {
    final s = widget.snippet;
    final l = AppLocalizations.of(context);
    final bridge = AppScope.of(context).bridge;
    try {
      var r = await bridge.copySnippet(s.id);
      if (r is NeedsInput) {
        if (!mounted) return;
        final values = await showVariableDialog(context, r.missing);
        if (values == null) return; // batal → tidak menyalin
        r = await bridge.copySnippet(s.id, overrides: values);
      }
      if (!mounted || r is! Copied) return;
      setState(() => _copied = true);
      _copiedTimer?.cancel(); // tap beruntun me-reset hold
      _copiedTimer = Timer(OneUiMotion.copiedHold, () {
        if (mounted) setState(() => _copied = false);
      });
      unawaited(SemanticsService.sendAnnouncement(View.of(context), l.copiedAnnounce(s.title), Directionality.of(context)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copyFailed)));
    }
  }

  void _toggleReveal() {
    setState(() => _revealed = !_revealed);
    _revealTimer?.cancel();
    if (_revealed) {
      _revealTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() => _revealed = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snippet;
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<OneUiColors>()!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final preview = _sensitive && !_revealed ? maskSensitive(s.body) : s.body;

    return Semantics(
      button: true,
      label: '${s.title}. ${_sensitive ? maskSensitive(s.body) : s.body}. '
          '${l.categoryLabel} ${categoryLabel(l, s.category)}${s.pinned ? ', ${l.pinned}' : ''}',
      hint: l.tapToCopy,
      onLongPressHint: l.moreOptions,
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? 0.97 : 1,
        duration: _pressed ? OneUiMotion.press : OneUiMotion.release,
        curve: OneUiMotion.standard,
        child: AnimatedContainer(
          duration: OneUiMotion.copied,
          decoration: ShapeDecoration(
            color: _pressed ? colors.surfacePressed : theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(OneUiRadius.card)),
              side: BorderSide(color: _copied ? colors.success : Colors.transparent, width: 2),
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: OneUiRadius.cardShape,
              onTap: _copy,
              onLongPress: widget.onLongPress,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 80),
                child: Padding(
                  padding: const EdgeInsets.all(OneUiSpace.s2),
                  child: Row(children: [
                    _leading(colors, reduceMotion),
                    const SizedBox(width: OneUiSpace.s2),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                        const SizedBox(height: OneUiSpace.half),
                        _copied
                            ? Text(l.copied, style: theme.textTheme.labelLarge!.copyWith(color: colors.success))
                            : AnimatedSwitcher(
                                duration: reduceMotion ? Duration.zero : OneUiMotion.reveal,
                                child: Text(
                                  preview,
                                  key: ValueKey(_revealed),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                      ]),
                    ),
                    if (s.pinned)
                      Icon(Icons.push_pin, size: OneUiIconSize.sm, color: theme.colorScheme.primary),
                    if (_sensitive)
                      IconButton(
                        tooltip: _revealed ? l.hideNumber : l.showNumber,
                        icon: Icon(_revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: _toggleReveal,
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _leading(OneUiColors colors, bool reduceMotion) {
    final c = widget.snippet.category;
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : OneUiMotion.copied,
      child: Container(
        key: ValueKey(_copied),
        width: 40,
        height: 40,
        decoration: ShapeDecoration(
          color: _copied ? colors.success.withValues(alpha: 0.16) : colors.categoryContainer[c],
          shape: OneUiRadius.squircle,
        ),
        child: Icon(_copied ? Icons.check : categoryIcons[c],
            size: OneUiIconSize.md, color: _copied ? colors.success : colors.category[c]),
      ),
    );
  }
}
