import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';

class ItemlistUtilities {

  static MediaSearchType getMediaSearchType(ItemlistType itemlistType) {
    switch(itemlistType) {
      case ItemlistType.playlist:
      case ItemlistType.single:
      case ItemlistType.ep:
      case ItemlistType.album:
      case ItemlistType.demo:
      case ItemlistType.radioStation:
        return MediaSearchType.song;

      case ItemlistType.podcast:
        return MediaSearchType.audiobook;

      case ItemlistType.giglist:
        return MediaSearchType.song;

      case ItemlistType.readlist:
      case ItemlistType.publication:
        return MediaSearchType.book;

      case ItemlistType.audiobook:
        return MediaSearchType.audiobook;
      }
  }

}
