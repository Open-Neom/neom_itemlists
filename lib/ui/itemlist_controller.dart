
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/band.dart';
import 'package:neom_core/domain/model/item_found_in_list.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/itemlist_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';

import '../utils/constants/itemlist_translation_constants.dart';
import 'itemlist_items_controller.dart';

class ItemlistController extends GetxController implements ItemlistService {

  ItemlistController({ItemlistType? type}) :
        itemlistType = type ?? AppFlavour.getDefaultItemlistType(),
        super() {
          if(Get.find<UserService>().currentItemlistType != null && type == null) {
            itemlistType = Get.find<UserService>().currentItemlistType!;
          } else {
            Get.find<UserService>().setCurrentItemlistType(itemlistType);
          }
        }

  final userServiceImpl = Get.find<UserService>();

  Itemlist currentItemlist = Itemlist();

  TextEditingController newItemlistNameController = TextEditingController();
  TextEditingController newItemlistDescController = TextEditingController();

  final RxMap<String, Itemlist> itemlists = <String, Itemlist>{}.obs;
  final RxList<Itemlist> addedItemlists = <Itemlist>[].obs;

  AppProfile profile = AppProfile();
  Band band = Band();
  String ownerId = '';
  String ownerName = '';
  OwnerType ownerType = OwnerType.profile;
  ItemlistType itemlistType;

  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;

  final RxBool isPublicNewItemlist = true.obs;
  final RxString errorMsg = "".obs;

  RxString itemName = "".obs;
  RxInt itemNumber = 0.obs;
  int totalItemsToSync = 0;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("onInit Itemlist Controller");

    try {
      userServiceImpl.itemlistOwnerType = OwnerType.profile;
      profile = userServiceImpl.profile;
      ownerId = profile.id;
      ownerName = profile.name;

      if(Get.arguments != null) {
        if(Get.arguments.isNotEmpty && Get.arguments[0] is Band) {
          if(Get.arguments[0] is Band) {
            band = Get.arguments[0];
            ownerId = band.id;
            ownerName = band.name;
            ownerType = OwnerType.band;

            userServiceImpl.band = band;
            userServiceImpl.itemlistOwnerType = OwnerType.band;
          } else if(Get.arguments[0] is ItemlistType) {
            itemlistType = Get.arguments[0];
          }
        }
      }


    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    AppConfig.logger.t('Itemlists being loaded from ${ownerType.name}');
    if(ownerType == OwnerType.profile) {
      itemlists.value = Map.from(profile.itemlists ?? {});
    } else if(ownerType == OwnerType.band){
      itemlists.value = Map.from(band.itemlists ?? {});
    }

    setItemlists();
  }

  Future<void> setItemlists() async {
    if(itemlists.isEmpty || (itemlists.values.any((list) => list.type != itemlistType))) {
      itemlists.value = await ItemlistFirestore().getByOwnerId(ownerId, ownerType: ownerType,
          itemlistType: itemlistType
      );
    } else {
      itemlists.removeWhere((id, itemlist) {
        return itemlist.type != itemlistType;
      });
    }

    isLoading.value = false;
    update([AppPageIdConstants.itemlist]);
    AppConfig.logger.d('${itemlists.length} Itemlists Type: ${itemlistType.name} were loaded from OwnerType: ${ownerType.name}');
  }

  void clear() {
    itemlists.value = <String, Itemlist>{};
    currentItemlist = Itemlist();
  }

  @override
  void clearNewItemlist() {
    newItemlistNameController.clear();
    newItemlistDescController.clear();
  }

  void setItemlistType(ItemlistType type) {
    AppConfig.logger.d("Setting itemlistType to $itemlistType");
    itemlistType = type;
    update([AppPageIdConstants.itemlist]);
  }

  @override
  Future<void> createItemlist({ItemlistType? type}) async {
    AppConfig.logger.d("Start ${newItemlistNameController.text} and ${newItemlistDescController.text}");

    try {
      errorMsg.value = '';
      if((isPublicNewItemlist.value && newItemlistNameController.text.isNotEmpty)
          || (!isPublicNewItemlist.value && newItemlistNameController.text.isNotEmpty)) {
        Itemlist newItemlist = Itemlist(
          name: newItemlistNameController.text,
          description: newItemlistDescController.text,
          ownerId: ownerId,
          ownerName: ownerName,
          ownerType: ownerType,
          type: type ?? itemlistType,
          public: isPublicNewItemlist.value,
        );

        String newItemlistId = "";

        if (profile.position?.latitude != 0.0) {
          newItemlist.position = profile.position!;
        }

        newItemlistId = await ItemlistFirestore().insert(newItemlist);

        AppConfig.logger.i("Empty Itemlist created successfully for profile ${newItemlist.ownerId}");
        newItemlist.id = newItemlistId;

        if(newItemlistId.isNotEmpty) {
          itemlists[newItemlistId] = newItemlist;
          if(userServiceImpl.profile.itemlists == null) {
            userServiceImpl.profile.itemlists = {};
            userServiceImpl.profile.itemlists![newItemlistId] = newItemlist;
          } else {
            userServiceImpl.profile.itemlists![newItemlistId] = newItemlist;
          }

          AppConfig.logger.t("Itemlists $itemlists");

          clearNewItemlist();
          AppUtilities.showSnackBar(
              title: CommonTranslationConstants.itemlistPrefs.tr,
              message: ItemlistTranslationConstants.itemlistCreated.tr
          );
        } else {
          AppConfig.logger.d("Something happens trying to insert itemlist");
        }
      } else {
        AppConfig.logger.d(MessageTranslationConstants.pleaseFillItemlistInfo.tr);
        errorMsg.value = newItemlistNameController.text.isEmpty ? MessageTranslationConstants.pleaseAddName
            : MessageTranslationConstants.pleaseAddDescription;

        AppUtilities.showSnackBar(
          title: CommonTranslationConstants.addNewItemlist.tr,
          message: MessageTranslationConstants.pleaseFillItemlistInfo.tr,
        );
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.itemlist]);
  }

  @override
  Future<void> deleteItemlist(Itemlist itemlist) async {
    AppConfig.logger.d("Removing for $itemlist");

    try {
      isLoading.value = true;
      update([AppPageIdConstants.itemlist]);

      if(await ItemlistFirestore().delete(itemlist.id)) {
        AppConfig.logger.d("Itemlist ${itemlist.id} removed");

        if((itemlist.appMediaItems?.isNotEmpty ?? false) && ownerType == OwnerType.profile) {
          List<String> appMediaItemsIds = itemlist.appMediaItems!.map((e) => e.id).toList();

          if(await ProfileFirestore().removeFavoriteItems(profile.id, appMediaItemsIds)) {
            for (var itemId in appMediaItemsIds) {
              if (userServiceImpl.profile.favoriteItems != null && userServiceImpl.profile.favoriteItems!.isNotEmpty) {
                AppConfig.logger.d("Removing item from global state items for profile from userController");
                userServiceImpl.profile.favoriteItems!.remove(itemId);
              }
            }
          }

        }
        itemlists.remove(itemlist.id);
        AppUtilities.showSnackBar(
            title: CommonTranslationConstants.itemlistPrefs.tr,
            message: CommonTranslationConstants.itemlistRemoved.tr
        );
      } else {
        AppUtilities.showSnackBar(
            title: CommonTranslationConstants.itemlistPrefs.tr,
            message: MessageTranslationConstants.itemlistRemovedErrorMsg.tr
        );
        AppConfig.logger.e("Something happens trying to remove itemlist");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.itemlist]);
  }

  @override
  Future<void> updateItemlist(String itemlistId, Itemlist itemlist) async {

    AppConfig.logger.d("Updating to $itemlist");

    try {
      isLoading.value = true;
      update([AppPageIdConstants.itemlist]);
      String newName = newItemlistNameController.text;
      String newDesc = newItemlistDescController.text;

      if((newName.isNotEmpty && newName.toLowerCase() != itemlist.name.toLowerCase())
          || (newDesc.isNotEmpty && newDesc.toLowerCase() != itemlist.description.toLowerCase())) {

        if(newItemlistNameController.text.isNotEmpty) {
          itemlist.name = newItemlistNameController.text;
        }

        if(newItemlistDescController.text.isNotEmpty) {
          itemlist.description = newItemlistDescController.text;
        }

        if(await ItemlistFirestore().update(itemlist)){
          AppConfig.logger.d("Itemlist $itemlistId updated");
          itemlists[itemlist.id] = itemlist;
          clearNewItemlist();
          AppUtilities.showSnackBar(
              title: CommonTranslationConstants.itemlistPrefs.tr,
              message: CommonTranslationConstants.itemlistUpdated.tr
          );
        } else {
          AppConfig.logger.i("Something happens trying to update itemlist");
          AppUtilities.showSnackBar(
              title: CommonTranslationConstants.itemlistPrefs.tr,
              message: MessageTranslationConstants.itemlistUpdatedErrorMsg.tr
          );
        }
      } else {
        AppUtilities.showSnackBar(
            title: CommonTranslationConstants.itemlistPrefs.tr,
            message: CommonTranslationConstants.itemlistUpdateSameInfo.tr
        );
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppUtilities.showSnackBar(
          title: CommonTranslationConstants.itemlistPrefs.tr,
          message: MessageTranslationConstants.itemlistUpdatedErrorMsg.tr
      );
    }


    isLoading.value = false;
    update([AppPageIdConstants.itemlist]);
  }

  @override
  Future<void> setPrivacyOption() async {
    AppConfig.logger.t('setPrivacyOption for Playlist');
    isPublicNewItemlist.value = !isPublicNewItemlist.value;
    AppConfig.logger.d("New Itemlist would be ${isPublicNewItemlist.value ? 'Public':'Private'}");
    update([AppPageIdConstants.itemlist, AppPageIdConstants.itemlistItem]);
  }

  ///NEW
  ///
  AppMediaItem appMediaItem = AppMediaItem();
  final RxString itemlistId = "".obs;
  final RxInt appItemState = 0.obs;
  final RxBool existsInItemlist = false.obs;
  final RxBool wasAdded = false.obs;
  ItemFoundInList? itemFoundInList;

  @override
  Future<Itemlist> createBasicItemlist() async {
    Itemlist newItemlist = Itemlist.createBasic(ItemlistTranslationConstants.myFirstPlaylist.tr, ItemlistTranslationConstants.myFirstPlaylistDesc.tr,
        profile.id, profile.name, ItemlistType.playlist);

    String listId = await ItemlistFirestore().insert(newItemlist);
    newItemlist.id = listId;

    return newItemlist;
  }

  @override
  void setSelectedItemlist(String selectedItemlist){
    AppConfig.logger.d("Setting selectedItemlist $selectedItemlist");
    itemlistId.value  = selectedItemlist;
    itemFoundInList = AppUtilities.getItemFoundInList(itemlists.values.toList(), appMediaItem.id);
    existsInItemlist.value = itemFoundInList != null;
    update([AppPageIdConstants.appItemDetails]);
  }

  @override
  Future<void> addItemlistItem(BuildContext context, {int fanItemState = 0, bool goHome = true}) async {
    AppConfig.logger.t("addItemlistItem ${appMediaItem.id}");


    if(existsInItemlist.value) {
      AppUtilities.showSnackBar(message: '"${appMediaItem.name}" ${ItemlistTranslationConstants.isAlreadyInPlaylist.tr} ${itemFoundInList?.listName}');
    } else {
      isLoading.value = true;
      update([AppPageIdConstants.appItemDetails]);
      AppConfig.logger.i("AppMediaItem ${appMediaItem.name} would be added as $appItemState for Itemlist $itemlistId");

      try {

        if(fanItemState > 0) appItemState.value = fanItemState;
        if(itemlistId.isEmpty) itemlistId.value = itemlists.values.first.id;

        ItemlistItemsController itemController;
        if (Get.isRegistered<ItemlistItemsController>()) {
          itemController = Get.find<ItemlistItemsController>();
        } else {
          itemController = Get.put(ItemlistItemsController());
        }

        AppMediaItemFirestore().existsOrInsert(appMediaItem);

        if(!existsInItemlist.value) {
          appMediaItem.state = appItemState.value;
          if(await itemController.addItemToItemlist(appMediaItem, itemlistId.value)){
            AppConfig.logger.d("Setting existsInItemlist and wasAdded true");
            existsInItemlist.value = true;
            wasAdded.value = true;
          }
        }

      } catch (e) {
        AppConfig.logger.d(e.toString());
      }

      update([AppPageIdConstants.itemlistItem,
        AppPageIdConstants.itemlist,
        AppPageIdConstants.appItemDetails,
        AppPageIdConstants.profile]);

      try {
        if(goHome) {
          Get.offAllNamed(AppRouteConstants.home);
        } else {
          Navigator.pop(context);
        }
        AppUtilities.showSnackBar(
            message: '"${appMediaItem.name}" ${ItemlistTranslationConstants.wasAddedToItemList.tr}.'
        );
      } catch (e) {
        Get.offAllNamed(AppRouteConstants.home);
        Get.toNamed(AppRouteConstants.listItems);
      }
    }

  }

  @override
  int getItemState() {
  AppConfig.logger.d("Getting appItemState $appItemState");
    return appItemState.value;
  }

  @override
  bool checkIsLoading() {
    return isLoading.value;
  }

  @override
  void setAppMediaItem(AppMediaItem item) {
    AppConfig.logger.d("Setting appMediaItem $item");
    appMediaItem = item;
    update([AppPageIdConstants.appItemDetails]);
  }

  @override
  String getSelectedItemlist() {
    AppConfig.logger.d("Getting selectedItemlist $itemlistId");
    return itemlistId.value;
  }

  @override
  List<Itemlist> getItemlists() {
    return itemlists.values.toList();
  }

  @override
  void setAppItemState(AppItemState newState) {
    appItemState.value = newState.value;
    AppConfig.logger.d("Setting new appItemState $newState");
    appItemState.value = newState.value;
    update([AppPageIdConstants.appItemDetails]);
  }

}
