import 'package:material_ui/material_ui.dart';

import '../app_scope.dart';
import '../data/db.dart';
import '../data/snippet_repo.dart';
import '../l10n/app_localizations.dart';
import 'category_chips.dart';
import 'editor_page.dart';
import 'settings_page.dart';
import 'snippet_card.dart';
import 'theme.dart';
import 'upgrade_page.dart';

/// Home One UI (ui-specs §1): 1/3 atas viewing area (judul besar), 2/3 bawah interaksi.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _category;
  late Stream<List<Snippet>> _stream;
  late Stream<int> _count;
  late Stream<bool> _pro;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      final scope = AppScope.of(context);
      _stream = scope.repo.watch();
      _count = scope.repo.watchCount();
      _pro = scope.settings.watchPro();
    }
  }

  void _setCategory(int? c) => setState(() {
        _category = c;
        _stream = AppScope.of(context).repo.watch(category: c);
      });

  void _openEditor([Snippet? s]) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => EditorPage(snippet: s)));

  /// FAB: batas gratis tercapai → Upgrade dulu (ui-specs §1.3); batal → tidak membuka editor.
  Future<void> _add() async {
    if (await AppScope.of(context).repo.atFreeLimit()) {
      if (!mounted || !await UpgradePage.open(context)) return;
    }
    if (mounted) _openEditor();
  }

  Future<void> _delete(Snippet s) async {
    final repo = AppScope.of(context).repo;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final row = await repo.delete(s.id);
    if (row == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.deleted),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: l.undo, onPressed: () => repo.restore(row)),
      ));
  }

  void _showActions(Snippet s) {
    final l = AppLocalizations.of(context);
    final error = Theme.of(context).colorScheme.error;
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l.edit),
            onTap: () {
              Navigator.pop(c);
              _openEditor(s);
            },
          ),
          ListTile(
            leading: Icon(s.pinned ? Icons.push_pin : Icons.push_pin_outlined),
            title: Text(s.pinned ? l.unpin : l.pin),
            onTap: () {
              Navigator.pop(c);
              AppScope.of(context).repo.togglePin(s.id);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: error),
            title: Text(l.delete, style: TextStyle(color: error)),
            onTap: () {
              Navigator.pop(c);
              _delete(s);
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    // design-system §4.2: viewing area dimatikan di landscape / tinggi < 600 dp.
    final viewing = size.height < 600 || size.width > size.height ? null : (size.height * 0.33).clamp(200.0, 320.0);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(l.add),
      ),
      body: StreamBuilder<List<Snippet>>(
        stream: _stream,
        builder: (context, snap) {
          final items = snap.data;
          return CustomScrollView(slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: OneUiSpace.s8,
              expandedHeight: viewing,
              actions: [
                IconButton(
                  tooltip: l.settings,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(start: OneUiSpace.s2, bottom: OneUiSpace.s2),
                expandedTitleScale: 34 / 20, // headerLarge → titleBar
                title: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.appTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge!.copyWith(fontSize: 20)),
                  _counter(l, theme),
                ]),
              ),
            ),
            PinnedHeaderSliver(
              child: ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: CategoryChips(selected: _category, onSelected: _setCategory),
              ),
            ),
            if (items == null)
              const SliverToBoxAdapter()
            else if (items.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _empty(l, theme))
            else
              SliverPadding(
                // bawah: ruang FAB 56 + 16 + inset nav bar agar kartu terakhir tidak tertutup.
                padding: EdgeInsets.fromLTRB(OneUiSpace.s2, OneUiSpace.s1, OneUiSpace.s2,
                    OneUiSpace.s7 + OneUiSpace.s4 + MediaQuery.paddingOf(context).bottom),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: OneUiSpace.s1),
                  itemBuilder: (_, i) => SnippetCard(
                    key: ValueKey(items[i].id),
                    snippet: items[i],
                    onLongPress: () => _showActions(items[i]),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }

  /// "x/10 snippet" hanya untuk gratis (FR-033); 10/10 → warna primary + tautan Upgrade.
  Widget _counter(AppLocalizations l, ThemeData theme) => StreamBuilder<bool>(
        stream: _pro,
        builder: (_, pro) => pro.data ?? true // sembunyikan sampai status diketahui
            ? const SizedBox.shrink()
            : StreamBuilder<int>(
                stream: _count,
                builder: (_, c) {
                  final n = c.data ?? 0;
                  final full = n >= SnippetRepo.freeLimit;
                  final style = theme.textTheme.labelSmall!
                      .copyWith(color: full ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant);
                  final text = Text(full ? '${l.snippetCount(n)} · ${l.upgrade}' : l.snippetCount(n), style: style);
                  return full ? InkWell(onTap: () => UpgradePage.open(context), child: text) : text;
                },
              ),
      );

  Widget _empty(AppLocalizations l, ThemeData theme) {
    if (_category != null) {
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(l.noResults, style: theme.textTheme.bodyMedium),
        TextButton(onPressed: () => _setCategory(null), child: Text(l.clearFilter)),
      ]);
    }
    return Padding(
      padding: const EdgeInsets.all(OneUiSpace.s3),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 96,
          height: 96,
          decoration: ShapeDecoration(color: theme.colorScheme.primaryContainer, shape: OneUiRadius.squircle),
          child: Icon(Icons.content_paste, size: 40, color: theme.colorScheme.onPrimaryContainer),
        ),
        const SizedBox(height: OneUiSpace.s3),
        Text(l.emptyState, style: theme.textTheme.titleLarge),
        const SizedBox(height: OneUiSpace.s1),
        Text(l.emptyBody, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: OneUiSpace.s3),
        FilledButton(onPressed: _openEditor, child: Text(l.createFirst)),
      ]),
    );
  }
}
