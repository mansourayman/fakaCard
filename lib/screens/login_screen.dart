import 'package:flutter/material.dart';

import '../services/backend_auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/vodafone_api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _backendAuth = BackendAuthService();
  final _api = VodafoneApiService();
  final _connectivity = const ConnectivityService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _backendAuth.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final isMobile = await _connectivity.isUsingMobileData();
      if (!isMobile) {
        throw VodafoneApiException('افتح بيانات الهاتف قبل دخول لوحة التحكم');
      }

      final session = await _api.login();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DashboardScreen(session: session),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -28,
                            top: -34,
                            child:
                                _SoftCircle(size: 140, color: Colors.white24),
                          ),
                          Positioned(
                            left: -18,
                            bottom: -32,
                            child:
                                _SoftCircle(size: 120, color: Colors.white12),
                          ),
                          const Center(
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
                              size: 76,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'تسجيل الدخول',
                      textAlign: TextAlign.right,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ادخل بيانات المستخدم من السيرفر. بعد نجاح الدخول، التطبيق هيتأكد من بيانات الهاتف ويفتح لوحة التحكم.',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF606777),
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _usernameController,
                      enabled: !_loading,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (value) {
                        final username = value?.trim() ?? '';
                        if (username.length < 3) {
                          return 'اسم المستخدم لازم يكون 3 حروف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_loading,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: const InputDecoration(
                        labelText: 'كلمة السر',
                        prefixIcon: Icon(Icons.lock_rounded),
                      ),
                      validator: (value) {
                        final password = value?.trim() ?? '';
                        if (password.length < 6) {
                          return 'كلمة السر لازم تكون 6 حروف أو أرقام على الأقل';
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      _ErrorBox(message: _error!),
                    ],
                    const SizedBox(height: 26),
                    FilledButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(_loading ? 'جاري الدخول' : 'دخول'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
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

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC7C7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF8A1F17)),
            ),
          ),
        ],
      ),
    );
  }
}
