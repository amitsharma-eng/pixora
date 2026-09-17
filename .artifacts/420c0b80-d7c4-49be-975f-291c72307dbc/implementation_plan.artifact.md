# Plan to reach 160/160 pub.dev score for Pixora

To achieve a perfect score on pub.dev, a package must follow all best practices, have zero analysis issues, and provide complete documentation.

## User Review Required

> [!IMPORTANT]
> I will be adding an **MIT License** file. Please confirm if this is your intended license.
> I will also remove `publish_to: none` from `pubspec.yaml` to allow publishing to pub.dev.

## Proposed Changes

### Metadata & Legal

#### [NEW] [LICENSE](file:///Users/apple/Documents/flutter_projects/pixora/LICENSE)
- Create a standard MIT License file as mentioned in the README.

#### [MODIFY] [pubspec.yaml](file:///Users/apple/Documents/flutter_projects/pixora/pubspec.yaml)
- Remove `publish_to: none`.
- Ensure `description` is high quality (60-130 chars).
- Verify `environment` constraints are appropriate.

### Lint & Code Quality

#### [MODIFY] [pixora.dart](file:///Users/apple/Documents/flutter_projects/pixora/lib/pixora.dart)
- Remove `library pixora;` to fix `unnecessary_library_name` lint.

#### [MODIFY] [pixora_cache_manager.dart](file:///Users/apple/Documents/flutter_projects/pixora/lib/src/cache/pixora_cache_manager.dart)
- Remove unnecessary `dart:typed_data` import.

#### [MODIFY] [pixora_placeholder.dart](file:///Users/apple/Documents/flutter_projects/pixora/lib/src/widgets/pixora_placeholder.dart)
- Fix `unnecessary_underscores` lint.

### Documentation

#### [MODIFY] ALL PUBLIC FILES
- Add `///` doc comments to all public classes, constructors, methods, and properties.
- Files to be updated:
    - [pixora.dart](file:///Users/apple/Documents/flutter_projects/pixora/lib/pixora.dart)
    - [pixora_cache_policy.dart](file:///Users/apple/Documents/flutter_projects/pixora/lib/src/core/pixora_cache_policy.dart)
    - [pixora_config.dart](file:///Users/apple/Documents/flutter_projects/pixora/lib/src/core/pixora_config.dart)
    - [pixora_image_state.dart](file:///Users/apple/Documents/flutter_projects/pixora/lib/src/core/pixora_image_state.dart)
    - [pixora_cache_manager.dart](file:///Users/apple/Documents/flutter_projects/pixora/lib/src/cache/pixora_cache_manager.dart)
    - [pixora_error.dart](file:///Users/apple/Documents/flutter_projects/pixora/lib/src/widgets/pixora_error.dart)
    - [pixora_image.dart](file:///Users/apple/Documents/flutter_projects/pixora/lib/src/widgets/pixora_image.dart)
    - [pixora_placeholder.dart](file:///Users/apple/Documents/flutter_projects/pixora/lib/src/widgets/pixora_placeholder.dart)

### Platform Support
- Investigate `dart:io` usage in `PixoraImage` and `PixoraCacheManager` to see if we can easily add Web support (which significantly helps the score).

## Verification Plan

### Automated Tests
- Run `dart analyze` to ensure 0 issues.
- Run `dart format .` to ensure consistent formatting.
- Run `flutter test` to ensure no regressions.

### Manual Verification
- Verify the package score using `dart pub publish --dry-run` which provides a preliminary score/report.
