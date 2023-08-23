import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';

abstract class AppItemSearchService {

  Future<void> setSearchParam(String text);
  Future<void> searchAppMediaItem();
  void getAppMediaItemDetails(AppMediaItem appMediaItem);
  void getItemListDetails(Itemlist itemList);

}
