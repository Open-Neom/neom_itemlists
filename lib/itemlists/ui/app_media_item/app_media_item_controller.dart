import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/band.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_commons/core/utils/enums/owner_type.dart';
import 'package:neom_commons/core/utils/enums/push_notification_type.dart';
import 'package:neom_music_player/ui/player/media_player_controller.dart';

import '../../domain/use_cases/app_item_service.dart';

class AppMediaItemController extends GetxController implements AppItemService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  AppMediaItem appMediaItem = AppMediaItem();
  Itemlist itemlist = Itemlist();

  final RxInt itemState = 0.obs;
  final RxMap<String, AppMediaItem> itemlistItems = <String, AppMediaItem>{}.obs;
  final RxBool isLoading = true.obs;

  bool isFixed = false;

  String profileId = "";
  String itemlistId = "";
  Band band = Band();
  int _prevItemState = 0;
  OwnerType itemlistOwner = OwnerType.profile;


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
        if(arguments[0] is Itemlist) {
          itemlist =  arguments[0];
        } else if(arguments[0] is String) {
          itemlistId = arguments[0];
          itemlist = await ItemlistFirestore().retrieve(itemlistId);
        }
        if(arguments.length > 1) {
          isFixed = arguments[1];
        }
      }

      if(itemlist.id.isNotEmpty) {
        logger.i("AppMediaItemController for Itemlist: ${itemlist.id} ${itemlist.name} ");
        logger.d("${itemlist.appMediaItems?.length ?? 0} items in itemlist");
        loadItemsFromList();
      } else {
        logger.i("ItemlistItemController Init ready loco with no itemlist");
      }

      if(AppFlavour.appInUse == AppInUse.c) {
        isFixed = true;
      }
    } catch (e) {
      logger.e(e.toString());
    }

  }


  @override
  void onReady() {
    super.onReady();
    isLoading.value = false;
    update([AppPageIdConstants.itemlistItem]);
  }

  void clear() {
    itemlistItems.value = <String, AppMediaItem>{};
  }

  @override
  Future<void> updateItemlistItem(AppMediaItem updatedItem) async {
    logger.d("Preview state ${updatedItem.state}");
    if(updatedItem.state == itemState.value) {
      logger.d("Trying to set same status");
    } else {
      _prevItemState = updatedItem.state;
      updatedItem.state = itemState.value;
      logger.d("updating itemlistItem ${updatedItem.toString()}");
      try {

        if (await ItemlistFirestore().updateItem(itemlist.id, updatedItem)) {
          itemlistItems.update(updatedItem.id, (itemlistItem) => itemlistItem);
          userController.profile.itemlists![itemlist.id]!
              .appMediaItems!.add(updatedItem);
          updatedItem.state = _prevItemState;
          userController.profile.itemlists![itemlist.id]!
              .appMediaItems!.remove(updatedItem);
          if(await ItemlistFirestore().deleteItem(updatedItem, itemlist.id)){
            logger.d("ItemlistItem was updated and old version deleted.");
          } else {
            logger.d("ItemlistItem was updated but old version remains.");
          }
          updatedItem.state = itemState.value;
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
      if(await ItemlistFirestore().addAppMediaItem(appMediaItem, itemlistId)) {
        if (itemlistOwner == OwnerType.profile) {
          if (await ProfileFirestore().addFavoriteItem(
              profileId, appMediaItem.id)) {
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
        } else if (itemlistOwner == OwnerType.band) {
          if (userController.band.itemlists!.isNotEmpty) {
            logger.d("Adding item to global itemlist from userController");
            userController.band.itemlists![itemlistId]!.appMediaItems!.add(appMediaItem);
            itemlist = userController.band.itemlists![itemlistId]!;
            loadItemsFromList();
          }
          return true;
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
      if(await ItemlistFirestore().deleteItem(appMediaItem, itemlist.id)) {
        logger.d("");

        if(itemlistOwner == OwnerType.profile) {
          if(await ProfileFirestore().removeFavoriteItem(profileId, appMediaItem.id)) {
            if (userController.profile.itemlists != null &&
                userController.profile.itemlists!.isNotEmpty) {
              logger.d("Removing item from global itemlist from userController");
              userController.profile.itemlists = await ItemlistFirestore().fetchAll(ownerId: userController.profile.id);
              itemlistItems.remove(appMediaItem.id);
            }
          }
        } else if(itemlistOwner == OwnerType.band) {
          ///DEPRECATED if(await BandItemlistFirestore().removeItem(band.id, appMediaItem, itemlist.id)){
          ///DEPRECATED if(await BandFirestore().removeItem(band.id, appMediaItem.id)) {
          if (userController.band.itemlists != null && userController.band.itemlists!.isNotEmpty) {
            logger.d("Removing item from global itemlist from userController");
            userController.band.itemlists![itemlist.id]!.appMediaItems!.remove(appMediaItem);
            ///DEPRECATED userController.band.appMediaItems!.remove(appMediaItem.id);
            itemlistItems.remove(appMediaItem.id);
          }
          ///DEPRECATED}
          ///DEPRECATED}
        }

      } else {
        logger.d("ItemlistItem not removed");
        return false;
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
    itemState.value = newState.value;
    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.appItem]);
  }

  @override
  Future<void> getItemlistItemDetails(AppMediaItem appMediaItem) async {
    logger.d("getItemlistItemDetails ${appMediaItem.name}");

    if(appMediaItem.imgUrl.isEmpty && itemlist.imgUrl.isNotEmpty) appMediaItem.imgUrl = itemlist.imgUrl;

    ///DELETE SWITCH WHEN READLIST IS APART
    switch(AppFlavour.appInUse) {
      case AppInUse.c:
        if (Get.isRegistered<MediaPlayerController>()) {
          Get.delete<MediaPlayerController>();
          Get.toNamed(AppRouteConstants.musicPlayerMedia, arguments: [appMediaItem]);
        } else {
          Get.toNamed(AppRouteConstants.musicPlayerMedia, arguments: [appMediaItem]);
        }
        break;
      case AppInUse.g:
        ///DEPRECATED Get.to(() => MediaPlayerPage(appMediaItem: appMediaItem),transition: Transition.leftToRight);
        if (Get.isRegistered<MediaPlayerController>()) {
          Get.delete<MediaPlayerController>();
          Get.toNamed(AppRouteConstants.musicPlayerMedia, arguments: [appMediaItem]);
        } else {
          Get.toNamed(AppRouteConstants.musicPlayerMedia, arguments: [appMediaItem]);
        }

        break;
      case AppInUse.e:
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

    itemlist.appMediaItems?.forEach((item) {
      logger.d(item.name);
      items[item.id] = item;
    });

    itemlistItems.value = items;
    update([AppPageIdConstants.itemlistItem]);
  }
  
}
