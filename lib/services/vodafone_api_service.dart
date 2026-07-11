import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import '../models/faka_product.dart';

class VodafoneApiException implements Exception {
  VodafoneApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class VodafoneOrderResult {
  const VodafoneOrderResult({
    required this.success,
    required this.message,
    this.statusCode,
  });

  final bool success;
  final String message;
  final int? statusCode;
}

class VodafoneApiService {
  VodafoneApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const products = <FakaProduct>[
    FakaProduct(id: 'Fakka_2.5_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_4.25_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_5_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_6_NewUnite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_7_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_9_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_10_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_10_NewUnite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_10.5_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_11.5_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_12_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_12.5_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_13_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_13.5_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_15_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_15_NewUnite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_15.5_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_16.5_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_17.5_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_19.5_NewUnite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_20_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Fakka_26_Unite', group: ProductGroup.fakka),
    FakaProduct(id: 'Mared_10_Minuts', group: ProductGroup.mared),
    FakaProduct(id: 'Mared_10_Flexs', group: ProductGroup.mared),
    FakaProduct(id: 'Mared_10_Social', group: ProductGroup.mared),
  ];

  Future<AuthSession> login() async {
    final seamless = await _getSeamlessAndMsisdn();
    final accessToken = await getAccessToken(seamless.seamlessToken);
    return AuthSession(
      seamlessToken: seamless.seamlessToken,
      accessToken: accessToken,
      msisdn: seamless.msisdn,
    );
  }

  Future<String> getAccessToken(String seamlessToken) async {
    final response = await _client.post(
      Uri.parse(
        'https://mobile.vodafone.com.eg/auth/realms/vf-realm/protocol/openid-connect/token',
      ),
      body: const {
        'grant_type': 'password',
        'client_secret': 'b86e30a8-ae29-467a-a71f-65c73f2ff5e3',
        'client_id': 'cash-app',
      },
      headers: {
        ..._baseHeaders,
        'Accept': 'application/json, text/plain, */*',
        'silentLogin': 'true',
        'CRP': 'false',
        'seamlessToken': seamlessToken,
        'firstTimeLogin': 'true',
      },
    );

    if (response.statusCode != 200) {
      throw VodafoneApiException(
        'فشل الحصول على access token',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw VodafoneApiException('الرد لا يحتوي على access token');
    }

    return token;
  }

  Future<VodafoneOrderResult> placeOrder({
    required AuthSession session,
    required FakaProduct product,
    required String receiver,
    required String pin,
  }) async {
    final response = await _client.post(
      Uri.parse('https://mobile.vodafone.com.eg/services/dxl/pom/productOrder'),
      body: jsonEncode({
        'channel': {'name': 'MobileApp'},
        'orderItem': [
          {
            'action': 'insert',
            'id': product.id,
            'product': {
              'characteristic': [
                {'name': 'PaymentMethod', 'value': 'VFCash'},
                {'name': 'USE_EMONEY', 'value': 'False'},
                {'name': 'MerchantCode', 'value': '81841829'},
              ],
              'id': product.id,
              'relatedParty': [
                {
                  'id': session.msisdn,
                  'name': 'MSISDN',
                  'role': 'Subscriber',
                },
                {'id': receiver, 'name': 'Receiver', 'role': 'Receiver'},
              ],
            },
            '@type': product.id,
            'eCode': 0,
          },
        ],
        'relatedParty': [
          {'id': pin, 'name': 'pin', 'role': 'Requestor'},
        ],
        '@type': 'CashFakkaAndMared',
      }),
      headers: {
        ..._baseHeaders,
        'Accept': 'application/json',
        'api-host': 'ProductOrderingManagement',
        'useCase': 'CashFakkaAndMared',
        'X-Request-ID': _requestId(),
        'api-version': 'v2',
        'msisdn': session.msisdn,
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (!_isSuccessfulOrderStatus(response.statusCode)) {
      return VodafoneOrderResult(
        success: false,
        message: _extractMessage(response.body) ?? 'فشل تنفيذ العملية',
        statusCode: response.statusCode,
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final state = data['state']?.toString();

      return VodafoneOrderResult(
        success: true,
        message: state == 'Completed'
            ? 'تم إرسال الطلب بنجاح والكارت اتبعت للمستلم'
            : 'تم تنفيذ العملية بنجاح',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return VodafoneOrderResult(
        success: true,
        message: 'تم استلام الرد بنجاح',
        statusCode: response.statusCode,
      );
    }
  }

  bool _isSuccessfulOrderStatus(int statusCode) {
    return statusCode >= 200 && statusCode <= 203;
  }

  Future<_SeamlessResult> _getSeamlessAndMsisdn() async {
    final uri = Uri.parse(
      'http://mobile.vodafone.com.eg/checkSeamless/realms/vf-realm/protocol/openid-connect/auth',
    ).replace(queryParameters: const {'client_id': 'cash-app'});

    final response = await _client.get(uri, headers: _baseHeaders);
    if (response.statusCode != 200) {
      throw VodafoneApiException(
        'فشل seamless token. تأكد إنك فاتح بيانات الهاتف',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final seamlessToken = data['seamlessToken'] as String?;
    final rawMsisdn = data['msisdn']?.toString();

    if (seamlessToken == null || seamlessToken.isEmpty) {
      throw VodafoneApiException('الرد لا يحتوي على seamless token');
    }

    final msisdn = rawMsisdn != null && rawMsisdn.startsWith('1')
        ? '0$rawMsisdn'
        : rawMsisdn;

    if (msisdn == null || msisdn.isEmpty) {
      throw VodafoneApiException('تعذر قراءة رقم الخط من الشبكة');
    }

    return _SeamlessResult(seamlessToken: seamlessToken, msisdn: msisdn);
  }

  String? _extractMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['reason']?.toString() ??
          data['message']?.toString() ??
          data['error_description']?.toString();
    } catch (_) {
      return body.trim().isEmpty ? null : body;
    }
  }

  static String _requestId() {
    final random = Random.secure();
    String section(int length) {
      const chars = '0123456789abcdef';
      return List.generate(length, (_) => chars[random.nextInt(chars.length)])
          .join();
    }

    return '${section(8)}-${section(4)}-${section(4)}-${section(4)}-${section(12)}';
  }

  static const _baseHeaders = {
    'User-Agent': 'okhttp/4.12.0',
    'Connection': 'Keep-Alive',
    'Accept-Encoding': 'gzip',
    'x-agent-operatingsystem': '16',
    'clientId': 'AnaVodafoneAndroid',
    'Accept-Language': 'ar',
    'x-agent-device': 'Samsung SM-A165F',
    'x-agent-version': '2025.11.1',
    'x-agent-build': '1063',
    'digitalId': '',
    'device-id': 'b26ba335813fad21',
  };
}

class _SeamlessResult {
  const _SeamlessResult({
    required this.seamlessToken,
    required this.msisdn,
  });

  final String seamlessToken;
  final String msisdn;
}
