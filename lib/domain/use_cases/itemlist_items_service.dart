import 'package:neom_core/utils/enums/app_item_state.dart';

abstract class ItemlistItemService {

  Future<bool> addItemToItemlist(dynamic item, String targetItemlistId);
  Future<void> updateItemlistItem(dynamic updatedItem);
  Future<bool> removeItemFromList(String itemId);
  void setItemState(AppItemState newState);
  Future<void> getItemlistItemDetails(String itemId);
  void loadItemsFromList();

}
