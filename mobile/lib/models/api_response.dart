class ApiResponse<T> {
  final String status;
  final String code;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.status,
    required this.code,
    required this.message,
    this.data,
    this.errors,
  });

  bool get berhasil => status == 'sukses';

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      status: json['status'] ?? '',
      code: json['code']?.toString() ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      errors: json['errors'] != null
          ? Map<String, dynamic>.from(json['errors'])
          : null,
    );
  }
}
