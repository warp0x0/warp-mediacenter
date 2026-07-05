// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DatabaseHealth _$DatabaseHealthFromJson(Map<String, dynamic> json) =>
    _DatabaseHealth(
      status: json['status'] as String,
      schemaVersion: (json['schema_version'] as num?)?.toInt(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$DatabaseHealthToJson(_DatabaseHealth instance) =>
    <String, dynamic>{
      'status': instance.status,
      'schema_version': instance.schemaVersion,
      'message': instance.message,
    };

_HealthSubsystems _$HealthSubsystemsFromJson(Map<String, dynamic> json) =>
    _HealthSubsystems(
      database: DatabaseHealth.fromJson(
        json['database'] as Map<String, dynamic>,
      ),
      services: json['services'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$HealthSubsystemsToJson(_HealthSubsystems instance) =>
    <String, dynamic>{
      'database': instance.database.toJson(),
      'services': instance.services,
    };

_HealthResponse _$HealthResponseFromJson(Map<String, dynamic> json) =>
    _HealthResponse(
      status: json['status'] as String,
      service: json['service'] as String,
      subsystems: HealthSubsystems.fromJson(
        json['subsystems'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$HealthResponseToJson(_HealthResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'service': instance.service,
      'subsystems': instance.subsystems.toJson(),
    };
