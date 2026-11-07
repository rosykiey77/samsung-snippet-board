import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

/// Upgrade Pro (ui-specs §10.2). Pop `true` = Pro aktif (beli/pulihkan berhasil).
class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});

  /// Buka Upgrade; true jika pengguna sekarang Pro.
  static Future<bool> open(BuildContext context) async =>
      await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const UpgradePage())) ?? false;

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  String? _price;
  String? _unavailable; // pesan saat harga tidak bisa diambil
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrice());
  }

  Future<void> _loadPrice() async {
    final l = AppLocalizations.of(context);
    try {
      final p = await AppScope.of(context).bridge.iapProduct();
      if (mounted) setState(() => _price = p);
    } on PlatformException catch (e) {
      if (mounted) setState(() => _unavailable = e.code == 'IAP_UNAVAILABLE' ? l.iapUnavailable : l.iapFailed);
    }
  }

  /// [action] true → Pro aktif → tutup layar; false → tampilkan [falseMsg]. Error tidak mengubah data.
  Future<void> _run(Future<bool> Function() action, String falseMsg) async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    String msg;
    try {
      if (await action()) {
        if (mounted) Navigator.pop(context, true);
        return;
      }
      msg = falseMsg;
    } on PlatformException catch (e) {
      msg = e.code == 'IAP_UNAVAILABLE' ? l.iapUnavailable : l.iapFailed;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = AppScope.of(context).settings;
    final price = _price;

    Widget benefit(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: OneUiSpace.s1),
          child: Row(children: [
            Icon(icon, size: 24, color: scheme.primary),
            const SizedBox(width: OneUiSpace.s2),
            Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
          ]),
        );

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(OneUiSpace.s3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Viewing area: squircle 72 + judul besar.
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: ShapeDecoration(color: scheme.primaryContainer, shape: OneUiRadius.squircle),
                  child: Icon(Icons.workspace_premium_outlined, size: 36, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: OneUiSpace.s2),
                Text(l.proTitle, style: theme.textTheme.displaySmall),
                const SizedBox(height: OneUiSpace.s3),
              ]),
            ),
            benefit(Icons.all_inclusive, l.proUnlimited),
            benefit(Icons.verified_outlined, l.proLifetime),
            benefit(Icons.cloud_off_outlined, l.proOffline),
            const SizedBox(height: OneUiSpace.s3),
            if (_unavailable != null)
              Padding(
                padding: const EdgeInsets.only(bottom: OneUiSpace.s1),
                child: Text(_unavailable!, style: theme.textTheme.bodyMedium!.copyWith(color: scheme.error)),
              ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(OneUiSpace.s7), shape: const StadiumBorder()),
              onPressed: price == null || _busy ? null : () => _run(settings.purchasePro, l.iapCancelled),
              child: price != null
                  ? Text(l.buyFor(price))
                  : _unavailable != null
                      ? Text(l.upgradeToPro)
                      // skeleton pill harga selagi memuat
                      : Container(
                          width: 120,
                          height: 20,
                          decoration: ShapeDecoration(color: scheme.onSurface.withValues(alpha: 0.12), shape: const StadiumBorder()),
                        ),
            ),
            const SizedBox(height: OneUiSpace.s1),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => _run(settings.restorePro, l.restoreNone),
                child: Text(l.restorePurchase),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
