import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
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
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:neom_core/utils/enums/push_notification_type.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/itemlist_translation_constants.dart';
import '../domain/use_cases/itemlist_items_service.dart';
import 'itemlist_controller.dart';

class ItemlistItemsController extends SintController implements ItemlistItemService {

  final userServiceImpl = Sint.find<UserService>();

  AppMediaItem appMediaItem = AppMediaItem();
  Itemlist itemlist = Itemlist();

  final RxInt itemState = 0.obs;
  final RxMap<String, dynamic> itemlistItems = <String, dynamic>{}.obs;
  final RxBool isLoading = true.obs;

  bool isFixed = false;

  String profileId = "";
  String itemlistId = "";
  Band band = Band();

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
  Future<bool> addItemToItemlist(dynamic item, String targetItemlistId) async {
    // Use targetItemlistId if provided, otherwise fall back to itemlist.id
    final String listId = targetItemlistId.isNotEmpty ? targetItemlistId : itemlist.id;
    AppConfig.logger.d("Item ${appMediaItem.name} would be added as $itemState for Itemlist $listId (owner: ${itemlistOwner.name})");

    String itemId = '';
    String itemImgUrl = '';
    bool wasAdded = false;

    try {

      if(item is AppReleaseItem) {
        wasAdded = await ItemlistFirestore().addReleaseItem(listId, item);
        itemId = item.id;
        itemImgUrl = item.imgUrl;
      } else if(item is AppMediaItem) {
        wasAdded = await ItemlistFirestore().addMediaItem(listId, item);
        itemId = item.id;
        itemImgUrl = item.imgUrl;
      } else if(item is ExternalItem) {
        wasAdded = await ItemlistFirestore().addExternalItem(listId, item);
        itemId = item.id;
        itemImgUrl = item.imgUrl;
      }

      if(wasAdded) {
        if (itemlistOwner == OwnerType.profile) {
          if (await ProfileFirestore().addFavoriteItem(profileId, appMediaItem.id)) {
            if (userServiceImpl.profile.itemlists?.isNotEmpty ?? false) {
              AppConfig.logger.d("Adding item to profile itemlist: $listId");
              if(item is AppReleaseItem) {
                userServiceImpl.profile.itemlists![listId]?.appReleaseItems?.add(item);
              } else if(item is AppMediaItem) {
                userServiceImpl.profile.itemlists![listId]?.appMediaItems?.add(item);
              } else if(item is ExternalItem) {
                userServiceImpl.profile.itemlists![listId]?.externalItems?.add(item);
              }

              if(userServiceImpl.profile.itemlists![listId] != null) {
                itemlist = userServiceImpl.profile.itemlists![listId]!;
                loadItemsFromList();
              }
            }

            FirebaseMessagingCalls.sendPublicPushNotification(
              fromProfile: userServiceImpl.profile,
              toProfileId: '',
              notificationType: PushNotificationType.appItemAdded,
              title: ItemlistTranslationConstants.addedAppItemToList,
              referenceId: itemId,
              imgUrl: itemImgUrl,
            );

            return true;
          }
        } else if (itemlistOwner == OwnerType.band) {
          if (userServiceImpl.band.itemlists?.isNotEmpty ?? false) {
            AppConfig.logger.d("Adding item to band itemlist: $listId");
            if(item is AppReleaseItem) {
              userServiceImpl.band.itemlists![listId]?.appReleaseItems?.add(item);
            } else if(item is AppMediaItem) {
              userServiceImpl.band.itemlists![listId]?.appMediaItems?.add(item);
            } else if(item is ExternalItem) {
              userServiceImpl.band.itemlists![listId]?.externalItems?.add(item);
            }

            if(userServiceImpl.band.itemlists![listId] != null) {
              itemlist = userServiceImpl.band.itemlists![listId]!;
              loadItemsFromList();
            }
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
  Future<void> updateItemlistItem(dynamic updatedItem) async {
    AppConfig.logger.d("Preview state ${updatedItem.state} for owner: ${itemlistOwner.name}");
    if(updatedItem.state == itemState.value) {
      AppConfig.logger.d("Trying to set same status");
    } else {
      try {
        bool oldVersionDeleted = false;

        // Delete old version from Firestore
        if(updatedItem is AppReleaseItem) {
          oldVersionDeleted = await ItemlistFirestore().deleteReleaseItem(itemlistId: itemlist.id, itemId: updatedItem.id);
        } else if(updatedItem is AppMediaItem) {
          oldVersionDeleted = await ItemlistFirestore().deleteMediaItem(itemlistId: itemlist.id, itemId: updatedItem.id);
        } else if(updatedItem is ExternalItem) {
          oldVersionDeleted = await ItemlistFirestore().deleteExternalItem(itemlistId: itemlist.id, itemId: updatedItem.id);
        }

        // Remove from local state based on owner type
        if(oldVersionDeleted) {
          _removeItemFromOwnerState(updatedItem);

          AppConfig.logger.d("ItemlistItem old version was deleted.");
          updatedItem.state = itemState.value;
          AppConfig.logger.d("updating itemlistItem ${updatedItem.toString()}");

          bool wasUpdated = false;
          if(updatedItem is AppReleaseItem) {
            wasUpdated = await ItemlistFirestore().addReleaseItem(itemlist.id, updatedItem);
          } else if(updatedItem is AppMediaItem) {
            wasUpdated = await ItemlistFirestore().addMediaItem(itemlist.id, updatedItem);
          } else if(updatedItem is ExternalItem) {
            wasUpdated = await ItemlistFirestore().addExternalItem(itemlist.id, updatedItem);
          }

          if(wasUpdated) {
            _addItemToOwnerState(updatedItem);
            itemlistItems.update(updatedItem.id, (itemlistItem) => itemlistItem = updatedItem);
          } else {
            AppConfig.logger.e("ItemlistItem not updated");
          }
        } else {
          AppConfig.logger.d("ItemlistItem old version was not deleted.");
        }
      } catch (e) {
        AppConfig.logger.e(e.toString());
      }

      Sint.back();
      update([AppPageIdConstants.itemlistItem]);
    }
  }

  /// Helper to remove item from the correct owner's state
  void _removeItemFromOwnerState(dynamic item) {
    Map<String, Itemlist>? ownerItemlists;

    if(itemlistOwner == OwnerType.profile) {
      ownerItemlists = userServiceImpl.profile.itemlists;
    } else if(itemlistOwner == OwnerType.band) {
      ownerItemlists = userServiceImpl.band.itemlists;
    }

    if(ownerItemlists != null && ownerItemlists[itemlist.id] != null) {
      if(item is AppReleaseItem) {
        ownerItemlists[itemlist.id]!.appReleaseItems?.remove(item);
      } else if(item is AppMediaItem) {
        ownerItemlists[itemlist.id]!.appMediaItems?.remove(item);
      } else if(item is ExternalItem) {
        ownerItemlists[itemlist.id]!.externalItems?.remove(item);
      }
    }
  }

  /// Helper to add item to the correct owner's state
  void _addItemToOwnerState(dynamic item) {
    Map<String, Itemlist>? ownerItemlists;

    if(itemlistOwner == OwnerType.profile) {
      ownerItemlists = userServiceImpl.profile.itemlists;
    } else if(itemlistOwner == OwnerType.band) {
      ownerItemlists = userServiceImpl.band.itemlists;
    }

    if(ownerItemlists != null && ownerItemlists[itemlist.id] != null) {
      if(item is AppReleaseItem) {
        ownerItemlists[itemlist.id]!.appReleaseItems?.add(item);
      } else if(item is AppMediaItem) {
        ownerItemlists[itemlist.id]!.appMediaItems?.add(item);
      } else if(item is ExternalItem) {
        ownerItemlists[itemlist.id]!.externalItems?.add(item);
      }
    }
  }

  @override
  Future<bool> removeItemFromList(String itemId) async {
    AppConfig.logger.d("removing itemlistItem ${appMediaItem.toString()}");

    dynamic item = itemlistItems[itemId];
    bool wasRemoved = false;
    try {

      if(item is AppReleaseItem) {
        wasRemoved = await ItemlistFirestore().deleteReleaseItem(itemlistId: itemlist.id, itemId: itemId);
      } else if(item is AppMediaItem) {
        wasRemoved = await ItemlistFirestore().deleteMediaItem(itemlistId: itemlist.id, itemId: itemId);
      } else if(item is ExternalItem) {
        wasRemoved = await ItemlistFirestore().deleteExternalItem(itemlistId: itemlist.id, itemId: itemId);
      }

      if(wasRemoved) {
        AppConfig.logger.d("Item was deleted from itemlist: ${itemlist.id}");

        if(itemlistOwner == OwnerType.profile) {
          if(await ProfileFirestore().removeFavoriteItem(profileId, itemId)) {
            userServiceImpl.profile.itemlists = await ItemlistFirestore().getByOwnerId(userServiceImpl.profile.id);
          }
        } else if(itemlistOwner == OwnerType.band) {
          if (userServiceImpl.band.itemlists != null && userServiceImpl.band.itemlists!.isNotEmpty) {
            AppConfig.logger.d("Removing item from global itemlist from userController");
            if(item is AppReleaseItem) {
              userServiceImpl.band.itemlists![itemlist.id]!.appReleaseItems!.remove(item);
            } else if(item is AppMediaItem) {
              userServiceImpl.band.itemlists![itemlist.id]!.appMediaItems!.remove(item);
            } else if(item is ExternalItem) {
              userServiceImpl.band.itemlists![itemlist.id]!.externalItems!.remove(item);
            }

          }
        }

        if(Sint.getInstanceInfo<ItemlistController>().isInit ?? false) {
          Sint.find<ItemlistController>().onInit();
        }
      } else {
        AppConfig.logger.d("Item was not deleted from itemlist: ${itemlist.id}");
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
    ExternalItem? externalItem;

    dynamic itemlistItem = itemlist.getItem(itemId);

    try {
      if(itemlistItem is AppReleaseItem) {
        releaseItem = itemlistItem;
      } else if(itemlistItem is AppMediaItem) {
        mediaItem = itemlistItem;
      } else if(itemlistItem is ExternalItem) {
        externalItem = itemlistItem;
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
            Sint.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [releaseItem ?? externalItem]);
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
    Map<String, dynamic> items = {};

    for (var item in itemlist.appReleaseItems ?? []) {
      items[item.id] = item;
    }

    for (var item in itemlist.appMediaItems ?? []) {
      items[item.id] = item;
    }

    for (var item in itemlist.externalItems ?? []) {
      items[item.id] = item;
    }

    itemlistItems.value = items;
    update([AppPageIdConstants.itemlistItem]);
  }

}
