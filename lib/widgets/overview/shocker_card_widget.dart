import 'package:flutter/material.dart';
import '../../models/shocker.dart';
import '../../models/shared_shocker.dart';
import '../../models/device_with_shockers.dart';
import '../../services/ws_client.dart';
import 'shocker_control_sheet.dart';

class ShockerCardWidget extends StatelessWidget {
  final dynamic shocker;
  final DeviceWithShockers? device;
  final OpenShockClient? wsClient;

  const ShockerCardWidget({
    super.key,
    required this.shocker,
    this.device,
    this.wsClient,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays ~/ 365 > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays ~/ 30 > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPaused = shocker.isPaused as bool;
    final String name = shocker.name as String;
    final bool isShared = shocker is SharedShocker;

    // For own shockers, show RF ID and model
    String? rfId;
    String? model;
    DateTime? createdOn;

    if (shocker is Shocker) {
      rfId = shocker.rfId;
      model = shocker.model;
      createdOn = shocker.createdOn;
    }

    return GestureDetector(
      onTap: () {
        if (wsClient != null) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => ShockerControlSheet(
              shocker: shocker,
              device: device,
              wsClient: wsClient!,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isShared
                ? Colors.blue.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPaused
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPaused
                      ? Icons.pause
                      : (isShared ? Icons.share : Icons.bolt),
                  color: isPaused
                      ? Colors.orange
                      : (isShared ? Colors.blue : Colors.green),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (device != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: device!.isOnline
                                  ? Colors.blue.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: device!.isOnline
                                    ? Colors.blue.withValues(alpha: 0.5)
                                    : Colors.red.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  device!.isOnline ? Icons.circle : Icons.circle,
                                  size: 8,
                                  color: device!.isOnline ? Colors.blue : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  device!.isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: device!.isOnline ? Colors.blue : Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isShared) ...[
                          const Icon(Icons.share, color: Colors.blue, size: 14),
                          const SizedBox(width: 4),
                          const Text(
                            'Shared',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          if (rfId != null) ...[
                            const Icon(
                              Icons.key,
                              color: Colors.white30,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'RF ID: $rfId',
                                style: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (model != null && rfId != null)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '•',
                                style: TextStyle(color: Colors.white30),
                              ),
                            ),
                          if (model != null)
                            Flexible(
                              child: Text(
                                model,
                                style: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPaused
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPaused ? 'Paused' : 'Active',
                  style: TextStyle(
                    color: isPaused ? Colors.orange : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (createdOn != null || (device != null && device!.firmwareVersion != null)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (createdOn != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white30,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Created: ${_formatDate(createdOn)}',
                        style: const TextStyle(color: Colors.white30, fontSize: 12),
                      ),
                    ],
                  ),
                if (device != null && device!.firmwareVersion != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.memory,
                        color: Colors.white30,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'FW: ${device!.firmwareVersion}',
                        style: const TextStyle(color: Colors.white30, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }
}
