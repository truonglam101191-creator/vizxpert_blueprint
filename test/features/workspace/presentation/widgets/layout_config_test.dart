import 'package:flutter_test/flutter_test.dart';
import 'package:vizxpert_blueprint/features/workspace/presentation/widgets/workspace_toolbar.dart';

void main() {
  group('LayoutConfig Tests', () {
    test('default constructor should set all panels to visible', () {
      const config = LayoutConfig();

      expect(config.showSidebar, isTrue);
      expect(config.showProperties, isTrue);
      expect(config.showTimeline, isTrue);
      expect(config.sidebarWidth, 220.0);
      expect(config.propertiesWidth, 280.0);
      expect(config.timelineHeight, 130.0);
    });

    test('copyWith should update specified fields and retain others', () {
      const config = LayoutConfig();
      final updatedConfig = config.copyWith(
        showSidebar: false,
        sidebarWidth: 300.0,
      );

      // Updated fields
      expect(updatedConfig.showSidebar, isFalse);
      expect(updatedConfig.sidebarWidth, 300.0);

      // Retained fields
      expect(updatedConfig.showProperties, isTrue);
      expect(updatedConfig.showTimeline, isTrue);
      expect(updatedConfig.propertiesWidth, 280.0);
      expect(updatedConfig.timelineHeight, 130.0);
    });

    test('fromPreset(compact) should set narrower dimensions', () {
      final config = LayoutConfig.fromPreset(LayoutPreset.compact);

      expect(config.showSidebar, isTrue);
      expect(config.sidebarWidth, 180.0);
      expect(config.propertiesWidth, 240.0);
      expect(config.timelineHeight, 90.0);
    });

    test('fromPreset(wide) should set wider dimensions', () {
      final config = LayoutConfig.fromPreset(LayoutPreset.wide);

      expect(config.showSidebar, isTrue);
      expect(config.sidebarWidth, 280.0);
      expect(config.propertiesWidth, 360.0);
      expect(config.timelineHeight, 160.0);
    });

    test('fromPreset(cinematic) should hide all panels', () {
      final config = LayoutConfig.fromPreset(LayoutPreset.cinematic);

      expect(config.showSidebar, isFalse);
      expect(config.showProperties, isFalse);
      expect(config.showTimeline, isFalse);
    });
  });
}
