import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';

abstract class AppItemService {

  Future<void> updateItemlistItem(AppMediaItem itemUpdate);
  Future<void> removeItemFromList(AppMediaItem item);
  void setItemState(AppItemState newState);
  Future<void> getItemlistItemDetails(AppMediaItem item);
  Future<bool> addItemToItemlist(AppMediaItem item, String itemlistId);
  void loadItemsFromList();

}
