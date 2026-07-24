import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A backend-served illustration with the app's loading manners: fades in
/// when the (disk-cached) image arrives and renders **nothing** while loading
/// or on failure — callers keep their own fallback visible underneath, so a
/// child never sees a spinner or a broken-image icon.
class RemoteIllustration extends StatelessWidget {
  const RemoteIllustration({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 500),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (BuildContext context, String url) =>
          const SizedBox.shrink(),
      errorWidget: (BuildContext context, String url, Object error) =>
          const SizedBox.shrink(),
    );
  }
}

/// The cache-backed [ImageProvider] for an illustration URL — for
/// `precacheImage` warm-ups without leaking the cache package to callers.
ImageProvider<Object> illustrationProvider(String url) =>
    CachedNetworkImageProvider(url);

/// Resolves [url] through the shared image cache and reports whether a frame
/// is actually available, so layout code can swap layers (e.g. hide the
/// vector stage's characters only once the illustration is really on screen).
/// Errors just mean [onReady] never fires — no error surface.
class IllustrationPreloader {
  IllustrationPreloader({required this.url, required this.onReady});

  final String url;
  final VoidCallback onReady;

  ImageStream? _stream;
  ImageStreamListener? _listener;

  void start() {
    final ImageStream stream =
        CachedNetworkImageProvider(url).resolve(ImageConfiguration.empty);
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool syncCall) {
        info.dispose();
        onReady();
      },
      onError: (Object error, StackTrace? stackTrace) {
        // Unreachable URL → the caller simply keeps its fallback visible.
      },
    );
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void dispose() {
    final ImageStreamListener? listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }
}
