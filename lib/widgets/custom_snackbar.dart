import 'package:flutter/material.dart';

enum SnackbarType { success, warning, error, loading }

class CustomSnackbar {
  static final Map<String, _SnackbarController> _activeSnackbars = {};

  static void show(
    BuildContext context, {
    required String title,
    String? description,
    required SnackbarType type,
    Duration? duration,
    String? key,
  }) {
    // Update existing snackbar with the same key if it exists
    if (key != null && _activeSnackbars.containsKey(key)) {
      _activeSnackbars[key]!.update(
        title: title,
        description: description,
        type: type,
        duration: duration,
      );
      return;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final controller = _SnackbarController();

    overlayEntry = OverlayEntry(
      builder: (context) => _CustomSnackbarWidget(
        title: title,
        description: description,
        type: type,
        duration: duration ?? const Duration(seconds: 3),
        controller: controller,
        onDismiss: () {
          overlayEntry.remove();
          if (key != null) {
            _activeSnackbars.remove(key);
          }
        },
      ),
    );

    overlay.insert(overlayEntry);

    if (key != null) {
      _activeSnackbars[key] = controller;
    }
  }

  static void dismiss(String key) {
    if (_activeSnackbars.containsKey(key)) {
      _activeSnackbars[key]!.dismiss();
      _activeSnackbars.remove(key);
    }
  }

  static void success(
    BuildContext context, {
    required String title,
    String? description,
    Duration? duration,
    String? key,
  }) {
    show(
      context,
      title: title,
      description: description,
      type: SnackbarType.success,
      duration: duration,
      key: key,
    );
  }

  static void warning(
    BuildContext context, {
    required String title,
    String? description,
    Duration? duration,
    String? key,
  }) {
    show(
      context,
      title: title,
      description: description,
      type: SnackbarType.warning,
      duration: duration,
      key: key,
    );
  }

  static void error(
    BuildContext context, {
    required String title,
    String? description,
    Duration? duration,
    String? key,
  }) {
    show(
      context,
      title: title,
      description: description,
      type: SnackbarType.error,
      duration: duration,
      key: key,
    );
  }

  static void loading(
    BuildContext context, {
    required String title,
    String? description,
    String? key,
  }) {
    show(
      context,
      title: title,
      description: description,
      type: SnackbarType.loading,
      duration: null, // Loading snackbars don't auto-dismiss
      key: key,
    );
  }
}

class _SnackbarController {
  _CustomSnackbarWidgetState? _state;

  void _attach(_CustomSnackbarWidgetState state) {
    _state = state;
  }

  void update({
    required String title,
    String? description,
    required SnackbarType type,
    Duration? duration,
  }) {
    _state?.updateContent(
      title: title,
      description: description,
      type: type,
      duration: duration,
    );
  }

  void dismiss() {
    _state?.dismiss();
  }
}

class _CustomSnackbarWidget extends StatefulWidget {
  final String title;
  final String? description;
  final SnackbarType type;
  final Duration? duration;
  final VoidCallback onDismiss;
  final _SnackbarController controller;

  const _CustomSnackbarWidget({
    required this.title,
    this.description,
    required this.type,
    this.duration,
    required this.onDismiss,
    required this.controller,
  });

  @override
  State<_CustomSnackbarWidget> createState() => _CustomSnackbarWidgetState();
}

class _CustomSnackbarWidgetState extends State<_CustomSnackbarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  double _progress = 1.0;

  late String _title;
  late String? _description;
  late SnackbarType _type;
  late Duration? _duration;

  @override
  void initState() {
    super.initState();

    // Attach controller
    widget.controller._attach(this);

    // Initialize state
    _title = widget.title;
    _description = widget.description;
    _type = widget.type;
    _duration = widget.duration;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    if (_duration != null) {
      _startProgressTimer();
    }
  }

  void updateContent({
    required String title,
    String? description,
    required SnackbarType type,
    Duration? duration,
  }) {
    if (!mounted) return;
    setState(() {
      _title = title;
      _description = description;
      _type = type;
      _duration = duration ?? const Duration(seconds: 3);

      // Reset progress if duration changed
      if (duration != null) {
        _progress = 1.0;
        _startProgressTimer();
      }
    });
  }

  Future<void> dismiss() async {
    await _dismiss();
  }

  void _startProgressTimer() {
    final duration = _duration!;
    final steps = 100;
    final stepDuration = duration.inMilliseconds ~/ steps;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      for (var i = 0; i < steps; i++) {
        Future.delayed(Duration(milliseconds: stepDuration * i), () {
          if (!mounted) return;
          setState(() {
            _progress = 1.0 - (i / steps);
          });
        });
      }

      Future.delayed(duration, _dismiss);
    });
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (_type) {
      case SnackbarType.success:
        return Colors.green;
      case SnackbarType.warning:
        return Colors.orange;
      case SnackbarType.error:
        return Colors.red;
      case SnackbarType.loading:
        return Colors.blue;
    }
  }

  IconData _getIcon() {
    switch (_type) {
      case SnackbarType.success:
        return Icons.check_circle;
      case SnackbarType.warning:
        return Icons.warning_amber;
      case SnackbarType.error:
        return Icons.error;
      case SnackbarType.loading:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          if (_type == SnackbarType.loading)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            )
                          else
                            Icon(icon, color: color, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _description!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_type != SnackbarType.loading)
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white54,
                                size: 18,
                              ),
                              onPressed: _dismiss,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_duration != null)
                      SizedBox(
                        height: 3,
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
