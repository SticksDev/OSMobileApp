import 'dart:async';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flat_buffers/flat_buffers.dart' as fb;
import '../utils/logger.dart';
import '../generated/flatbuffers/LocalToHubMessage_open_shock.serialization.local_generated.dart';
import '../generated/flatbuffers/HubToLocalMessage_open_shock.serialization.local_generated.dart';
import '../generated/flatbuffers/WifiNetwork_open_shock.serialization.types_generated.dart';

class HubWebSocketClient {
  static const String _tag = 'HubWS';

  WebSocketChannel? _channel;
  final StreamController<List<WifiNetwork>> _wifiNetworksController =
      StreamController<List<WifiNetwork>>.broadcast();
  final StreamController<String> _connectionStateController =
      StreamController<String>.broadcast();

  Stream<List<WifiNetwork>> get wifiNetworks => _wifiNetworksController.stream;
  Stream<String> get connectionState => _connectionStateController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<bool> connect({String host = '10.10.10.10', int port = 81}) async {
    try {
      Logger.log('Connecting to hub at ws://$host:$port/ws', tag: _tag);
      _connectionStateController.add('connecting');

      _channel = WebSocketChannel.connect(Uri.parse('ws://$host:$port/ws'));

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          Logger.error('WebSocket error', tag: _tag, error: error);
          _connectionStateController.add('error');
          _isConnected = false;
        },
        onDone: () {
          Logger.log('WebSocket connection closed', tag: _tag);
          _connectionStateController.add('disconnected');
          _isConnected = false;
        },
      );

      await _channel!.ready.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Connection timed out.');
        },
      );

      _isConnected = true;
      _connectionStateController.add('connected');
      Logger.log('Successfully connected to hub', tag: _tag);

      return true;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to connect to hub',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      _connectionStateController.add('error');
      _isConnected = false;
      return false;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      if (message is Uint8List || message is List<int>) {
        final bytes = message is Uint8List
            ? message
            : Uint8List.fromList(message);
        _handleBinaryMessage(bytes);
      } else {
        Logger.log('Received non-binary message: $message', tag: _tag);
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Error handling message',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleBinaryMessage(Uint8List bytes) {
    try {
      final hubMessage = HubToLocalMessage(bytes);
      final payloadType = hubMessage.payloadType;

      Logger.log('Received message type: $payloadType', tag: _tag);

      switch (payloadType) {
        case HubToLocalMessagePayloadTypeId.WifiNetworkEvent:
          // Handle WiFi network events - this contains the list of scanned networks
          final wifiEvent = hubMessage.payload as WifiNetworkEvent?;
          if (wifiEvent != null) {
            Logger.log('WiFi event: type=${wifiEvent.eventType}', tag: _tag);
            if (wifiEvent.networks != null) {
              _wifiNetworksController.add(wifiEvent.networks!);
              Logger.log(
                'Received ${wifiEvent.networks!.length} WiFi networks',
                tag: _tag,
              );
            }
          }
          break;

        case HubToLocalMessagePayloadTypeId.WifiScanStatusMessage:
          // Handle scan status updates (started/stopped/etc)
          final scanStatus = hubMessage.payload as WifiScanStatusMessage?;
          if (scanStatus != null) {
            Logger.log('WiFi scan status: ${scanStatus.status}', tag: _tag);
          }
          break;

        case HubToLocalMessagePayloadTypeId.ReadyMessage:
          // Hub ready message - received when first connected
          final ready = hubMessage.payload as ReadyMessage?;
          if (ready != null) {
            Logger.log(
              'Hub ready: connected WiFi=${ready.connectedWifi?.ssid ?? "none"}',
              tag: _tag,
            );
          }
          break;

        default:
          Logger.log('Unhandled message type: $payloadType', tag: _tag);
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Error parsing binary message',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> startWifiScan() async {
    if (!_isConnected || _channel == null) {
      Logger.error('Cannot start scan: not connected', tag: _tag);
      return false;
    }

    try {
      // Build WiFi scan command
      final builder = fb.Builder(initialSize: 64);

      // Create WifiScanCommand with run=true
      final scanBuilder = WifiScanCommandBuilder(builder);
      scanBuilder.begin();
      scanBuilder.addRun(true);
      final scanOffset = scanBuilder.finish();

      // Wrap in LocalToHubMessage
      final msgBuilder = LocalToHubMessageBuilder(builder);
      msgBuilder.begin();
      msgBuilder.addPayloadType(LocalToHubMessagePayloadTypeId.WifiScanCommand);
      msgBuilder.addPayloadOffset(scanOffset);
      final msgOffset = msgBuilder.finish();

      builder.finish(msgOffset);

      final bytes = builder.buffer;
      _channel!.sink.add(bytes);

      Logger.log('Sent WiFi scan command', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to send scan command',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> connectToNetwork(String ssid) async {
    if (!_isConnected || _channel == null) {
      Logger.error(
        'Cannot connect to network: not connected to hub',
        tag: _tag,
      );
      return false;
    }

    try {
      // Build WiFi connect command
      final builder = fb.Builder(initialSize: 128);

      final ssidOffset = builder.writeString(ssid);

      // Create WifiNetworkConnectCommand
      final connectBuilder = WifiNetworkConnectCommandBuilder(builder);
      connectBuilder.begin();
      connectBuilder.addSsidOffset(ssidOffset);
      final connectOffset = connectBuilder.finish();

      // Wrap in LocalToHubMessage
      final msgBuilder = LocalToHubMessageBuilder(builder);
      msgBuilder.begin();
      msgBuilder.addPayloadType(
        LocalToHubMessagePayloadTypeId.WifiNetworkConnectCommand,
      );
      msgBuilder.addPayloadOffset(connectOffset);
      final msgOffset = msgBuilder.finish();

      builder.finish(msgOffset);

      final bytes = builder.buffer;
      _channel!.sink.add(bytes);

      Logger.log('Sent connect command for network: $ssid', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to send connect command',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  void disconnect() {
    Logger.log('Disconnecting from hub', tag: _tag);
    _channel?.sink.close();
    _isConnected = false;
    _connectionStateController.add('disconnected');
  }

  void dispose() {
    disconnect();
    _wifiNetworksController.close();
    _connectionStateController.close();
  }
}
