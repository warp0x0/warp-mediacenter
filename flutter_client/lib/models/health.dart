import 'package:freezed_annotation/freezed_annotation.dart';

part 'health.freezed.dart';
part 'health.g.dart';

@freezed
abstract class DatabaseHealth with _$DatabaseHealth {
  const factory DatabaseHealth({
    required String status,
    int? schemaVersion,
    String? message,
  }) = _DatabaseHealth;

  factory DatabaseHealth.fromJson(Map<String, dynamic> json) =>
      _$DatabaseHealthFromJson(json);
}

@freezed
abstract class HealthSubsystems with _$HealthSubsystems {
  const factory HealthSubsystems({
    required DatabaseHealth database,
    @Default({}) Map<String, dynamic> services,
  }) = _HealthSubsystems;

  factory HealthSubsystems.fromJson(Map<String, dynamic> json) =>
      _$HealthSubsystemsFromJson(json);
}

@freezed
abstract class HealthResponse with _$HealthResponse {
  const factory HealthResponse({
    required String status,
    required String service,
    required HealthSubsystems subsystems,
  }) = _HealthResponse;

  factory HealthResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthResponseFromJson(json);
}
