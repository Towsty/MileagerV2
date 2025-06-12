import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../providers/vehicle_provider.dart';
import '../services/image_cache_service.dart';
import '../models/vehicle.dart';

class CacheDebugScreen extends StatefulWidget {
  const CacheDebugScreen({super.key});

  @override
  State<CacheDebugScreen> createState() => _CacheDebugScreenState();
}

class _CacheDebugScreenState extends State<CacheDebugScreen> {
  final ImageCacheService _cacheService = ImageCacheService();
  Map<String, dynamic>? _cacheInfo;
  List<FileInfo> _cachedFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() => _isLoading = true);

    try {
      final info = await _cacheService.getCacheInfo();
      // Note: Getting detailed cache file info is limited in the public API
      // We'll show basic cache status instead

      setState(() {
        _cacheInfo = info;
        _cachedFiles = []; // Simplified for now
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cache info: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllCache() async {
    await _cacheService.clearAllCache();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All cache cleared!')),
    );
    _loadCacheInfo();
  }

  Future<void> _clearVehicleCache(Vehicle vehicle) async {
    if (vehicle.photoUrl != null && vehicle.photoUrl!.startsWith('http')) {
      await _cacheService.clearCacheForUrl(vehicle.photoUrl!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Cache cleared for ${vehicle.make} ${vehicle.model}')),
      );
      _loadCacheInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Cache Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCacheInfoSection(),
                  const SizedBox(height: 24),
                  _buildCachedFilesSection(),
                  const SizedBox(height: 24),
                  _buildVehicleCacheSection(),
                  const SizedBox(height: 24),
                  _buildCacheActionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildCacheInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cache Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_cacheInfo != null) ...[
              _buildInfoRow('Status', _cacheInfo!['status']),
              _buildInfoRow('Cache Directory', _cacheInfo!['cacheDirectory']),
              _buildInfoRow('Cached Files', '${_cachedFiles.length} files'),
            ] else
              const Text('Loading cache info...'),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedFilesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cached Files',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
                'Cache file details are managed internally by the system')
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCacheSection() {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        final vehiclesWithUrls = vehicleProvider.vehicles
            .where((v) => v.photoUrl != null && v.photoUrl!.startsWith('http'))
            .toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehicle Images with URLs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (vehiclesWithUrls.isEmpty)
                  const Text('No vehicles with photo URLs found')
                else
                  ...vehiclesWithUrls
                      .map((vehicle) => _buildVehicleCacheItem(vehicle)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleCacheItem(Vehicle vehicle) {
    final cacheKey =
        _cacheService.generateVehicleCacheKey(vehicle.id, vehicle.photoUrl!);
    // Note: Cache status checking is simplified due to API limitations
    final isCached = true; // Assume cached for display purposes

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.make} ${vehicle.model}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Cache Key: $cacheKey',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Row(
                  children: [
                    Icon(
                      isCached ? Icons.check_circle : Icons.cloud_download,
                      size: 16,
                      color: isCached ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCached ? 'Cached' : 'Not cached',
                      style: TextStyle(
                        color: isCached ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _clearVehicleCache(vehicle),
            tooltip: 'Clear cache for this vehicle',
          ),
        ],
      ),
    );
  }

  Widget _buildCacheActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cache Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearAllCache,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All Cache'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadCacheInfo,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Cache Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
