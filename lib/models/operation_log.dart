import 'dart:convert';

enum OperationStatus { success, failed }

class OperationLog {
  const OperationLog({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.productId,
    required this.receiver,
    required this.message,
    this.statusCode,
  });

  final String id;
  final DateTime createdAt;
  final OperationStatus status;
  final String productId;
  final String receiver;
  final String message;
  final int? statusCode;

  bool get isSuccess => status == OperationStatus.success;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'productId': productId,
      'receiver': receiver,
      'message': message,
      'statusCode': statusCode,
    };
  }

  factory OperationLog.fromMap(Map<String, dynamic> map) {
    return OperationLog(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: OperationStatus.values.byName(map['status'] as String),
      productId: map['productId'] as String,
      receiver: map['receiver'] as String,
      message: map['message'] as String,
      statusCode: map['statusCode'] as int?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory OperationLog.fromJson(String source) {
    return OperationLog.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
