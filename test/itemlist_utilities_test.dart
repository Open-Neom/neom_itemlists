// Tests for `ItemlistUtilities`.
// Mapeo declarativo entre ItemlistType y MediaSearchType.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_itemlists/utils/itemlist_utilities.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';

void main() {
  group('ItemlistUtilities.getMediaSearchType', () {
    test('playlist/single/ep/album/demo/radioStation → song', () {
      for (final type in [
        ItemlistType.playlist,
        ItemlistType.single,
        ItemlistType.ep,
        ItemlistType.album,
        ItemlistType.demo,
        ItemlistType.radioStation,
      ]) {
        expect(
          ItemlistUtilities.getMediaSearchType(type),
          MediaSearchType.song,
          reason: '$type debe mapear a song',
        );
      }
    });

    test('podcast → podcast', () {
      expect(
        ItemlistUtilities.getMediaSearchType(ItemlistType.podcast),
        MediaSearchType.podcast,
      );
    });

    test('giglist → song', () {
      expect(
        ItemlistUtilities.getMediaSearchType(ItemlistType.giglist),
        MediaSearchType.song,
      );
    });

    test('readlist/publication → book', () {
      expect(
        ItemlistUtilities.getMediaSearchType(ItemlistType.readlist),
        MediaSearchType.book,
      );
      expect(
        ItemlistUtilities.getMediaSearchType(ItemlistType.publication),
        MediaSearchType.book,
      );
    });

    test('audiobook → audiobook', () {
      expect(
        ItemlistUtilities.getMediaSearchType(ItemlistType.audiobook),
        MediaSearchType.audiobook,
      );
    });

    test('meditation → meditation', () {
      expect(
        ItemlistUtilities.getMediaSearchType(ItemlistType.meditation),
        MediaSearchType.meditation,
      );
    });

    test('cubre TODOS los ItemlistType (switch exhaustivo)', () {
      // Si se agrega un nuevo ItemlistType y este switch no lo cubre,
      // el test falla en runtime con un missing case error.
      for (final type in ItemlistType.values) {
        expect(
          () => ItemlistUtilities.getMediaSearchType(type),
          returnsNormally,
          reason: '$type no está cubierto en getMediaSearchType',
        );
      }
    });
  });
}
