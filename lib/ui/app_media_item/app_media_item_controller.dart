import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/band.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/push_notification_type.dart';

import '../../domain/use_cases/app_item_service.dart';
import '../../utils/constants/itemlist_translation_constants.dart';
import '../itemlist_controller.dart';

class AppMediaItemController extends GetxController implements AppItemService {

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
    AppConfig.logger.d("ItemlistItem Controller init");
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
        AppConfig.logger.i("AppMediaItemController for Itemlist: ${itemlist.id} ${itemlist.name} ");
        AppConfig.logger.d("${itemlist.appReleaseItems?.length ?? 0} internal items in itemlist");
        AppConfig.logger.d("${itemlist.appMediaItems?.length ?? 0} external items in itemlist");
        loadItemsFromList();
        if(itemlistItems.length == 1) {
          getItemlistItemDetails(itemlistItems.values.first);
        }
      } else {
        AppConfig.logger.i("ItemlistItemController Init ready with no itemlist");
      }

      if(AppConfig.instance.appInUse == AppInUse.c) {
        isFixed = true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
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
    AppConfig.logger.d("Preview state ${updatedItem.state}");
    if(updatedItem.state == itemState.value) {
      AppConfig.logger.d("Trying to set same status");
    } else {
      _prevItemState = updatedItem.state;
      updatedItem.state = itemState.value;
      AppConfig.logger.d("updating itemlistItem ${updatedItem.toString()}");
      try {

        if (await ItemlistFirestore().updateItem(itemlist.id, updatedItem)) {
          itemlistItems.update(updatedItem.id, (itemlistItem) => itemlistItem);
          userController.profile.itemlists![itemlist.id]!
              .appMediaItems!.add(updatedItem);
          updatedItem.state = _prevItemState;
          userController.profile.itemlists![itemlist.id]!
              .appMediaItems!.remove(updatedItem);
          if(await ItemlistFirestore().deleteItem(itemlistId: itemlist.id, appMediaItem: updatedItem)){
            AppConfig.logger.d("ItemlistItem was updated and old version deleted.");
          } else {
            AppConfig.logger.d("ItemlistItem was updated but old version remains.");
          }
          updatedItem.state = itemState.value;
        } else {
          AppConfig.logger.e("ItemlistItem not updated");
        }
      } catch (e) {
        AppConfig.logger.e(e.toString());
      }

      Get.back();
      update([AppPageIdConstants.itemlistItem]);
    }
  }

  @override
  Future<bool> addItemToItemlist(AppMediaItem appMediaItem, String itemlistId) async {

    AppConfig.logger.d("Item ${appMediaItem.name} would be added as $itemState for Itemlist $itemlistId");

    try {
      if(await ItemlistFirestore().addAppMediaItem(appMediaItem, itemlistId)) {
        if (itemlistOwner == OwnerType.profile) {
          if (await ProfileFirestore().addFavoriteItem(
              profileId, appMediaItem.id)) {
            if (userController.profile.itemlists?.isNotEmpty ?? false) {
              AppConfig.logger.d("Adding item to global itemlist from userController");
              userController.profile.itemlists![itemlistId]!.appMediaItems!.add(appMediaItem);
              //TODO Verify unmodifiable list
              //userController.profile.items!.add(appMediaItem.id);
              itemlist = userController.profile.itemlists![itemlistId]!;
              loadItemsFromList();
            }

            FirebaseMessagingCalls.sendPublicPushNotification(
                fromProfile: userController.profile,
                toProfileId: '',
                notificationType: PushNotificationType.appItemAdded,
                title: ItemlistTranslationConstants.addedAppItemToList,
                referenceId: appMediaItem.id,
                imgUrl: appMediaItem.imgUrl,
            );

            return true;
          }
        } else if (itemlistOwner == OwnerType.band) {
          if (userController.band.itemlists!.isNotEmpty) {
            AppConfig.logger.d("Adding item to global itemlist from userController");
            userController.band.itemlists![itemlistId]!.appMediaItems!.add(appMediaItem);
            itemlist = userController.band.itemlists![itemlistId]!;
            loadItemsFromList();
          }
          return true;
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.itemlist, AppPageIdConstants.appMediaItemDetails]);
    return false;
  }

  @override
  Future<bool> removeItemFromList(AppMediaItem appMediaItem) async {
    AppConfig.logger.d("removing itemlistItem ${appMediaItem.toString()}");

    AppReleaseItem? releaseItem;
    bool wasRemoved = false;
    try {

      if(appMediaItem.mediaSource == AppMediaSource.internal && (itemlist.appReleaseItems?.isNotEmpty ?? false)) {
        releaseItem = itemlist.appReleaseItems!.firstWhereOrNull((item) => item.id == appMediaItem.id);
      }

      if(releaseItem != null && await ItemlistFirestore().deleteReleaseItem(itemlist.id, releaseItem)) {
        AppConfig.logger.d("ReleaseItem was deleted from itemlist: ${itemlist.id}");
        wasRemoved = true;
      } else if(await ItemlistFirestore().deleteItem(itemlistId: itemlist.id, appMediaItem: appMediaItem

      )) {
        AppConfig.logger.d("AppMediaItem was deleted from itemlist: ${itemlist.id}");
        wasRemoved = true;
      }

      if(wasRemoved) {
        if(itemlistOwner == OwnerType.profile) {
          if(await ProfileFirestore().removeFavoriteItem(profileId, appMediaItem.id)) {
            if (userController.profile.itemlists != null &&
                userController.profile.itemlists!.isNotEmpty) {
              AppConfig.logger.d("Removing item from global itemlist from userController");
              userController.profile.itemlists = await ItemlistFirestore().fetchAll(ownerId: userController.profile.id);
              itemlistItems.remove(appMediaItem.id);
            }
          }
        } else if(itemlistOwner == OwnerType.band) {
          if (userController.band.itemlists != null && userController.band.itemlists!.isNotEmpty) {
            AppConfig.logger.d("Removing item from global itemlist from userController");
            if(releaseItem != null) {
              userController.band.itemlists![itemlist.id]!.appReleaseItems!.remove(releaseItem);
            } else {
              userController.band.itemlists![itemlist.id]!.appMediaItems!.remove(appMediaItem);
            }

            itemlistItems.remove(appMediaItem.id);
          }
        }

        if(Get.getInstanceInfo<ItemlistController>().isInit ?? false) {
          Get.find<ItemlistController>().onInit();
        }
      } else {
        AppConfig.logger.d("ItemlistItem not removed");
        return false;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }

    Get.back();
    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.itemlist]);
    return true;
  }


  @override
  void setItemState(AppItemState newState){
    AppConfig.logger.d("Setting new itemState $newState");
    itemState.value = newState.value;
    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.appItem]);
  }

  @override
  Future<void> getItemlistItemDetails(AppMediaItem appMediaItem) async {
    AppConfig.logger.d("getItemlistItemDetails ${appMediaItem.name}");

    if(appMediaItem.imgUrl.isEmpty && itemlist.imgUrl.isNotEmpty) appMediaItem.imgUrl = itemlist.imgUrl;

    ///DELETE SWITCH WHEN READLIST IS APART
    switch(AppConfig.instance.appInUse) {
      case AppInUse.c:
        Get.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [appMediaItem]);
        break;
      case AppInUse.g:
        Get.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [appMediaItem]);
        break;
      case AppInUse.e:
        if(itemlist.type == ItemlistType.readlist) {
          Get.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [appMediaItem]);
        } else {
          Get.toNamed(AppFlavour.getSecondaryItemDetailsRoute(), arguments: [appMediaItem]);
        }
        break;
      default:
        Get.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [appMediaItem]);
        break;
    }

    update([AppPageIdConstants.itemlistItem]);
  }

  @override
  void loadItemsFromList(){
    Map<String, AppMediaItem> items = {};

    itemlist.appReleaseItems?.forEach((releaseItem) {
      AppMediaItem item = AppMediaItemMapper.fromAppReleaseItem(releaseItem);
      AppConfig.logger.d(releaseItem.name);
      items[item.id] = item;
    });

    itemlist.appMediaItems?.forEach((item) {
      AppConfig.logger.d(item.name);
      items[item.id] = item;
    });

    itemlistItems.value = items;
    update([AppPageIdConstants.itemlistItem]);
  }
  
}
