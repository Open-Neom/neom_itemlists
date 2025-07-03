
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/app_flavour.dart';
import 'package:neom_commons/commons/utils/app_utilities.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/commons/utils/constants/message_translation_constants.dart';
import 'package:neom_core/core/app_config.dart';
import 'package:neom_core/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/core/data/firestore/profile_firestore.dart';
import 'package:neom_core/core/data/implementations/user_controller.dart';
import 'package:neom_core/core/domain/model/app_profile.dart';
import 'package:neom_core/core/domain/model/app_release_item.dart';
import 'package:neom_core/core/domain/model/band.dart';
import 'package:neom_core/core/domain/model/item_list.dart';
import 'package:neom_core/core/domain/use_cases/itemlist_service.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';
import 'package:neom_core/core/utils/enums/app_in_use.dart';
import 'package:neom_core/core/utils/enums/itemlist_type.dart';
import 'package:neom_core/core/utils/enums/owner_type.dart';

import 'app_media_item/app_media_item_controller.dart';

class ItemlistController extends GetxController implements ItemlistService {

  final userController = Get.find<UserController>();

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
  ItemlistType itemlistType = ItemlistType.playlist;

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
      userController.itemlistOwner = OwnerType.profile;
      profile = userController.profile;
      ownerId = profile.id;
      ownerName = profile.name;
      itemlistType = userController.defaultItemlistType;

      if(Get.arguments != null) {
        if(Get.arguments.isNotEmpty && Get.arguments[0] is Band) {
          if(Get.arguments[0] is Band) {
            band = Get.arguments[0];
            ownerId = band.id;
            ownerName = band.name;
            ownerType = OwnerType.band;

            userController.band = band;
            userController.itemlistOwner = OwnerType.band;
          } else if(Get.arguments[0] is ItemlistType) {
            itemlistType = Get.arguments[0];
          }
        }
      }

      AppConfig.logger.t('Itemlists being loaded from ${ownerType.name}');
      if(ownerType == OwnerType.profile) {
        itemlists.value = Map.from(profile.itemlists ?? {});
      } else if(ownerType == OwnerType.band){
        itemlists.value = Map.from(band.itemlists ?? {});
      }

      setItemlists();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  Future<void> setItemlists() async {
    if(itemlists.isEmpty) {
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

        if(newItemlistId.isNotEmpty){
          itemlists[newItemlistId] = newItemlist;
          if(userController.profile.itemlists == null) {
            userController.profile.itemlists = {};
            userController.profile.itemlists![newItemlistId] = newItemlist;
          } else {
            userController.profile.itemlists![newItemlistId] = newItemlist;
          }

          AppConfig.logger.t("Itemlists $itemlists");

          clearNewItemlist();
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.itemlistPrefs.tr,
              message: AppTranslationConstants.itemlistCreated.tr
          );
        } else {
          AppConfig.logger.d("Something happens trying to insert itemlist");
        }
      } else {
        AppConfig.logger.d(MessageTranslationConstants.pleaseFillItemlistInfo.tr);
        errorMsg.value = newItemlistNameController.text.isEmpty ? MessageTranslationConstants.pleaseAddName
            : MessageTranslationConstants.pleaseAddDescription;

        AppUtilities.showSnackBar(
          title: MessageTranslationConstants.addNewItemlist.tr,
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
              if (userController.profile.favoriteItems != null && userController.profile.favoriteItems!.isNotEmpty) {
                AppConfig.logger.d("Removing item from global state items for profile from userController");
                userController.profile.favoriteItems!.remove(itemId);
              }
            }
          }

        }
        itemlists.remove(itemlist.id);
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.itemlistPrefs.tr,
            message: AppTranslationConstants.itemlistRemoved.tr
        );
      } else {
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.itemlistPrefs.tr,
            message: AppTranslationConstants.itemlistRemovedErrorMsg.tr
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
              title: AppTranslationConstants.itemlistPrefs.tr,
              message: AppTranslationConstants.itemlistUpdated.tr
          );
        } else {
          AppConfig.logger.i("Something happens trying to update itemlist");
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.itemlistPrefs.tr,
              message: AppTranslationConstants.itemlistUpdatedErrorMsg.tr
          );
        }
      } else {
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.itemlistPrefs.tr,
            message: AppTranslationConstants.itemlistUpdateSameInfo.tr
        );
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppUtilities.showSnackBar(
          title: AppTranslationConstants.itemlistPrefs.tr,
          message: AppTranslationConstants.itemlistUpdatedErrorMsg.tr
      );
    }


    isLoading.value = false;
    update([AppPageIdConstants.itemlist]);
  }

  @override
  Future<void> gotoItemlistItems(Itemlist itemlist) async {

    if(AppFlavour.appInUse == AppInUse.c) {
      await Get.toNamed(AppRouteConstants.listItems, arguments: [itemlist]);
    } else {
      AppMediaItemController appItemController;
      try {
        appItemController = Get.find<AppMediaItemController>();
        appItemController.itemlist = itemlist;
        appItemController.loadItemsFromList();
      } catch (e) {
        AppConfig.logger.w(e.toString());
        AppConfig.logger.i("Controller is not active");
      }

      await Get.toNamed(AppRouteConstants.listItems, arguments: [itemlist]);
      update([AppPageIdConstants.itemlist, AppPageIdConstants.itemlistItem]);
    }

  }

  Future<void> gotoSuggestedItem() async {
    AppReleaseItem suggestedItem = AppReleaseItem(
      previewUrl: AppConfig.instance.appInfo.suggestedUrl,
      duration: 107,
    );

    Get.toNamed(AppRouteConstants.pdfViewer, arguments: [suggestedItem, true, true]);
  }


  @override
  Future<void> gotoPlaylistSongs(Itemlist itemlist) async {
    ///GOTO NeomSpotifyControlleR().gotoPlaylistSongs(itemlist);
  }

  @override
  Future<void> setPrivacyOption() async {
    AppConfig.logger.t('setPrivacyOption for Playlist');
    isPublicNewItemlist.value = !isPublicNewItemlist.value;
    AppConfig.logger.d("New Itemlist would be ${isPublicNewItemlist.value ? 'Public':'Private'}");
    update([AppPageIdConstants.itemlist, AppPageIdConstants.itemlistItem]);
  }

}
