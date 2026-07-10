import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../models/faka_product.dart';
import '../models/operation_log.dart';
import '../services/connectivity_service.dart';
import '../services/log_store.dart';
import '../services/vodafone_api_service.dart';
import '../widgets/product_selector.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.session, super.key});

  final AuthSession session;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _receiverController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _api = VodafoneApiService();
  final _connectivity = const ConnectivityService();
  final _logStore = LogStore();

  late AuthSession _session = widget.session;
  FakaProduct _selectedProduct = VodafoneApiService.products.first;
  bool _submitting = false;

  @override
  void dispose() {
    _receiverController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    VodafoneOrderResult result;
    try {
      final isMobile = await _connectivity.isUsingMobileData();
      if (!isMobile) {
        throw VodafoneApiException('العملية لازم تتم من بيانات الهاتف');
      }

      final freshToken = await _api.getAccessToken(_session.seamlessToken);
      _session = _session.copyWith(accessToken: freshToken);

      result = await _api.placeOrder(
        session: _session,
        product: _selectedProduct,
        receiver: _receiverController.text.trim(),
        pin: _pinController.text.trim(),
      );
    } catch (error) {
      result = VodafoneOrderResult(
        success: false,
        message: error.toString(),
      );
    }

    final log = OperationLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      status: result.success ? OperationStatus.success : OperationStatus.failed,
      productId: _selectedProduct.id,
      receiver: _receiverController.text.trim(),
      message: result.message,
      statusCode: result.statusCode,
    );
    await _logStore.add(log);

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            result.success ? const Color(0xFF057A55) : const Color(0xFFB42318),
        content: Text(result.message, textAlign: TextAlign.right),
      ),
    );

    if (result.success) {
      _pinController.clear();
    }
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
          actions: [
            IconButton(
              tooltip: 'سجل العمليات',
              onPressed: _openHistory,
              icon: const Icon(Icons.receipt_long_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                _AccountHeader(msisdn: _session.msisdn),
                const SizedBox(height: 18),
                ProductSelector(
                  selected: _selectedProduct,
                  onChanged: (product) {
                    setState(() => _selectedProduct = product);
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _receiverController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: const InputDecoration(
                    labelText: 'رقم المستلم',
                    prefixIcon: Icon(Icons.phone_android_rounded),
                    counterText: '',
                  ),
                  validator: (value) {
                    final receiver = value?.trim() ?? '';
                    if (!RegExp(r'^01\d{9}$').hasMatch(receiver)) {
                      return 'اكتب رقم صحيح يبدأ بـ 01 ومكون من 11 رقم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'PIN فودافون كاش',
                    prefixIcon: Icon(Icons.lock_rounded),
                    counterText: '',
                  ),
                  validator: (value) {
                    final pin = value?.trim() ?? '';
                    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
                      return 'الـ PIN لازم يكون 6 أرقام';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_submitting ? 'جاري التنفيذ' : 'تنفيذ العملية'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openHistory,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('عرض السجل'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.msisdn});

  final String msisdn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'متصل ببيانات الهاتف',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  msisdn,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
