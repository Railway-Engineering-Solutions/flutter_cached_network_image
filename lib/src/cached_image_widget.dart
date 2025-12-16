import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:octo_image/octo_image.dart';

/// Builder function to create an image widget. The function is called after
/// the ImageProvider completes the image loading.
typedef ImageWidgetBuilder = Widget Function(
  BuildContext context,
  ImageProvider imageProvider,
);

/// Builder function to create a placeholder widget. The function is called
/// once while the ImageProvider is loading the image.
typedef PlaceholderWidgetBuilder = Widget Function(
  BuildContext context,
  String url,
);

/// Builder function to create a progress indicator widget. The function is
/// called every time a chuck of the image is downloaded from the web, but at
/// least once during image loading.
typedef ProgressIndicatorBuilder = Widget Function(
  BuildContext context,
  String url,
  DownloadProgress progress,
);

/// Builder function to create an error widget. This builder is called when
/// the image failed loading, for example due to a 404 NotFound exception.
typedef LoadingErrorWidgetBuilder = Widget Function(
  BuildContext context,
  String url,
  Object error,
);

/// Image widget to show NetworkImage with caching functionality.
class CachedNetworkImage extends StatefulWidget {
  /// Get the current log level of the cache manager.
  static CacheManagerLogLevel get logLevel => CacheManager.logLevel;

  /// Set the log level of the cache manager to a [CacheManagerLogLevel].
  static set logLevel(CacheManagerLogLevel level) =>
      CacheManager.logLevel = level;

  /// Evict an image from both the disk file based caching system of the
  /// [BaseCacheManager] as the in memory [ImageCache] of the [ImageProvider].
  /// [url] is used by both the disk and memory cache. The scale is only used
  /// to clear the image from the [ImageCache].
  static Future<bool> evictFromCache(
    String url, {
    String? cacheKey,
    BaseCacheManager? cacheManager,
    double scale = 1,
  }) async {
    final effectiveCacheManager =
        cacheManager ?? CachedNetworkImageProvider.defaultCacheManager;
    await effectiveCacheManager.removeFile(cacheKey ?? url);
    return CachedNetworkImageProvider(url, scale: scale).evict();
  }

  /// Option to use cacheManager with other settings
  final BaseCacheManager? cacheManager;

  /// The target image that is displayed.
  final String imageUrl;

  /// The target image's cache key.
  final String? cacheKey;

  /// Optional builder to further customize the display of the image.
  final ImageWidgetBuilder? imageBuilder;

  /// Widget displayed while the target [imageUrl] is loading.
  final PlaceholderWidgetBuilder? placeholder;

  /// Widget displayed while the target [imageUrl] is loading.
  final ProgressIndicatorBuilder? progressIndicatorBuilder;

  /// Widget displayed while the target [imageUrl] failed loading.
  final LoadingErrorWidgetBuilder? errorWidget;

  /// The duration of the fade-in animation for the [placeholder].
  final Duration? placeholderFadeInDuration;

  /// The duration of the fade-out animation for the [placeholder].
  final Duration? fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [imageUrl].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [imageUrl].
  final Curve fadeInCurve;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, a [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final Alignment alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// children); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with children in right-to-left environments, for
  /// children that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip children with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// Optional headers for the http request of the image url
  final Map<String, String>? httpHeaders;

  /// When set to true it will animate from the old image to the new image
  /// if the url changes.
  final bool useOldImageOnUrlChange;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color? color;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode? colorBlendMode;

  /// Target the interpolation quality for image scaling.
  ///
  /// If not given a value, defaults to FilterQuality.low.
  final FilterQuality filterQuality;

  /// Will resize the image in memory to have a certain width using [ResizeImage]
  final int? memCacheWidth;

  /// Will resize the image in memory to have a certain height using [ResizeImage]
  final int? memCacheHeight;

  /// Will resize the image and store the resized image in the disk cache.
  final int? maxWidthDiskCache;

  /// Will resize the image and store the resized image in the disk cache.
  final int? maxHeightDiskCache;

  /// Listener to be called when images fails to load.
  final ValueChanged<Object>? errorListener;

  /// CachedNetworkImage shows a network image using a caching mechanism. It also
  /// provides support for a placeholder, showing an error and fading into the
  /// loaded image. Next to that it supports most features of a default Image
  /// widget.
  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.httpHeaders,
    this.imageBuilder,
    this.placeholder,
    this.progressIndicatorBuilder,
    this.errorWidget,
    this.fadeOutDuration = const Duration(milliseconds: 1000),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.cacheManager,
    this.useOldImageOnUrlChange = false,
    this.color,
    this.filterQuality = FilterQuality.low,
    this.colorBlendMode,
    this.placeholderFadeInDuration,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheKey,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.errorListener,
    this.scale = 1.0,
  });

  /// Scale of the image
  final double scale;

  @override
  State<CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage> {
  late final CancellationToken _cancellationToken;

  @override
  void initState() {
    super.initState();
    _cancellationToken = CancellationToken();
  }

  @override
  void dispose() {
    _cancellationToken.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImageProvider(
      widget.imageUrl,
      headers: widget.httpHeaders,
      cacheManager: widget.cacheManager,
      cacheKey: widget.cacheKey,
      maxWidth: widget.maxWidthDiskCache,
      maxHeight: widget.maxHeightDiskCache,
      errorListener: widget.errorListener,
      scale: widget.scale,
      cancellationToken: _cancellationToken,
    );
    var octoPlaceholderBuilder =
        widget.placeholder != null ? _octoPlaceholderBuilder : null;
    final octoProgressIndicatorBuilder = widget.progressIndicatorBuilder != null
        ? _octoProgressIndicatorBuilder
        : null;

    ///If there is no placeholder OctoImage does not fade, so always set an
    ///(empty) placeholder as this always used to be the behaviour of
    ///CachedNetworkImage.
    if (octoPlaceholderBuilder == null &&
        octoProgressIndicatorBuilder == null) {
      octoPlaceholderBuilder = (context) => Container();
    }

    return OctoImage(
      image: image,
      imageBuilder: widget.imageBuilder != null ? _octoImageBuilder : null,
      placeholderBuilder: octoPlaceholderBuilder,
      progressIndicatorBuilder: octoProgressIndicatorBuilder,
      errorBuilder: widget.errorWidget != null ? _octoErrorBuilder : null,
      fadeOutDuration: widget.fadeOutDuration,
      fadeOutCurve: widget.fadeOutCurve,
      fadeInDuration: widget.fadeInDuration,
      fadeInCurve: widget.fadeInCurve,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      matchTextDirection: widget.matchTextDirection,
      color: widget.color,
      filterQuality: widget.filterQuality,
      colorBlendMode: widget.colorBlendMode,
      placeholderFadeInDuration: widget.placeholderFadeInDuration,
      gaplessPlayback: widget.useOldImageOnUrlChange,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
    );
  }

  Widget _octoImageBuilder(BuildContext context, Widget child) {
    final image = CachedNetworkImageProvider(
      widget.imageUrl,
      headers: widget.httpHeaders,
      cacheManager: widget.cacheManager,
      cacheKey: widget.cacheKey,
      maxWidth: widget.maxWidthDiskCache,
      maxHeight: widget.maxHeightDiskCache,
      errorListener: widget.errorListener,
      scale: widget.scale,
      cancellationToken: _cancellationToken,
    );
    return widget.imageBuilder!(context, image);
  }

  Widget _octoPlaceholderBuilder(BuildContext context) {
    return widget.placeholder!(context, widget.imageUrl);
  }

  Widget _octoProgressIndicatorBuilder(
    BuildContext context,
    ImageChunkEvent? progress,
  ) {
    int? totalSize;
    var downloaded = 0;
    if (progress != null) {
      totalSize = progress.expectedTotalBytes;
      downloaded = progress.cumulativeBytesLoaded;
    }
    return widget.progressIndicatorBuilder!(
      context,
      widget.imageUrl,
      DownloadProgress(widget.imageUrl, totalSize, downloaded),
    );
  }

  Widget _octoErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return widget.errorWidget!(context, widget.imageUrl, error);
  }
}
