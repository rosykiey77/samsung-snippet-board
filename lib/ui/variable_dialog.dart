import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'theme.dart';

/// Dialog isian variabel (ui-specs §6.1). [missing] berisi 'nama' | 'rekening'.
/// Mengembalikan nilai per variabel, atau null saat batal (tidak menyalin apa pun, FR-017).
Future<Map<String, String>?> showVariableDialog(BuildContext context, List<String> missing) =>
    showDialog<Map<String, String>>(context: context, builder: (_) => _VariableDialog(missing));

class _VariableDialog extends StatefulWidget {
  const _VariableDialog(this.missing);
  final List<String> missing;

  @override
  State<_VariableDialog> createState() => _VariableDialogState();
}

class _VariableDialogState extends State<_VariableDialog> {
  late final _ctrls = {for (final v in widget.missing) v: TextEditingController()};

  bool get _complete => _ctrls.values.every((c) => c.text.trim().isNotEmpty);

  void _submit() {
    if (_complete) Navigator.pop(context, {for (final e in _ctrls.entries) e.key: e.value.text.trim()});
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final last = widget.missing.last;
    return Dialog(
      // dialog One UI melayang di bawah (thumb zone).
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.all(OneUiSpace.s2),
      child: Padding(
        padding: const EdgeInsets.all(OneUiSpace.s3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.fillVariables, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: OneUiSpace.s2),
            for (final v in widget.missing) ...[
              Text(v == 'rekening' ? l.varRekening : l.varNama, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: OneUiSpace.half),
              TextField(
                controller: _ctrls[v],
                autofocus: v == widget.missing.first,
                keyboardType: v == 'rekening' ? TextInputType.number : TextInputType.name,
                textInputAction: v == last ? TextInputAction.done : TextInputAction.next,
                onChanged: (_) => setState(() {}),
                onSubmitted: v == last ? (_) => _submit() : null,
              ),
              const SizedBox(height: OneUiSpace.s1_5),
            ],
            Row(children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel))),
              Expanded(child: TextButton(onPressed: _complete ? _submit : null, child: Text(l.copy))),
            ]),
          ],
        ),
      ),
    );
  }
}
