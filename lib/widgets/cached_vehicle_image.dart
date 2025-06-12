import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/vehicle.dart';

class CachedVehicleImage extends StatelessWidget {
  final Vehicle? vehicle;
  final double radius;
  final Widget? child;
  final VoidCallback? onTap;
  final Function(Object, StackTrace?)? onError;

  const CachedVehicleImage({
    super.key,
    this.vehicle,
    required this.radius,
    this.child,
    this.onTap,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primary,
        backgroundImage: _getImageProvider(),
        onBackgroundImageError: onError,
        child: _getImageProvider() == null ? child : null,
      ),
    );
  }

  ImageProvider? _getImageProvider() {
    if (vehicle == null) return null;

    final photoSource = vehicle!.bestPhotoSource;
    if (photoSource == null || photoSource.isEmpty) return null;

    if (photoSource.startsWith('http')) {
      // Use cached network image for URLs
      final cacheKey = _generateCacheKey(photoSource);
      print(
          'CachedVehicleImage: Loading image for ${vehicle!.make} ${vehicle!.model} with cache key: $cacheKey');
      return CachedNetworkImageProvider(
        photoSource,
        cacheKey: cacheKey,
      );
    } else {
      // Use file image for local paths
      print(
          'CachedVehicleImage: Loading local image for ${vehicle!.make} ${vehicle!.model}: $photoSource');
      return FileImage(File(photoSource));
    }
  }

  String _generateCacheKey(String url) {
    // Generate a cache key based on the URL and vehicle ID
    // This ensures each vehicle has its own cached image
    final vehicleId = vehicle?.id ?? 'unknown';
    return '${vehicleId}_${url.hashCode}';
  }
}

class CachedVehicleImageWidget extends StatelessWidget {
  final Vehicle? vehicle;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedVehicleImageWidget({
    super.key,
    this.vehicle,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (vehicle == null) {
      return _buildDefaultWidget(context);
    }

    final photoSource = vehicle!.bestPhotoSource;
    if (photoSource == null || photoSource.isEmpty) {
      return _buildDefaultWidget(context);
    }

    if (photoSource.startsWith('http')) {
      final cacheKey = _generateCacheKey(photoSource);
      print(
          'CachedVehicleImageWidget: Loading image for ${vehicle!.make} ${vehicle!.model} with cache key: $cacheKey');

      return CachedNetworkImage(
        imageUrl: photoSource,
        width: width,
        height: height,
        fit: fit,
        cacheKey: cacheKey,
        placeholder: (context, url) {
          print(
              'CachedVehicleImageWidget: Showing placeholder for ${vehicle!.make} ${vehicle!.model} - downloading...');
          return placeholder ?? _buildPlaceholder(context);
        },
        errorWidget: (context, url, error) {
          print('CachedVehicleImageWidget: Error loading $url - $error');
          return errorWidget ?? _buildErrorWidget(context);
        },
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        // Add cache status logging
        imageBuilder: (context, imageProvider) {
          print(
              'CachedVehicleImageWidget: Successfully loaded cached image for ${vehicle!.make} ${vehicle!.model}');
          return Image(
            image: imageProvider,
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    } else {
      print(
          'CachedVehicleImageWidget: Loading local file for ${vehicle!.make} ${vehicle!.model}: $photoSource');
      return Image.file(
        File(photoSource),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          print(
              'CachedVehicleImageWidget: Error loading local file $photoSource - $error');
          return errorWidget ?? _buildErrorWidget(context);
        },
      );
    }
  }

  Widget _buildDefaultWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.directions_car,
        color: Colors.white,
        size: width * 0.5,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.directions_car,
        color: Colors.white,
        size: width * 0.5,
      ),
    );
  }

  String _generateCacheKey(String url) {
    final vehicleId = vehicle?.id ?? 'unknown';
    return '${vehicleId}_${url.hashCode}';
  }
}
