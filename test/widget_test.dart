import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:h_stream/models/media_item.dart';
import 'package:h_stream/models/tag_filter_state.dart';
import 'package:h_stream/models/catalog_model.dart';
import 'package:h_stream/providers/tag_matrix_provider.dart';
import 'package:h_stream/providers/stealth_provider.dart';
import 'package:h_stream/providers/vault_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HStream Architecture Unit Tests', () {
    test('3-State Boolean Tag Matrix Cycle Test', () {
      final matrix = TagMatrixProvider();
      expect(matrix.getTagState("Uncensored"), TagFilterState.neutral);

      // Tap 1: Included (+)
      matrix.cycleTagState("Uncensored");
      expect(matrix.getTagState("Uncensored"), TagFilterState.included);
      expect(matrix.whitelistedTags.contains("Uncensored"), isTrue);

      // Tap 2: Excluded (-) Blacklist
      matrix.cycleTagState("Uncensored");
      expect(matrix.getTagState("Uncensored"), TagFilterState.excluded);
      expect(matrix.blacklistedTags.contains("Uncensored"), isTrue);

      // Tap 3: Reset back to Neutral
      matrix.cycleTagState("Uncensored");
      expect(matrix.getTagState("Uncensored"), TagFilterState.neutral);
    });

    test('Stealth Calculator Decoy Mode Test', () {
      final stealth = StealthProvider();
      expect(stealth.currentMode, StealthMode.normal);

      stealth.activateCalculatorDecoy();
      expect(stealth.currentMode, StealthMode.calculatorDecoy);

      // Wrong code fails
      final wrongUnlock = stealth.unlockFromDecoy("0000");
      expect(wrongUnlock, isFalse);
      expect(stealth.currentMode, StealthMode.calculatorDecoy);

      // Secret unlock code works (7777)
      final correctUnlock = stealth.unlockFromDecoy("7777");
      expect(correctUnlock, isTrue);
      expect(stealth.currentMode, StealthMode.normal);
    });

    test('Encrypted Private Vault PIN Test', () {
      final vault = VaultProvider();
      expect(vault.isUnlocked, isFalse);

      // Incorrect PIN fails
      expect(vault.unlockWithPin("9999"), isFalse);
      expect(vault.isUnlocked, isFalse);

      // Default PIN (1234) unlocks vault
      expect(vault.unlockWithPin("1234"), isTrue);
      expect(vault.isUnlocked, isTrue);

      vault.lockVault();
      expect(vault.isUnlocked, isFalse);
    });

    test('MediaItem Model Serialization Test', () {
      final item = MediaItem(
        id: "test_1",
        title: "Cyberpunk Lucy 3D 60FPS",
        url: "https://rule34video.com/video/1",
        cover: "https://picsum.photos/640/360",
        duration: "04:15",
        type: MediaType.shortClip,
        tags: ["3D", "MMD", "4K"],
        isUncensored: true,
      );

      final json = item.toJson();
      final restored = MediaItem.fromJson(json);

      expect(restored.id, "test_1");
      expect(restored.title, "Cyberpunk Lucy 3D 60FPS");
      expect(restored.type, MediaType.shortClip);
      expect(restored.isUncensored, isTrue);
    });

    test('CatalogRepository Taxonomy Expansion & Matrix Sync Test', () {
      final allItems = CatalogRepository.getAllItems();
      expect(allItems.length, greaterThanOrEqualTo(140));
      expect(CatalogRepository.categories.length, greaterThanOrEqualTo(15));
      expect(CatalogRepository.genres.length, greaterThanOrEqualTo(18));
      expect(CatalogRepository.tags.length, greaterThanOrEqualTo(100));

      final matrix = TagMatrixProvider();
      expect(matrix.allTags.length, allItems.length);
      expect(matrix.allTags.any((t) => t.name == "Maid"), isTrue);
      expect(matrix.allTags.any((t) => t.name == "Uncensored"), isTrue);
      expect(matrix.allTags.any((t) => t.name == "Vanilla"), isTrue);
      expect(matrix.allTags.any((t) => t.name == "Genshin Impact"), isTrue);
    });

    test('Dynamic ExtensionTaxonomy and BaseExtension Fallback Test', () async {
      final defaultTaxonomy = ExtensionTaxonomy.fromDefaultCatalog();
      expect(defaultTaxonomy.categories.length, greaterThanOrEqualTo(15));
      expect(defaultTaxonomy.tagsAndGenres.length, greaterThanOrEqualTo(120));

      final emptyTaxonomy = ExtensionTaxonomy.empty;
      expect(emptyTaxonomy.categories, isEmpty);
      expect(emptyTaxonomy.tagsAndGenres, isEmpty);
    });
  });
}
