import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/fog/fog_grid.dart';
import '../../../../core/motion/dander_motion.dart';
import '../../../../core/sharing/share_service.dart';
import '../../../../core/theme/dander_colors.dart';
import '../../../../core/theme/dander_spacing.dart';
import '../../../../core/theme/dander_text_styles.dart';
import '../../../../core/zone/zone.dart';
import 'turf_share_card.dart';

/// Bottom sheet that previews and shares a [TurfShareCard] for a given [zone].
///
/// The sheet includes:
/// - A scaled card preview with an optional fade+slide entry animation.
/// - An editable caption field pre-filled from zone name and exploration pct.
/// - A primary "Share your turf →" action (via [ShareService]).
/// - A secondary "Save to Photos" action (via `gal`).
///
/// Pass [shareService] and [analyticsService] to inject test doubles.
class TurfSharePreviewSheet extends StatefulWidget {
  const TurfSharePreviewSheet({
    super.key,
    required this.zone,
    required this.streetCount,
    required this.explorationPct,
    this.fogGrid,
    this.shareService,
    this.analyticsService,
  });

  final Zone zone;
  final int streetCount;

  /// Fraction of zone explored, from 0.0 to 1.0.
  final double explorationPct;
  final FogGrid? fogGrid;

  /// Optional override for tests — falls back to GetIt registration.
  final ShareService? shareService;

  /// Optional override for tests — falls back to GetIt registration.
  final AnalyticsService? analyticsService;

  @override
  State<TurfSharePreviewSheet> createState() => _TurfSharePreviewSheetState();
}

class _TurfSharePreviewSheetState extends State<TurfSharePreviewSheet> {
  bool _sharingInProgress = false;
  bool _savingInProgress = false;
  late TextEditingController _captionController;

  ShareService get _shareService =>
      widget.shareService ?? GetIt.instance<ShareService>();

  AnalyticsService get _analyticsService =>
      widget.analyticsService ?? GetIt.instance<AnalyticsService>();

  @override
  void initState() {
    super.initState();
    final pct = (widget.explorationPct * 100).round();
    _captionController = TextEditingController(
      text: "I've mapped $pct% of ${widget.zone.name} with @DanderApp 🗺",
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: DanderColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDragHandle(),
                _buildHeader(),
                _buildCardPreview(),
                _buildCaptionField(),
                _buildShareButton(),
                _buildSaveButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Drag handle
  // ---------------------------------------------------------------------------

  Widget _buildDragHandle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: DanderColors.onSurfaceDisabled,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header — micro-label + zone name
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR TURF',
            style: DanderTextStyles.labelMedium.copyWith(
              color: DanderColors.secondary,
              letterSpacing: 3,
            ),
          ),
          Text(
            widget.zone.name,
            style: DanderTextStyles.headlineLarge.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card preview
  // ---------------------------------------------------------------------------

  Widget _buildCardPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _CardPreview(
          zone: widget.zone,
          streetCount: widget.streetCount,
          explorationPct: widget.explorationPct,
          fogGrid: widget.fogGrid,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Caption field
  // ---------------------------------------------------------------------------

  Widget _buildCaptionField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caption',
            style: DanderTextStyles.labelSmall.copyWith(
              color: DanderColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _captionController,
            maxLines: 2,
            style: DanderTextStyles.bodyMedium,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: DanderColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: DanderColors.cardBorder,
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: DanderColors.cardBorder,
                  width: 0.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: DanderColors.cardBorder,
                  width: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Share button
  // ---------------------------------------------------------------------------

  Widget _buildShareButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _sharingInProgress ? null : _share,
          style: ElevatedButton.styleFrom(
            backgroundColor: DanderColors.secondary,
            disabledBackgroundColor: DanderColors.secondary,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DanderSpacing.borderRadiusMd),
            ),
            elevation: 0,
          ),
          child: _sharingInProgress
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(DanderColors.onSecondary),
                  ),
                )
              : Text(
                  'Share your turf →',
                  style: DanderTextStyles.titleMedium.copyWith(
                    color: DanderColors.onSecondary,
                  ),
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save to Photos button
  // ---------------------------------------------------------------------------

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: _savingInProgress ? null : _saveToPhotos,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: DanderColors.cardBorder, width: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DanderSpacing.borderRadiusMd),
            ),
          ),
          child: _savingInProgress
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Save to Photos', style: DanderTextStyles.labelLarge),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _share() async {
    setState(() => _sharingInProgress = true);
    try {
      final bytes = await _shareService.captureWidget(
        TurfShareCard(
          zone: widget.zone,
          streetCount: widget.streetCount,
          explorationPct: widget.explorationPct,
          fogGrid: widget.fogGrid,
        ),
        size: const Size(TurfShareCard.cardWidth, TurfShareCard.cardHeight),
      );
      await _shareService.shareImage(bytes, subject: _captionController.text);
      _analyticsService.track(ZoneTurfShared(
        zoneName: widget.zone.name,
        level: widget.zone.level,
        streetCount: widget.streetCount,
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't create share image. Try again."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingInProgress = false);
    }
  }

  Future<void> _saveToPhotos() async {
    setState(() => _savingInProgress = true);
    try {
      final bytes = await _shareService.captureWidget(
        TurfShareCard(
          zone: widget.zone,
          streetCount: widget.streetCount,
          explorationPct: widget.explorationPct,
          fogGrid: widget.fogGrid,
        ),
        size: const Size(TurfShareCard.cardWidth, TurfShareCard.cardHeight),
      );
      await Gal.putImageBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Photos ✓')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save image. Try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _savingInProgress = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Private card preview widget with optional entry animation
// ---------------------------------------------------------------------------

class _CardPreview extends StatefulWidget {
  const _CardPreview({
    required this.zone,
    required this.streetCount,
    required this.explorationPct,
    this.fogGrid,
  });

  final Zone zone;
  final int streetCount;
  final double explorationPct;
  final FogGrid? fogGrid;

  @override
  State<_CardPreview> createState() => _CardPreviewState();
}

class _CardPreviewState extends State<_CardPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _reduced = false;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = DanderMotion.isReduced(context);

    // Start the entry animation once, after the first frame, with a 100 ms
    // delay — but only when reduced motion is not active.
    if (!_reduced && !_animationStarted) {
      _animationStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_reduced) {
          // Use a 100 ms delay via AnimationController's reverseDuration to
          // mimic the intended delay without a rogue timer.
          Future<void>.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _controller.forward();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / TurfShareCard.cardWidth;
        return Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: TurfShareCard.cardWidth,
            height: TurfShareCard.cardHeight,
            child: TurfShareCard(
              zone: widget.zone,
              streetCount: widget.streetCount,
              explorationPct: widget.explorationPct,
              fogGrid: widget.fogGrid,
            ),
          ),
        );
      },
    );

    if (_reduced) {
      return card;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: card,
      ),
    );
  }
}
