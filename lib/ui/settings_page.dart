import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app_scope.dart';
import '../data/mask.dart';
import '../data/settings_repo.dart';
import '../data/snippet_repo.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';
import 'upgrade_page.dart';

/// Pengaturan One UI (ui-specs §10.1): header besar lalu grup kartu berisi baris.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
  Map<String, bool>? _status; // surfaceStatus native
  bool _wantOverlay = false; // menunggu pengguna kembali dari halaman izin

  SettingsRepo get _repo => AppScope.of(context).settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatus());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadStatus();
  }

  Future<void> _loadStatus() async {
    final s = await AppScope.of(context).bridge.surfaceStatus();
    if (!mounted) return;
    setState(() => _status = s);
    if (_wantOverlay && s['overlayPermission'] == true) {
      _wantOverlay = false;
      await _repo.setOverlay(true);
    }
  }

  Future<void> _editVariable(String key, String label, String? current) async {
    var text = current ?? ''; // tanpa controller: dialog masih dianimasikan setelah pop
    final l = AppLocalizations.of(context);
    final value = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(label),
        content: TextFormField(
          initialValue: current,
          onChanged: (v) => text = v,
          autofocus: true,
          keyboardType: key == SettingsRepo.varRekening ? TextInputType.number : TextInputType.name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l.notSet),
          onFieldSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, text), child: Text(l.save)),
        ],
      ),
    );
    if (value != null) await _repo.setVariable(key, value);
  }

  Future<void> _toggleOverlay(bool on) async {
    if (await _repo.setOverlay(on) || !mounted) return;
    // FR-023: jelaskan dulu alasan izin sebelum membuka halaman sistem.
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.overlayPermissionTitle),
        content: Text(l.overlayPermissionBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.openSettings)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _wantOverlay = true;
    await AppScope.of(context).bridge.openOverlayPermission();
  }

  Future<void> _setSurface(String surface, bool on) async {
    final bridge = AppScope.of(context).bridge;
    await bridge.setSurfaceEnabled(surface, on);
    if (surface == 'tile' && on) await _addTile();
    await _loadStatus();
  }

  Future<void> _addTile() async {
    final bridge = AppScope.of(context).bridge;
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    if (!await bridge.requestAddTile()) messenger.showSnackBar(SnackBar(content: Text(l.tileManual)));
  }

  Future<void> _export() async {
    final bridge = AppScope.of(context).bridge;
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    final date = DateTime.now().toIso8601String().substring(0, 10);
    try {
      if (await bridge.saveDocument('snippetboard-$date.json', await _repo.exportJson()) == true) {
        messenger.showSnackBar(SnackBar(content: Text(l.exportDone)));
      }
    } on PlatformException {
      messenger.showSnackBar(SnackBar(content: Text(l.fileError)));
    }
  }

  Future<void> _import() async {
    final bridge = AppScope.of(context).bridge;
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    String msg;
    try {
      final text = await bridge.openDocument();
      if (text == null) return;
      msg = l.importDone(await _repo.importJson(text));
    } on ImportInvalid {
      msg = l.importInvalid;
    } on FreeLimitReached {
      msg = l.freeLimitBody;
    } on PlatformException {
      msg = l.fileError;
    }
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _restore() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    String msg;
    try {
      msg = await _repo.restorePro() ? l.restoreDone : l.restoreNone;
    } on PlatformException catch (e) {
      msg = e.code == 'IAP_UNAVAILABLE' ? l.iapUnavailable : l.iapFailed;
    }
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final viewing = size.height < 600 || size.width > size.height ? null : (size.height * 0.33).clamp(200.0, 320.0);
    final s = _status;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          toolbarHeight: OneUiSpace.s8,
          expandedHeight: viewing,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: OneUiSpace.s7, bottom: OneUiSpace.s2),
            expandedTitleScale: 34 / 20,
            title: Text(l.settings, style: theme.textTheme.titleLarge!.copyWith(fontSize: 20)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(OneUiSpace.s2, 0, OneUiSpace.s2, OneUiSpace.s3),
          sliver: SliverList.list(children: [
            _Group(l.variablesGroup, [
              _varRow(SettingsRepo.varNama, l.defaultNama, (v) => v),
              _varRow(SettingsRepo.varRekening, l.defaultRekening, maskSensitive),
            ]),
            _Group(l.quickAccessGroup, [
              if (s?['edgeSupported'] ?? false)
                SwitchListTile(
                  title: Text(l.edgePanel),
                  subtitle: Text(l.edgePanelHint),
                  value: s!['edge']!,
                  onChanged: (v) => _setSurface('edge', v),
                ),
              SwitchListTile(
                title: Text(l.quickTile),
                subtitle: Text(l.quickTileHint),
                value: s?['tile'] ?? true,
                onChanged: s == null ? null : (v) => _setSurface('tile', v),
              ),
              if (s?['tile'] ?? false) ListTile(title: Text(l.addTile), onTap: _addTile),
              StreamBuilder<String?>(
                stream: _repo.watch(SettingsRepo.overlayEnabled),
                builder: (_, snap) => SwitchListTile(
                  title: Text(l.overlay),
                  subtitle: Text(l.overlayHint),
                  value: snap.data == '1' && (s?['overlayPermission'] ?? false),
                  onChanged: s == null ? null : _toggleOverlay,
                ),
              ),
            ]),
            _Group(l.proGroup, [
              StreamBuilder<bool>(
                stream: _repo.watchPro(),
                builder: (context, snap) => snap.data ?? false
                    ? ListTile(leading: const Icon(Icons.workspace_premium), title: Text(l.proActive))
                    : ListTile(
                        leading: const Icon(Icons.workspace_premium_outlined),
                        title: Text(l.upgradeToPro),
                        onTap: () => UpgradePage.open(context)),
              ),
              ListTile(leading: const Icon(Icons.restore), title: Text(l.restorePurchase), onTap: _restore),
            ]),
            _Group(l.dataGroup, [
              ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: Text(l.exportData),
                  subtitle: Text(l.exportHint),
                  onTap: _export),
              ListTile(leading: const Icon(Icons.download_outlined), title: Text(l.importData), onTap: _import),
            ]),
            _Group(l.aboutGroup, [
              ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: Text(l.privacy),
                subtitle: Text(l.privacyBody),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _varRow(String key, String label, String Function(String) display) => StreamBuilder<String?>(
        stream: _repo.watch(key),
        builder: (context, snap) {
          final v = snap.data ?? '';
          return ListTile(
            title: Text(label),
            subtitle: Text(v.isEmpty ? AppLocalizations.of(context).notSet : display(v)),
            onTap: () => _editVariable(key, label, v),
          );
        },
      );
}

/// Grup kartu radius 26 dengan judul kecil dan divider inset 16 (ui-specs §10.1).
class _Group extends StatelessWidget {
  const _Group(this.title, this.rows);
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: OneUiSpace.s2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(OneUiSpace.s2, 0, OneUiSpace.s2, OneUiSpace.s1),
          child: Text(title,
              style: theme.textTheme.labelMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: OneUiSpace.s2, endIndent: OneUiSpace.s2),
              rows[i],
            ],
          ]),
        ),
      ]),
    );
  }
}
