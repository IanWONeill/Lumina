import 'package:freezed_annotation/freezed_annotation.dart';

part 'version_info.freezed.dart';
part 'version_info.g.dart';

@freezed
class VersionInfo with _$VersionInfo {
  const factory VersionInfo({
    required String version,
    required String url,
    required String notes,
  }) = _VersionInfo;

  factory VersionInfo.fromJson(Map<String, dynamic> json) =>
      _$VersionInfoFromJson(json);
} 