import 'package:material_ui/material_ui.dart';

import '../app_scope.dart';
import '../data/db.dart';
import '../data/mask.dart';
import '../data/snippet_repo.dart';
import '../l10n/app_localizations.dart';
import 'category_chips.dart';
import 'theme.dart';

/// Tambah ([snippet] null) atau edit snippet (ui-specs §9).
class EditorPage extends StatefulWidget {
  const EditorPage({super.key, this.snippet});
  final Snippet? snippet;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final _title = TextEditingController(text: widget.snippet?.title);
  late final _body = TextEditingController(text: widget.snippet?.body);
  late int _category = widget.snippet?.category ?? Category.personal;
  String? _error; // 'title' | 'body'
  bool _saving = false;

  bool get _dirty =>
      _title.text != (widget.snippet?.title ?? '') ||
      _body.text != (widget.snippet?.body ?? '') ||
      _category != (widget.snippet?.category ?? Category.personal);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final repo = AppScope.of(context).repo;
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final s = widget.snippet;
      if (s == null) {
        await repo.create(title: _title.text, body: _body.text, category: _category);
      } else {
        await repo.update(s.id, title: _title.text, body: _body.text, category: _category);
      }
      if (mounted) Navigator.pop(context, true);
    } on SnippetInvalid catch (e) {
      setState(() => _error = e.field);
    } on FreeLimitReached {
      // shortcut: dialog sementara, diganti layar Upgrade di US6 (T053).
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(l.freeLimitTitle),
            content: Text(l.freeLimitBody),
            actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(l.ok))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDiscard() async {
    final l = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.discardTitle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.keepEditing)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.discard)),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = theme.textTheme.labelMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final previewBody = _category == Category.account ? maskSensitive(_body.text) : _body.text;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.snippet == null ? l.newSnippet : l.editSnippet),
          actions: [TextButton(onPressed: _saving ? null : _save, child: Text(l.save))],
        ),
        body: ListView(
          padding: const EdgeInsets.all(OneUiSpace.s2),
          children: [
            Text(l.titleLabel, style: label),
            const SizedBox(height: OneUiSpace.half),
            TextField(
              controller: _title,
              maxLength: SnippetRepo.maxTitle,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: l.titleHint,
                errorText: _error == 'title' ? l.titleTooLong : null,
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            Text(l.categoryLabel, style: label),
            const SizedBox(height: OneUiSpace.s1),
            CategoryChips(wrap: true, selected: _category, onSelected: (c) => setState(() => _category = c!)),
            const SizedBox(height: OneUiSpace.s2),
            Text(l.bodyLabel, style: label),
            const SizedBox(height: OneUiSpace.half),
            TextField(
              controller: _body,
              maxLength: SnippetRepo.maxBody,
              minLines: 6,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(errorText: _error == 'body' ? l.bodyEmpty : null),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_body.text.trim().isNotEmpty) ...[
              Text(l.preview, style: label),
              const SizedBox(height: OneUiSpace.s1),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(OneUiSpace.s2),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_title.text.trim().isEmpty ? l.titleHint : _title.text.trim(),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                    const SizedBox(height: OneUiSpace.half),
                    Text(previewBody, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: OneUiSpace.s3),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(OneUiSpace.s7), shape: const StadiumBorder()),
              onPressed: _saving ? null : _save,
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
