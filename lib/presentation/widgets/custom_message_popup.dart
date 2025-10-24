// Custom Message Popup Widget
// Usage:
// MessagePopup.show(
//   context,
//   message: 'Welcome Staff',
//   type: MessageType.success,
//   position: PopupPosition.top,
// );

import 'package:flutter/material.dart';

enum MessageType { success, error, info, warning }

enum PopupPosition { top, bottom }

class MessagePopup {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String message,
    MessageType type = MessageType.info,
    PopupPosition position = PopupPosition.top,
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    // Remove existing overlay if any
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => _MessagePopupWidget(
            message: message,
            type: type,
            position: position,
            title: title,
            onDismiss: () {
              overlayEntry.remove();
              if (_currentOverlay == overlayEntry) {
                _currentOverlay = null;
              }
            },
          ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);

    // Auto dismiss after duration
    Future.delayed(duration, () {
      if (_currentOverlay == overlayEntry) {
        overlayEntry.remove();
        _currentOverlay = null;
      }
    });
  }

  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _MessagePopupWidget extends StatefulWidget {
  final String message;
  final MessageType type;
  final PopupPosition position;
  final String? title;
  final VoidCallback onDismiss;

  const _MessagePopupWidget({
    required this.message,
    required this.type,
    required this.position,
    required this.onDismiss,
    this.title,
  });

  @override
  State<_MessagePopupWidget> createState() => _MessagePopupWidgetState();
}

class _MessagePopupWidgetState extends State<_MessagePopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin:
          widget.position == PopupPosition.top
              ? const Offset(0, -1)
              : const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFF10B981);
      case MessageType.error:
        return const Color(0xFFEF4444);
      case MessageType.warning:
        return const Color(0xFFF59E0B);
      case MessageType.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.error:
        return Icons.error;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.info:
        return Icons.info;
    }
  }

  String _getDefaultTitle() {
    switch (widget.type) {
      case MessageType.success:
        return 'Success';
      case MessageType.error:
        return 'Error';
      case MessageType.warning:
        return 'Warning';
      case MessageType.info:
        return 'Information';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.position == PopupPosition.top ? 0 : null,
      bottom: widget.position == PopupPosition.bottom ? 0 : null,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(_getIcon(), color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title ?? _getDefaultTitle(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _controller.reverse().then((_) {
                            widget.onDismiss();
                          });
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Example Usage Widget
class MessagePopupExample extends StatelessWidget {
  const MessagePopupExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Popup Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                MessagePopup.show(
                  context,
                  message: 'Welcome Staff! You have successfully logged in.',
                  type: MessageType.success,
                  position: PopupPosition.top,
                  title: 'Welcome',
                );
              },
              child: const Text('Show Welcome Message (Top)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                MessagePopup.show(
                  context,
                  message: 'Your profile has been updated successfully.',
                  type: MessageType.success,
                  position: PopupPosition.bottom,
                );
              },
              child: const Text('Show Success Message (Bottom)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                MessagePopup.show(
                  context,
                  message: 'Failed to connect to server. Please try again.',
                  type: MessageType.error,
                  position: PopupPosition.top,
                );
              },
              child: const Text('Show Error Message (Top)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                MessagePopup.show(
                  context,
                  message: 'Your session will expire in 5 minutes.',
                  type: MessageType.warning,
                  position: PopupPosition.bottom,
                );
              },
              child: const Text('Show Warning Message (Bottom)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                MessagePopup.show(
                  context,
                  message: 'New updates are available for download.',
                  type: MessageType.info,
                  position: PopupPosition.top,
                );
              },
              child: const Text('Show Info Message (Top)'),
            ),
          ],
        ),
      ),
    );
  }
}
