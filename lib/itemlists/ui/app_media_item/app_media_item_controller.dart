import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_commons/core/data/firestore/band_firestore.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';

import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/band.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_commons/core/utils/enums/itemlist_owner.dart';
import 'package:neom_commons/core/utils/enums/push_notification_type.dart';
import 'package:neom_itemlists/itemlists/data/firestore/band_itemlist_firestore.dart';
import 'package:neom_music_player/ui/player/media_player_page.dart';
import '../../domain/use_cases/app_item_service.dart';

class AppMediaItemController extends GetxController implements AppItemService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  AppMediaItem appMediaItem = AppMediaItem();
  Itemlist itemlist = Itemlist();

  final RxInt _itemState = 0.obs;
  int get itemState => _itemState.value;
  set itemState(int itemState) => _itemState.value = itemState;

  final RxMap<String, AppMediaItem> _itemlistItems = <String, AppMediaItem>{}.obs;
  Map<String, AppMediaItem> get itemlistItems => _itemlistItems;
  set itemlistItems(Map<String, AppMediaItem> itemlistItems) => _itemlistItems.value  = itemlistItems;

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
        logger.i("AppMediaItemController for Itemlist ${itemlist.name}");
        logger.d("${itemlist.appMediaItems?.length ?? 0} items in itemlist");
        loadItemsFromList();
      } else {
        logger.i("ItemlistItemController Init ready loco with no itemlist");
      }

      if(AppFlavour.appInUse == AppInUse.cyberneom) {
        isFixed = true;
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
    itemlistItems = <String, AppMediaItem>{};
  }

  @override
  Future<void> updateItemlistItem(AppMediaItem updatedItem) async {
    logger.d("Preview state ${updatedItem.state}");
    if(updatedItem.state == itemState) {
      logger.d("Trying to set same status");
    } else {
      _prevItemState = updatedItem.state;
      updatedItem.state = itemState;
      logger.d("updating itemlistItem ${updatedItem.toString()}");
      try {

        if (await ItemlistFirestore().updateItem(itemlist.id, updatedItem)) {
          itemlistItems.update(updatedItem.id, (itemlistItem) => itemlistItem);
          userController.profile.itemlists![itemlist.id]!
              .appMediaItems!.add(updatedItem);
          updatedItem.state = _prevItemState;
          userController.profile.itemlists![itemlist.id]!
              .appMediaItems!.remove(updatedItem);
          if(await ItemlistFirestore().removeItem(updatedItem, itemlist.id)){
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
  Future<bool> addItemToItemlist(AppMediaItem appMediaItem, String itemlistId) async {

    logger.d("Item ${appMediaItem.name} would be added as $itemState for Itemlist $itemlistId");

    try {

      if(itemlistOwner == ItemlistOwner.profile) {
        if(await ItemlistFirestore().addAppMediaItem(appMediaItem, itemlistId)){
          if(await ProfileFirestore().addFavoriteItem(profileId, appMediaItem.id)) {
            if (userController.profile.itemlists!.isNotEmpty) {
              logger.d("Adding item to global itemlist from userController");
              userController.profile.itemlists![itemlistId]!.appMediaItems!.add(appMediaItem);
              //TODO Verify unmodifiable list
              //userController.profile.items!.add(appMediaItem.id);
              itemlist = userController.profile.itemlists![itemlistId]!;
              loadItemsFromList();
            }

            FirebaseMessagingCalls.sendGlobalPushNotification(
              fromProfile: userController.profile,
              notificationType: PushNotificationType.appItemAdded,
              referenceId: appMediaItem.id,
              imgUrl: appMediaItem.imgUrl
            );

            return true;
          }
        }
      } else if(itemlistOwner == ItemlistOwner.band) {
        if(await BandItemlistFirestore().addAppMediaItem(band.id, appMediaItem, itemlistId)){
          if(await BandFirestore().addAppMediaItem(band.id, appMediaItem.id)) {
            if (userController.band.itemlists!.isNotEmpty) {
              logger.d("Adding item to global itemlist from userController");
              userController.band.itemlists![itemlistId]!.appMediaItems!.add(appMediaItem);
              userController.band.appMediaItems!.add(appMediaItem.id);
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

    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.itemlist, AppPageIdConstants.appMediaItemDetails]);
    return false;
  }

  @override
  Future<bool> removeItemFromList(AppMediaItem appMediaItem) async {
    logger.d("removing itemlistItem ${appMediaItem.toString()}");

    try {
      if(itemlistOwner == ItemlistOwner.profile) {
        if(await ItemlistFirestore().removeItem(appMediaItem, itemlist.id)) {
          logger.d("");
          if(await ProfileFirestore().removeFavoriteItem(profileId, appMediaItem.id)) {
            if (userController.profile.itemlists != null &&
                userController.profile.itemlists!.isNotEmpty) {
              logger.d("Removing item from global itemlist from userController");
              userController.profile.itemlists = await ItemlistFirestore().fetchAll(profileId: userController.profile.id);
              itemlistItems.remove(appMediaItem.id);
            }
          }
        } else {
          logger.d("ItemlistItem not removed");
          return false;
        }
      } else if(itemlistOwner == ItemlistOwner.band) {
        if(await BandItemlistFirestore().removeItem(band.id, appMediaItem, itemlist.id)){
          logger.d("");
          if(await BandFirestore().removeItem(band.id, appMediaItem.id)) {
            if (userController.band.itemlists != null &&
                userController.band.itemlists!.isNotEmpty) {
              logger.d("Removing item from global itemlist from userController");
              userController.band.itemlists![itemlist.id]!.appMediaItems!.remove(appMediaItem);
              userController.band.appMediaItems!.remove(appMediaItem.id);
              itemlistItems.remove(appMediaItem.id);
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
  Future<void> getItemlistItemDetails(AppMediaItem appMediaItem) async {
    logger.d("getItemlistItemDetails ${appMediaItem.name}");
    switch(AppFlavour.appInUse) {
      case AppInUse.cyberneom:
        ChamberPreset chamberPreset = itemlist.chamberPresets?.firstWhere((element) => element.name == appMediaItem.name) ?? ChamberPreset();
        if(chamberPreset.name.isNotEmpty) {
          Get.toNamed(AppFlavour.getItemDetailsRoute(), arguments: [chamberPreset.clone()]
          );
        }
        break;
      case AppInUse.gigmeout:
        Get.to(() => MediaPlayerPage(appMediaItem: appMediaItem),transition: Transition.leftToRight);
        break;
      case AppInUse.emxi:
        Get.toNamed(AppFlavour.getItemDetailsRoute(), arguments: [appMediaItem]);
        break;
    }

    update([AppPageIdConstants.itemlistItem]);
  }

  @override
  void loadItemsFromList(){
    Map<String, AppMediaItem> items = {};

    if(itemlist.appReleaseItems?.isNotEmpty ?? false) {
      itemlist.appReleaseItems?.forEach((releaseItem) {
        AppMediaItem item = AppMediaItem.fromAppReleaseItem(releaseItem);
        logger.d(releaseItem.name);
        items[item.id] = item;
      });
    }

    if(itemlist.chamberPresets?.isNotEmpty ?? false) {
      itemlist.chamberPresets?.forEach((preset) {
        AppMediaItem item = AppMediaItem.fromChamberPreset(preset);
        logger.d(item.name);
        items[item.id] = item;
      });
    }

    itemlist.appMediaItems?.forEach((s) {
      logger.d(s.name);
      items[s.id] = s;
    });

    itemlistItems = items;
    update([AppPageIdConstants.itemlistItem]);
  }
  
}
