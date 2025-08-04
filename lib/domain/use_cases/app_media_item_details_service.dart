import 'package:flutter/cupertino.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';

abstract class AppMediaItemDetailsService {

  void clear();
  void setAppItemState(AppItemState newState);
  void setSelectedItemlist(String selectedItemlist);
  void getAppItemDetails(String itemId);
  Future<void> addItemlistItem(BuildContext context, {int fanItemState = 0});
  Future<void> removeItem();
  bool itemAlreadyInList();

}
