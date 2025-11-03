import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';

abstract class AppItemService {

  Future<void> updateItemlistItem(AppMediaItem itemUpdate);
  Future<bool> removeItemFromList(String itemId);
  void setItemState(AppItemState newState);
  Future<void> getItemlistItemDetails(String itemId);
  Future<bool> addItemToItemlist(AppMediaItem item, String itemlistId);
  void loadItemsFromList();

}
