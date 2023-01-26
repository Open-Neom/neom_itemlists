import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';

abstract class AppItemSearchService {

  Future<void> setSearchParam(String text);
  Future<void> searchAppItem();
  void getAppItemDetails(AppItem appItem);
  void getItemListDetails(Itemlist itemList);

}
