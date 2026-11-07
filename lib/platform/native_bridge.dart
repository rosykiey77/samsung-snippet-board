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

  /// `ok` atau `needsPermission` (izin tampil di atas app belum diberikan).
  Future<String> setOverlayEnabled(bool enabled) async =>
      (await _channel.invokeMapMethod<String, Object?>('setOverlayEnabled', {'enabled': enabled}))!['status']!
          as String;

  Future<void> openOverlayPermission() => _channel.invokeMethod<void>('openOverlayPermission');

  /// false = API < 33, UI menampilkan instruksi manual.
  Future<bool> requestAddTile() async => await _channel.invokeMethod<bool>('requestAddTile') ?? false;

  /// `{edgeSupported, edge, tile, overlayPermission}`.
  Future<Map<String, bool>> surfaceStatus() async =>
      (await _channel.invokeMapMethod<String, bool>('surfaceStatus'))!;

  Future<void> setSurfaceEnabled(String surface, bool enabled) =>
      _channel.invokeMethod<void>('setSurfaceEnabled', {'surface': surface, 'enabled': enabled});

  /// null = pengguna membatalkan pemilih file.
  Future<bool?> saveDocument(String name, String content) =>
      _channel.invokeMethod<bool>('saveDocument', {'name': name, 'content': content});

  Future<String?> openDocument() => _channel.invokeMethod<String>('openDocument');

  /// Harga lokal `pro_lifetime`. Error `IAP_UNAVAILABLE` jika Galaxy Store tidak ada.
  Future<String> iapProduct() async =>
      (await _channel.invokeMapMethod<String, Object?>('iapProduct'))!['price']! as String;

  /// true = terbeli (Kotlin sudah menulis `is_pro=1`), false = dibatalkan. Error `IAP_UNAVAILABLE`/`IAP_FAILED`.
  Future<bool> iapPurchase() async =>
      (await _channel.invokeMapMethod<String, Object?>('iapPurchase'))!['status'] == 'purchased';

  /// Status Pro dari Galaxy Store (Kotlin menulis hasilnya ke `settings`).
  Future<bool> iapRestore() async =>
      (await _channel.invokeMapMethod<String, Object?>('iapRestore'))!['isPro'] == true;
}
