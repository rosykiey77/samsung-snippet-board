import 'package:flutter/services.dart';

/// Hasil `copySnippet` (docs/contracts/method-channel.md).
sealed class CopyResult {
  const CopyResult();
}

final class Copied extends CopyResult {
  const Copied();
}

final class NeedsInput extends CopyResult {
  const NeedsInput(this.missing);
  final List<String> missing; // 'nama' | 'rekening'
}

/// Wrapper channel `snippetboard/native`. Error native → [PlatformException] (mis. `NOT_FOUND`).
class NativeBridge {
  const NativeBridge([this._channel = const MethodChannel('snippetboard/native')]);
  final MethodChannel _channel;

  Future<CopyResult> copySnippet(int id, {Map<String, String> overrides = const {}}) async {
    final r = (await _channel.invokeMapMethod<String, Object?>(
        'copySnippet', {'id': id, 'overrides': overrides}))!;
    return switch (r['status']) {
      'copied' => const Copied(),
      'needsInput' => NeedsInput((r['missing']! as List<Object?>).cast<String>()),
      final s => throw PlatformException(code: 'BAD_STATUS', message: '$s'),
    };
  }

  Future<void> refreshSurfaces() => _channel.invokeMethod<void>('refreshSurfaces');

  Future<bool> edgePanelSupported() async =>
      await _channel.invokeMethod<bool>('edgePanelSupported') ?? false;
}
