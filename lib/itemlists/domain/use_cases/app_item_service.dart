import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';

abstract class AppItemService {

  Future<void> updateItemlistItem(AppItem appItemUpdate);
  Future<void> removeItemFromList(AppItem appItem);
  void setItemState(AppItemState newState);
  Future<void> getItemlistItemDetails(AppItem appItem);
  Future<bool> addItemToItemlist(AppItem appItem, String itemlistId);

}
