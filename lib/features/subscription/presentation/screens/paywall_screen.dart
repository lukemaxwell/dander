import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:dander/core/subscription/purchase_result.dart';
import 'package:dander/core/subscription/subscription_service.dart';
import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/core/theme/dander_spacing.dart';
import 'package:dander/core/theme/dander_text_styles.dart';
import 'package:dander/features/subscription/paywall_trigger.dart';
import 'package:dander/features/subscription/presentation/widgets/benefit_row.dart';
import 'package:dander/features/subscription/presentation/widgets/paywall_hero.dart';
import 'package:dander/features/subscription/presentation/widgets/plan_card.dart';

/// Full-screen paywall modal.
///
/// Pushed as a standard [MaterialPageRoute] (slide-up from bottom).
/// Close via the X button at top-left or swipe down.
///
/// Reads [SubscriptionService] from [GetIt] to trigger purchases.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    super.key,
    required this.trigger,
  });

  /// The context that brought the user to this screen.
  final PaywallTrigger trigger;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final List<Animation<double>> _benefitOpacities;

  bool _annualLoading = false;
  bool _monthlyLoading = false;
  String? _annualError;
  String? _monthlyError;

  SubscriptionService get _service => GetIt.instance<SubscriptionService>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Stagger 3 benefits: 0ms, 50ms, 100ms offsets within the 600ms window.
    _benefitOpacities = List.generate(3, (i) {
      final start = (i * 50) / 600.0;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    // Start stagger after the first frame so the slide-in transition
    // has time to begin. WidgetsBinding.addPostFrameCallback is testable
    // with pumpAndSettle; a hard Future.delayed is not.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _purchaseAnnual() async {
    setState(() {
      _annualLoading = true;
      _annualError = null;
    });
    final result = await _service.purchaseAnnual();
    if (!mounted) return;
    _handleResult(result, isAnnual: true);
  }

  Future<void> _purchaseMonthly() async {
    setState(() {
      _monthlyLoading = true;
      _monthlyError = null;
    });
    final result = await _service.purchaseMonthly();
    if (!mounted) return;
    _handleResult(result, isAnnual: false);
  }

  void _handleResult(PurchaseResult result, {required bool isAnnual}) {
    switch (result) {
      case PurchaseSuccess():
        // Capture messenger before pop — context becomes detached after pop.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Welcome to Pro')),
        );
      case PurchaseCancelled():
        setState(() {
          if (isAnnual) {
            _annualLoading = false;
          } else {
            _monthlyLoading = false;
          }
        });
      case PurchaseError():
        setState(() {
          if (isAnnual) {
            _annualLoading = false;
            _annualError = 'Something went wrong. Try again.';
          } else {
            _monthlyLoading = false;
            _monthlyError = 'Something went wrong. Try again.';
          }
        });
    }
  }

  Future<void> _restorePurchases() async {
    final stateBefore = _service.state.value;
    await _service.restorePurchases();
    if (!mounted) return;
    final restored = _service.state.value.isPro && !stateBefore.isPro;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored ? 'Pro access restored' : 'No previous purchases found',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DanderColors.surface,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            // Swipe down to dismiss
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 200) {
              Navigator.of(context).pop();
            }
          },
          child: Stack(
            children: [
              // Scrollable content
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 60, // space for close button
                  left: DanderSpacing.lg,
                  right: DanderSpacing.lg,
                  bottom: DanderSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hero
                    PaywallHero(trigger: widget.trigger),
                    const SizedBox(height: DanderSpacing.xl),

                    // "DANDER PRO" headline with amber→cyan gradient
                    _GradientHeadline(),
                    const SizedBox(height: DanderSpacing.sm),

                    // Subtitle
                    Text(
                      'Take your exploration further',
                      style: DanderTextStyles.bodyLargeMuted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DanderSpacing.xl),

                    // Benefits list (staggered fade-in)
                    ..._benefits.asMap().entries.map((entry) {
                      final i = entry.key;
                      final benefit = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i < _benefits.length - 1
                              ? DanderSpacing.lg
                              : 0,
                        ),
                        child: AnimatedBuilder(
                          animation: _benefitOpacities[i],
                          builder: (_, child) => Opacity(
                            opacity: _benefitOpacities[i].value,
                            child: child,
                          ),
                          child: benefit,
                        ),
                      );
                    }),
                    const SizedBox(height: DanderSpacing.xl),

                    // Annual plan card (highlighted)
                    PlanCard(
                      price: r'$34.99/year',
                      period: 'year',
                      subtitle: r'$2.92/mo · 7 days free',
                      ctaLabel: 'Start free trial',
                      isHighlighted: true,
                      isLoading: _annualLoading,
                      onTap: _purchaseAnnual,
                      errorMessage: _annualError,
                    ),
                    const SizedBox(height: DanderSpacing.md),

                    // Monthly plan card (quiet)
                    PlanCard(
                      price: r'$4.99/month',
                      period: 'month',
                      subtitle: '',
                      ctaLabel: 'Subscribe',
                      isHighlighted: false,
                      isLoading: _monthlyLoading,
                      onTap: _purchaseMonthly,
                      errorMessage: _monthlyError,
                    ),
                    const SizedBox(height: DanderSpacing.xl),

                    // Legal footer
                    _LegalFooter(onRestore: _restorePurchases),
                  ],
                ),
              ),

              // Close button — always visible, top-left, inset from edge
              // to avoid iOS back-swipe zone and ensure reliable tappability.
              Positioned(
                top: 0,
                left: DanderSpacing.sm, // 8px inset from screen edge
                child: Semantics(
                  label: 'Close Dander Pro subscription',
                  hint: 'Swipe down to dismiss',
                  button: true,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: DanderColors.onSurfaceMuted,
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "DANDER PRO" gradient headline
// ---------------------------------------------------------------------------

class _GradientHeadline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          DanderColors.secondary,
          DanderColors.accent,
        ],
      ).createShader(bounds),
      child: Text(
        'DANDER PRO',
        style: DanderTextStyles.headlineLarge.copyWith(
          color: Colors.white, // ShaderMask overrides this
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legal footer
// ---------------------------------------------------------------------------

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegalLink(label: 'Restore purchases', onTap: onRestore),
        _Separator(),
        _LegalLink(label: 'Terms', onTap: () {}),
        _Separator(),
        _LegalLink(label: 'Privacy', onTap: () {}),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44,
        child: Center(
          child: Text(label, style: DanderTextStyles.labelSmall),
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DanderSpacing.sm),
      child: Text(' · ', style: DanderTextStyles.labelSmall),
    );
  }
}

// ---------------------------------------------------------------------------
// Benefit data
// ---------------------------------------------------------------------------

const _benefits = <BenefitRow>[
  BenefitRow(
    icon: Icons.map_outlined,
    title: 'Unlimited zones',
    description: 'Map every neighbourhood',
  ),
  BenefitRow(
    icon: Icons.quiz_outlined,
    title: 'Full quiz access',
    description: 'All question types, no cap',
  ),
  BenefitRow(
    icon: Icons.bar_chart_outlined,
    title: 'Advanced stats & wraps',
    description: 'Heat maps, monthly trends',
  ),
];
