import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _connectivity = const ConnectivityService();
  bool _checking = true;
  bool _requiresMobileData = false;

  @override
  void initState() {
    super.initState();
    _checkNetwork();
  }

  Future<void> _checkNetwork() async {
    setState(() {
      _checking = true;
      _requiresMobileData = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 500));
    final isMobile = await _connectivity.isUsingMobileData();

    if (!mounted) return;

    if (isMobile) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
      return;
    }

    setState(() {
      _checking = false;
      _requiresMobileData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _checking
                  ? const _CheckingView()
                  : _MobileDataRequiredView(
                      showWarning: _requiresMobileData,
                      onRetry: _checkNetwork,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckingView extends StatelessWidget {
  const _CheckingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('checking'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.network_cell, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 28),
        Text(
          'Faka Card',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ],
    );
  }
}

class _MobileDataRequiredView extends StatelessWidget {
  const _MobileDataRequiredView({
    required this.showWarning,
    required this.onRetry,
  });

  final bool showWarning;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      key: const ValueKey('mobile_required'),
      constraints: const BoxConstraints(maxWidth: 430),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.signal_cellular_connected_no_internet_4_bar,
                  color: colors.primary, size: 44),
              const SizedBox(height: 18),
              Text(
                'شغّل بيانات الهاتف',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                showWarning
                    ? 'التطبيق لازم يبدأ من شبكة الموبايل علشان يقرأ الخط ويكمل تسجيل الدخول.'
                    : 'جاري التحقق من الشبكة.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5D6475),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة الفحص'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
