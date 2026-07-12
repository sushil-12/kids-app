import 'package:equatable/equatable.dart';

/// A drawing the child saved from the Creative Canvas. The rendered canvas is
/// stored as a base64-encoded PNG so the Hive box stays adapter-free (mirroring
/// the rest of the app's persistence — plain values only).
class CreativeArtwork extends Equatable {
  const CreativeArtwork({
    required this.id,
    required this.createdAtMs,
    required this.pngBase64,
  });

  /// Unique id (also the Hive map key).
  final String id;

  /// Creation time in epoch milliseconds; the gallery shows newest first.
  final int createdAtMs;

  /// The drawing as a base64-encoded PNG.
  final String pngBase64;

  /// Serializes to a plain map for Hive (no custom adapter needed).
  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'createdAtMs': createdAtMs,
        'png': pngBase64,
      };

  /// Reads back a map written by [toMap]; returns null if it is malformed.
  static CreativeArtwork? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final dynamic id = raw['id'];
    final dynamic created = raw['createdAtMs'];
    final dynamic png = raw['png'];
    if (id is! String || created is! int || png is! String) return null;
    return CreativeArtwork(id: id, createdAtMs: created, pngBase64: png);
  }

  @override
  List<Object?> get props => <Object?>[id, createdAtMs, pngBase64];
}
