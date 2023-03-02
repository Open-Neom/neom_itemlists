import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/band_firestore.dart';

import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/domain/model/band.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_commons/core/utils/enums/itemlist_owner.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_itemlists/itemlists/data/firestore/band_itemlist_firestore.dart';
import '../../domain/use_cases/app_item_service.dart';

class AppItemController extends GetxController implements AppItemService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  AppItem appItem = AppItem();
  Itemlist itemlist = Itemlist();

  final RxInt _itemState = 0.obs;
  int get itemState => _itemState.value;
  set itemState(int itemState) => _itemState.value = itemState;

  final RxMap<String, AppItem> _itemlistItems = <String, AppItem>{}.obs;
  Map<String, AppItem> get itemlistItems => _itemlistItems;
  set itemlistItems(Map<String, AppItem> itemlistItems) => _itemlistItems.value  = itemlistItems;

  final RxBool _isPlaying = false.obs;
  bool get isPlaying => _isPlaying.value;
  set isPlaying(bool isPlaying) => _isPlaying.value = isPlaying;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  bool isFixed = false;

  String profileId = "";
  Band band = Band();
  int _prevItemState = 0;
  ItemlistOwner itemlistOwner = ItemlistOwner.profile;


  @override
  void onInit() async {
    super.onInit();
    logger.d("ItemlistItem Controller init");
    try {
      profileId = userController.profile.id;
      band = userController.band;
      itemlistOwner = userController.itemlistOwner;

      if(Get.arguments != null) {
        List<dynamic> arguments = Get.arguments;
        itemlist =  arguments[0];
        if(arguments.length > 1) {
          isFixed = arguments[1];
        }
      }

      if(itemlist.id.isNotEmpty) {
        logger.i("AppItemController for Itemlist ${itemlist.name}");
        logger.d("${itemlist.appItems?.length ?? 0} items in itemlist");
        loadItemsFromList();
      } else {
        logger.i("ItemlistItemController Init ready loco with no itemlist");
      }
    } catch (e) {
      logger.e(e.toString());
    }

  }


  @override
  void onReady() {
    super.onReady();
    logger.d("");
    isLoading = false;
    update([AppPageIdConstants.itemlistItem]);
  }

  void clear() {
    itemlistItems = <String, AppItem>{};
  }

  @override
  Future<void> updateItemlistItem(AppItem updatedItem) async {
    logger.d("Preview state ${updatedItem.state}");
    if(updatedItem.state == itemState) {
      logger.d("Trying to set same status");
    } else {
      _prevItemState = updatedItem.state;
      updatedItem.state = itemState;
      logger.d("updating itemlistItem ${updatedItem.toString()}");
      try {
        if (await ItemlistFirestore().updateItem(profileId, itemlist.id, updatedItem)) {
          itemlistItems.update(updatedItem.id, (itemlistItem) => itemlistItem);
          userController.profile.itemlists![itemlist.id]!
              .appItems!.add(updatedItem);
          updatedItem.state = _prevItemState;
          userController.profile.itemlists![itemlist.id]!
              .appItems!.remove(updatedItem);
          if(await ItemlistFirestore().removeItem(profileId, updatedItem, itemlist.id)){
            logger.d("ItemlistItem was updated and old version deleted.");
          } else {
            logger.d("ItemlistItem was updated but old version remains.");
          }
          updatedItem.state = itemState;
        } else {
          logger.e("ItemlistItem not updated");
        }
      } catch (e) {
        logger.e(e.toString());
      }

      Get.back();
      update([AppPageIdConstants.itemlistItem]);
    }
  }

  @override
  Future<bool> addItemToItemlist(AppItem appItem, String itemlistId) async {

    logger.d("Item ${appItem.name} would be added as $itemState for Itemlist $itemlistId");

    try {

      if(itemlistOwner == ItemlistOwner.profile) {
        if(await ItemlistFirestore().addAppItem(profileId, appItem, itemlistId)){
          if(await ProfileFirestore().addAppItem(profileId, appItem.id)){
            if (userController.profile.itemlists!.isNotEmpty) {
              logger.d("Adding item to global itemlist from userController");
              userController.profile.itemlists![itemlistId]!.appItems!.add(appItem);
              //TODO Verify unmodifiable list
              //userController.profile.items!.add(appItem.id);
              itemlist = userController.profile.itemlists![itemlistId]!;
              loadItemsFromList();
            }
            return true;
          }
        }
      } else if(itemlistOwner == ItemlistOwner.band) {
        if(await BandItemlistFirestore().addAppItem(band.id, appItem, itemlistId)){
          if(await BandFirestore().addAppItem(band.id, appItem.id)) {
            if (userController.band.itemlists!.isNotEmpty) {
              logger.d("Adding item to global itemlist from userController");
              userController.band.itemlists![itemlistId]!.appItems!.add(appItem);
              userController.band.appItems!.add(appItem.id);
              itemlist = userController.band.itemlists![itemlistId]!;
              loadItemsFromList();
            }
            return true;
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.itemlist, AppPageIdConstants.appItemDetails]);
    return false;
  }

  @override
  Future<bool> removeItemFromList(AppItem appItem) async {
    logger.d("removing itemlistItem ${appItem.toString()}");

    try {
      if(itemlistOwner == ItemlistOwner.profile) {
        if(await ItemlistFirestore().removeItem(profileId, appItem, itemlist.id)){
          logger.d("");
          if(await ProfileFirestore().removeAppItem(profileId, appItem.id)) {
            if (userController.profile.itemlists != null &&
                userController.profile.itemlists!.isNotEmpty) {
              logger.d("Removing item from global itemlist from userController");
              userController.profile.itemlists![itemlist.id]!.appItems!.remove(appItem);
              //userController.profile.items!.remove(appItem.id);
              itemlistItems.remove(appItem.id);
            }
          }
        } else {
          logger.d("ItemlistItem not removed");
          return false;
        }
      } else if(itemlistOwner == ItemlistOwner.band) {
        if(await BandItemlistFirestore().removeItem(band.id, appItem, itemlist.id)){
          logger.d("");
          if(await BandFirestore().removeItem(band.id, appItem.id)) {
            if (userController.band.itemlists != null &&
                userController.band.itemlists!.isNotEmpty) {
              logger.d("Removing item from global itemlist from userController");
              userController.band.itemlists![itemlist.id]!.appItems!.remove(appItem);
              userController.band.appItems!.remove(appItem.id);
              itemlistItems.remove(appItem.id);
            }
          }
        } else {
          logger.d("ItemlistItem not removed");
          return false;
        }
      }
    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    Get.back();
    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.itemlist]);
    return true;
  }


  @override
  void setItemState(AppItemState newState){
    logger.d("Setting new itemState $newState");
    itemState = newState.value;
    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.appItem]);
  }

  @override
  Future<void> getItemlistItemDetails(AppItem appItem) async {
    logger.d("");
    Get.toNamed(AppFlavour.getItemDetailsRoute(),
        arguments: [appItem]
    );
    update([AppPageIdConstants.itemlistItem]);
  }

  @override
  void loadItemsFromList(){
    Map<String, AppItem> items = {};

    itemlist.appItems?.forEach((s) {
      logger.d(s.name);
      items[s.id] = s;
    });

    itemlistItems = items;
    update([AppPageIdConstants.itemlistItem]);
  }
  
}
