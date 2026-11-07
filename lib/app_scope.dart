import 'package:flutter/widgets.dart';

import 'data/db.dart';
import 'data/snippet_repo.dart';
import 'platform/native_bridge.dart';

/// Dependensi app untuk seluruh pohon widget (tanpa library DI/state-management, plan.md).
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.db, required this.repo, required this.bridge, required super.child});

  final AppDb db;
  final SnippetRepo repo;
  final NativeBridge bridge;

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => false; // instance tetap seumur app
}
