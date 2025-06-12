import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // Get the default cache manager
  CacheManager get cacheManager => DefaultCacheManager();

  // Clear all cached images
  Future<void> clearAllCache() async {
    await cacheManager.emptyCache();
    print('ImageCacheService: All cached images cleared');
  }

  // Clear cache for a specific URL
  Future<void> clearCacheForUrl(String url) async {
    await cacheManager.removeFile(url);
    print('ImageCacheService: Cache cleared for URL: $url');
  }

  // Check if an image is cached
  Future<bool> isImageCached(String url) async {
    final fileInfo = await cacheManager.getFileFromCache(url);
    return fileInfo != null;
  }

  // Get cache size information
  Future<Map<String, dynamic>> getCacheInfo() async {
    // Note: This is a simplified version. For detailed cache info,
    // you might need to implement custom cache manager
    try {
      return {
        'cacheDirectory': 'System managed',
        'status': 'Active',
      };
    } catch (e) {
      return {
        'cacheDirectory': 'Error getting cache info',
        'status': 'Error: $e',
      };
    }
  }

  // Preload an image into cache
  Future<void> preloadImage(String url, {String? cacheKey}) async {
    try {
      await cacheManager.downloadFile(url, key: cacheKey);
      print('ImageCacheService: Preloaded image: $url');
    } catch (e) {
      print('ImageCacheService: Failed to preload image $url - $e');
    }
  }

  // Generate a cache key for a vehicle image
  String generateVehicleCacheKey(String vehicleId, String url) {
    return '${vehicleId}_${url.hashCode}';
  }
}
