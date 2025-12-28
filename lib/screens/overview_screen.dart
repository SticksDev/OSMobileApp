import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../services/ws_client.dart';
import '../models/device_with_shockers.dart';
import '../models/shared_user.dart';
import '../models/shared_shocker.dart';
import '../utils/logger.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/loading_state.dart';
import '../widgets/overview/search_bar_widget.dart';
import '../widgets/overview/filter_bar_widget.dart';
import '../widgets/overview/shocker_card_widget.dart';
import '../widgets/overview/empty_state_widget.dart';
import '../widgets/overview/error_state_widget.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final ApiClient _apiClient = ApiClient();
  OpenShockClient? _wsClient;
  List<DeviceWithShockers> _devices = [];
  List<SharedUser> _sharedUsers = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Set<ShockerFilter> _activeFilters = {ShockerFilter.all};

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    Logger.log('Initializing overview screen', tag: 'OverviewScreen');
    // Configure API client with current host
    final customHost = await StorageService().getCustomHost();
    if (customHost != null && customHost.isNotEmpty) {
      Logger.log('Using custom host: $customHost', tag: 'OverviewScreen');
      await _apiClient.setBaseUrl(customHost);
    }

    _loadShockers();
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    try {
      // Get session key from API client
      final sessionKey = await _apiClient.getSessionKey();
      if (sessionKey == null) {
        Logger.error(
          'No session key available for WebSocket',
          tag: 'OverviewScreen',
        );
        CustomSnackbar.error(
          context,
          title: 'WebSocket Connection Failed',
          description: 'No session key available.',
        );

        return;
      }

      final apiHost = _apiClient.baseUrl;

      // Initialize WebSocket client
      _wsClient = OpenShockClient(
        apiHost: apiHost,
        sessionKey: sessionKey,
        userAgent: 'OpenShockMobile/1.0.0',
      );

      // Register for DeviceStatus events
      await _wsClient!.start();
      _wsClient!.registerForwarder('DeviceStatus');

      // Listen for DeviceStatus events
      _wsClient!.onMethod('DeviceStatus').listen((event) {
        Logger.log(
          'DeviceStatus event received: ${event.args}',
          tag: 'OverviewScreen',
        );
        print('DeviceStatus event: ${event.args}');
      });

      // Send DeviceStatus command with empty data
      Logger.log('Sending DeviceStatus command', tag: 'OverviewScreen');
      final success = await _wsClient!.sendCommand('DeviceStatus');

      if (success) {
        Logger.log(
          'WebSocket connected and DeviceStatus sent successfully',
          tag: 'OverviewScreen',
        );

        CustomSnackbar.success(
          context,
          title: 'WebSocket Connected',
          description: 'Real-time updates are now enabled.',
        );
      } else {
        Logger.error(
          'Failed to send DeviceStatus command',
          tag: 'OverviewScreen',
        );

        CustomSnackbar.error(
          context,
          title: 'WebSocket Connection Failed',
          description: 'Could not send DeviceStatus command.',
        );
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to connect WebSocket',
        tag: 'OverviewScreen',
        error: e,
        stackTrace: stackTrace,
      );

      CustomSnackbar.error(
        context,
        title: 'WebSocket Connection Failed',
        description: e.toString(),
      );
    }
  }

  Future<void> _loadShockers() async {
    Logger.log('Loading shockers', tag: 'OverviewScreen');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Load both own and shared shockers in parallel
    final ownResponse = await _apiClient.getOwnShockers();
    final sharedResponse = await _apiClient.getSharedShockers();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (ownResponse.isSuccess && sharedResponse.isSuccess) {
          _devices = ownResponse.data ?? [];
          _sharedUsers = sharedResponse.data ?? [];
          Logger.log(
            'Loaded ${_devices.length} own devices and ${_sharedUsers.length} shared users',
            tag: 'OverviewScreen',
          );
        } else {
          _error = ownResponse.error ?? sharedResponse.error;
          Logger.error(
            'Failed to load shockers: $_error',
            tag: 'OverviewScreen',
          );
          CustomSnackbar.error(
            context,
            title: 'Failed to Load Shockers',
            description: _error ?? 'Unknown error occurred',
          );
        }
      });
    }
  }

  List<dynamic> _getFilteredShockers() {
    // Combine own and shared shockers
    final ownShockers = _devices.expand((device) => device.shockers).toList();
    final sharedShockers = _sharedUsers
        .expand((user) => user.devices)
        .expand((device) => device.shockers)
        .toList();

    List<dynamic> allShockers = [...ownShockers, ...sharedShockers];

    // Apply filters
    if (!_activeFilters.contains(ShockerFilter.all)) {
      allShockers = allShockers.where((shocker) {
        final isShared = shocker is SharedShocker;
        final isPaused = shocker.isPaused as bool;

        // Check ownership filter
        if (_activeFilters.contains(ShockerFilter.own) && isShared) {
          return false;
        }
        if (_activeFilters.contains(ShockerFilter.shared) && !isShared) {
          return false;
        }

        // Check status filter
        if (_activeFilters.contains(ShockerFilter.active) && isPaused) {
          return false;
        }
        if (_activeFilters.contains(ShockerFilter.paused) && !isPaused) {
          return false;
        }

        return true;
      }).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      allShockers = allShockers
          .where(
            (shocker) =>
                shocker.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return allShockers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wsClient?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/os/Icon64.png', width: 32, height: 32),
            const SizedBox(width: 12),
            const Text(
              'OpenShock',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_devices.isNotEmpty || _sharedUsers.isNotEmpty) ...[
            SearchBarWidget(
              controller: _searchController,
              searchQuery: _searchQuery,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
            FilterBarWidget(
              activeFilters: _activeFilters,
              onToggleFilter: _toggleFilter,
            ),
          ],
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  void _toggleFilter(ShockerFilter filter) {
    setState(() {
      if (filter == ShockerFilter.all) {
        _activeFilters = {ShockerFilter.all};
      } else {
        _activeFilters.remove(ShockerFilter.all);
        if (_activeFilters.contains(filter)) {
          _activeFilters.remove(filter);
          if (_activeFilters.isEmpty) {
            _activeFilters = {ShockerFilter.all};
          }
        } else {
          _activeFilters.add(filter);
        }
      }
    });
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingState(message: 'Loading shockers...');
    }

    if (_error != null) {
      return ErrorStateWidget(error: _error!, onRetry: _loadShockers);
    }

    if (_devices.isEmpty && _sharedUsers.isEmpty) {
      return EmptyStateWidget(onRefresh: _loadShockers);
    }

    final filteredShockers = _getFilteredShockers();

    return RefreshIndicator(
      onRefresh: _loadShockers,
      color: Colors.white,
      backgroundColor: const Color(0xFF1A1A1A),
      child: filteredShockers.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, color: Colors.white30, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'No shockers match your search',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredShockers.length,
              itemBuilder: (context, index) {
                final shocker = filteredShockers[index];
                return ShockerCardWidget(shocker: shocker);
              },
            ),
    );
  }
}
