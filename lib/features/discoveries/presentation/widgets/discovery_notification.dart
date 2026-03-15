import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/features/discoveries/presentation/widgets/discovery_card.dart';

/// An animated overlay that slides up from the bottom when a discovery
/// is triggered.
///
/// Dismisses on tap or after [autoDismissDuration] (default 8 seconds).
class DiscoveryNotification extends StatefulWidget {
  const DiscoveryNotification({
    super.key,
    required this.discovery,
    required this.onDismiss,
    this.discoveryNumber = 1,
    this.autoDismissDuration = const Duration(seconds: 8),
  });

  /// The discovery that was triggered.
  final Discovery discovery;

  /// Called when the notification is dismissed.
  final VoidCallback onDismiss;

  /// Sequential discovery number to pass down to [DiscoveryCard].
  final int discoveryNumber;

  /// How long before the notification auto-dismisses.
  final Duration autoDismissDuration;

  @override
  State<DiscoveryNotification> createState() => _DiscoveryNotificationState();
}

class _DiscoveryNotificationState extends State<DiscoveryNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    _autoDismissTimer = Timer(widget.autoDismissDuration, () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return GestureDetector(
      onTap: widget.onDismiss,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
          child: DiscoveryCard(
            discovery: widget.discovery,
            onDismiss: widget.onDismiss,
            discoveryNumber: widget.discoveryNumber,
          ),
        ),
      ),
    );
  }
}
