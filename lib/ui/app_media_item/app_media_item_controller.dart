import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/band.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/app_media_source.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/push_notification_type.dart';
import 'package:sint/sint.dart';

import '../../domain/use_cases/app_item_service.dart';
import '../../utils/constants/itemlist_translation_constants.dart';
import '../itemlist_controller.dart';

class AppMediaItemController extends SintController implements AppItemService {

  final userServiceImpl = Sint.find<UserService>();

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
      profileId = userServiceImpl.profile.id;
      band = userServiceImpl.band;
      itemlistOwner = userServiceImpl.itemlistOwnerType;

      if(Sint.arguments != null) {
        List<dynamic> arguments = Sint.arguments;
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
        AppConfig.logger.i("AppMediaItemController for Itemlist: ${itemlist.id} ${itemlist.name} - ${itemlist.type}");
        AppConfig.logger.d("${itemlist.appReleaseItems?.length ?? 0} release items in itemlist ${itemlist.type}");
        AppConfig.logger.d("${itemlist.appMediaItems?.length ?? 0} media items in itemlist ${itemlist.type}");
        AppConfig.logger.d("${itemlist.externalItems?.length ?? 0} external items in itemlist ${itemlist.type}");
        loadItemsFromList();
        if(itemlistItems.length == 1) {
          getItemlistItemDetails(itemlistItems.values.first.id);
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

        if (await ItemlistFirestore().addMediaItem(itemlist.id, updatedItem)) {
          itemlistItems.update(updatedItem.id, (itemlistItem) => itemlistItem);
          userServiceImpl.profile.itemlists![itemlist.id]!
              .appMediaItems!.add(updatedItem);
          updatedItem.state = _prevItemState;
          userServiceImpl.profile.itemlists![itemlist.id]!
              .appMediaItems!.remove(updatedItem);
          if(await ItemlistFirestore().deleteMediaItem(itemlistId: itemlist.id, itemId: updatedItem.id)){
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

      Sint.back();
      update([AppPageIdConstants.itemlistItem]);
    }
  }

  @override
  Future<bool> addItemToItemlist(AppMediaItem appMediaItem, String itemlistId) async {

    AppConfig.logger.d("Item ${appMediaItem.name} would be added as $itemState for Itemlist $itemlistId");

    try {
      if(await ItemlistFirestore().addMediaItem(itemlistId, appMediaItem)) {
        if (itemlistOwner == OwnerType.profile) {
          if (await ProfileFirestore().addFavoriteItem(
              profileId, appMediaItem.id)) {
            if (userServiceImpl.profile.itemlists?.isNotEmpty ?? false) {
              AppConfig.logger.d("Adding item to global itemlist from userController");
              userServiceImpl.profile.itemlists![itemlistId]!.appMediaItems!.add(appMediaItem);
              //TODO Verify unmodifiable list
              //userController.profile.items!.add(appMediaItem.id);
              itemlist = userServiceImpl.profile.itemlists![itemlistId]!;
              loadItemsFromList();
            }

            FirebaseMessagingCalls.sendPublicPushNotification(
                fromProfile: userServiceImpl.profile,
                toProfileId: '',
                notificationType: PushNotificationType.appItemAdded,
                title: ItemlistTranslationConstants.addedAppItemToList,
                referenceId: appMediaItem.id,
                imgUrl: appMediaItem.imgUrl,
            );

            return true;
          }
        } else if (itemlistOwner == OwnerType.band) {
          if (userServiceImpl.band.itemlists!.isNotEmpty) {
            AppConfig.logger.d("Adding item to global itemlist from userController");
            userServiceImpl.band.itemlists![itemlistId]!.appMediaItems!.add(appMediaItem);
            itemlist = userServiceImpl.band.itemlists![itemlistId]!;
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
  Future<bool> removeItemFromList(String itemId) async {
    AppConfig.logger.d("removing itemlistItem ${appMediaItem.toString()}");

    AppReleaseItem? releaseItem;
    bool wasRemoved = false;
    try {

      if(appMediaItem.mediaSource == AppMediaSource.internal && (itemlist.appReleaseItems?.isNotEmpty ?? false)) {
        releaseItem = itemlist.appReleaseItems!.firstWhereOrNull((item) => item.id == appMediaItem.id);
      }

      if(releaseItem != null && await ItemlistFirestore().deleteReleaseItem(itemlistId: itemlist.id, itemId: releaseItem.id)) {
        AppConfig.logger.d("ReleaseItem was deleted from itemlist: ${itemlist.id}");
        wasRemoved = true;
      } else if(await ItemlistFirestore().deleteMediaItem(itemlistId: itemlist.id, itemId: appMediaItem.id)) {
        AppConfig.logger.d("AppMediaItem was deleted from itemlist: ${itemlist.id}");
        wasRemoved = true;
      }

      if(wasRemoved) {
        if(itemlistOwner == OwnerType.profile) {
          if(await ProfileFirestore().removeFavoriteItem(profileId, appMediaItem.id)) {
            if (userServiceImpl.profile.itemlists != null &&
                userServiceImpl.profile.itemlists!.isNotEmpty) {
              AppConfig.logger.d("Removing item from global itemlist from userController");
              userServiceImpl.profile.itemlists = await ItemlistFirestore().fetchAll(ownerId: userServiceImpl.profile.id);
              itemlistItems.remove(appMediaItem.id);
            }
          }
        } else if(itemlistOwner == OwnerType.band) {
          if (userServiceImpl.band.itemlists != null && userServiceImpl.band.itemlists!.isNotEmpty) {
            AppConfig.logger.d("Removing item from global itemlist from userController");
            if(releaseItem != null) {
              userServiceImpl.band.itemlists![itemlist.id]!.appReleaseItems!.remove(releaseItem);
            } else {
              userServiceImpl.band.itemlists![itemlist.id]!.appMediaItems!.remove(appMediaItem);
            }

            itemlistItems.remove(appMediaItem.id);
          }
        }

        if(Sint.getInstanceInfo<ItemlistController>().isInit ?? false) {
          Sint.find<ItemlistController>().onInit();
        }
      } else {
        AppConfig.logger.d("ItemlistItem not removed");
        return false;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }

    Sint.back();
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
  Future<void> getItemlistItemDetails(String itemId) async {
    AppConfig.logger.d("getItemlistItemDetails for Item with ID: $itemId");

    //GET ITEM FROM ID
    AppReleaseItem? releaseItem;
    AppMediaItem? mediaItem;

    dynamic itemlistItem = itemlist.getItem(itemId);

    try {
      if(itemlistItem is AppReleaseItem) {
        releaseItem = itemlistItem;
      } else if(itemlistItem is AppMediaItem) {
        mediaItem = itemlistItem;
      } else if(itemlistItem is ExternalItem) {

      }

      if(appMediaItem.imgUrl.isEmpty && itemlist.imgUrl.isNotEmpty) appMediaItem.imgUrl = itemlist.imgUrl;

      switch(AppConfig.instance.appInUse) {
        case AppInUse.c:
          Sint.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [releaseItem]);
          break;
        case AppInUse.g:
          Sint.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [releaseItem]);
          break;
        case AppInUse.e:
          if(itemlist.type == ItemlistType.readlist) {
            Sint.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [releaseItem]);
          } else {
            Sint.toNamed(AppFlavour.getSecondaryItemDetailsRoute(), arguments: [mediaItem]);
          }
          break;
        default:
          Sint.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [releaseItem]);
          break;
      }
    } catch(e) {
      AppConfig.logger.e(e.toString());
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
