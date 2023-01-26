import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/domain/use_cases/itemlist_service.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/itemlist_owner.dart';
import 'package:neom_commons/core/utils/enums/spotify_search_type.dart';
import '../data/firestore/app_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'app_item/app_item_controller.dart';

class ItemlistController extends GetxController implements ItemlistService {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  Itemlist currentItemlist = Itemlist();

  final RxMap<String, Itemlist> _itemlists = <String, Itemlist>{}.obs;
  Map<String, Itemlist> get itemlists => _itemlists;
  set itemlists(Map<String, Itemlist> itemlists) => _itemlists.value = itemlists;

  final RxMap<String, Itemlist> _spotifyItemlists = <String, Itemlist>{}.obs;
  Map<String, Itemlist> get spotifyItemlists => _spotifyItemlists;
  set spotifyItemlists(Map<String, Itemlist> spotifyItemlists) => _spotifyItemlists.value = spotifyItemlists;

  final RxList<Itemlist> _addedItemlists = <Itemlist>[].obs;
  List<Itemlist> get addedItemlists => _addedItemlists;
  set addedItemlists(List<Itemlist> addedItemlists) => _addedItemlists.value = addedItemlists;

  Itemlist _favItemlist = Itemlist();
  AppProfile profile = AppProfile();

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  ItemlistOwner itemlistOwner = ItemlistOwner.profile;

  TextEditingController newItemlistNameController = TextEditingController();
  TextEditingController newItemlistDescController = TextEditingController();

  bool outOfSync = true;
  bool spotifyAvailable = true;

  @override
  void onInit() async {
    super.onInit();
    logger.d("");

    try {
      profile = userController.profile;
      userController.itemlistOwner = ItemlistOwner.profile;
      if(profile.itemlists!.isNotEmpty) {
        logger.d("Itemlists loaded from userController");
        itemlists = profile.itemlists!;
      } else {
        logger.d("Itemlists loaded from Firestore");
        itemlists = await ItemlistFirestore().retrieveItemlists(profile.id);
      }
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {

    try {
      // await getSpotifyToken();
      // if(userController.user!.spotifyToken.isNotEmpty
      //     && userController.profile.lastSpotifySync < DateTime.now()
      //         .subtract(const Duration(days: 30)).millisecondsSinceEpoch
      // ) {
      //   logger.d("Spotify Last Sync was more than 30 days");
      //   outOfSync = true;
      //
      // } else {
      //   logger.i("Spotify Last Sync in scope");
      // }

    } catch (e) {
      logger.e(e.toString());
      Get.snackbar(
          MessageTranslationConstants.spotifySynchronization.tr,
          e.toString(),
          snackPosition: SnackPosition.bottom,
      );
      spotifyAvailable = false;
    }
    isLoading = false;
    update([AppPageIdConstants.itemlist]);
  }


  void clear() {
    itemlists = <String, Itemlist>{};
    currentItemlist = Itemlist();
  }


  void clearNewItemlist() {
    newItemlistNameController.clear();
    newItemlistDescController.clear();
  }


  @override
  Future<void> createItemlist() async {
    logger.d("Start ${newItemlistNameController.text} and ${newItemlistDescController.text}");

    try {
      Get.back();
      
      if(newItemlistNameController.text.isNotEmpty) {
        Itemlist basicItemlist = Itemlist.createBasic(newItemlistNameController.text, newItemlistDescController.text);
        String newItemlistId = await ItemlistFirestore().insert(profile.id, basicItemlist);
        logger.i("Empty Itemlist created successfully for profile ${profile.id}");

        basicItemlist.id = newItemlistId;

        if(newItemlistId.isNotEmpty){
          itemlists[newItemlistId] = basicItemlist;
          logger.i("Itemlists $itemlists");
          clearNewItemlist();
        } else {
          logger.d("Something happens trying to insert itemlist");
        }
      } else {
        Get.snackbar(
            MessageTranslationConstants.addNewItemlist.tr,
            MessageTranslationConstants.pleaseFillItemlistInfo.tr,
            snackPosition: SnackPosition.bottom);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.itemlist]);
  }

  Future<void> searchItemlist() async {

    logger.d("Start ${newItemlistNameController.text} and ${newItemlistDescController.text}");

    Get.back();

    try {
      if(newItemlistNameController.text.isNotEmpty) {
        await Get.toNamed(AppRouteConstants.playlistSearch,
            arguments: [
              SpotifySearchType.playlist,
              newItemlistNameController.text]
        );
      } else {
        Get.snackbar(
            MessageTranslationConstants.searchPlaylist.tr,
            MessageTranslationConstants.missingPlaylistName.tr,
            snackPosition: SnackPosition.bottom);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.itemlist]);
  }


  @override
  Future<void> deleteItemlist(Itemlist itemlist) async {
    logger.d("Removing for $itemlist");

    try {
      isLoading = true;
      update([AppPageIdConstants.itemlist]);

      if(await ItemlistFirestore().remove(profile.id, itemlist.id)) {
        logger.d("Itemlist ${itemlist.id} removed");

        if(itemlist.appItems?.isNotEmpty ?? false) {
          for(var appItem in itemlist.appItems ?? []) {
            if(await ProfileFirestore().removeItem(profile.id, appItem.id)) {
              if (userController.profile.appItems != null &&
                  userController.profile.appItems!.isNotEmpty) {
                logger.d("Removing item from global items for profile from userController");
                userController.profile.appItems!.remove(appItem.id);
              }
            }
          }
        }

        itemlists.remove(itemlist.id);
      } else {
        logger.e("Something happens trying to remove itemlist");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    Get.back();
    update([AppPageIdConstants.itemlist]);
  }


  @override
  Future<void> setAsFavorite(Itemlist itemlist) async {
    logger.d("Making favorite for $itemlist");

    try {
      if(await ItemlistFirestore().setAsFavorite(profile.id, itemlist)){
        itemlist.isFav = true;
        itemlists[itemlist.id] = itemlist;
        logger.i("Itemlist ${itemlist.id} set as favorite");
        if(await ItemlistFirestore().unsetOfFavorite(profile.id, _favItemlist)) {
          logger.i("Itemlist ${profile.id} unset from favorite");
          _favItemlist.isFav = false;
          itemlists[_favItemlist.id] = _favItemlist;
        }
        _favItemlist = itemlist;
      } else {
        logger.e("Something happens trying to remove itemlist");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    Get.back();
    update([AppPageIdConstants.itemlist]);
  }


  @override
  Future<void> updateItemlist(String itemlistId, Itemlist itemlist) async {

    logger.d("Updating to $itemlist");

    try {
      isLoading = true;
      update([AppPageIdConstants.itemlist]);

      if(newItemlistNameController.text.isNotEmpty || newItemlistDescController.text.isNotEmpty) {

        if(newItemlistNameController.text.isNotEmpty) {
          itemlist.name = newItemlistNameController.text;
        }

        if(newItemlistDescController.text.isNotEmpty) {
          itemlist.description = newItemlistDescController.text;
        }

        if(await ItemlistFirestore().update(profile.id, itemlist)){
          logger.d("Itemlist $itemlistId updated");
          _itemlists[itemlist.id] = itemlist;
          clearNewItemlist();
        } else {
          logger.i("Something happens trying to update itemlist");
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }


    isLoading = false;
    Get.back();
    update([AppPageIdConstants.itemlist]);
  }


  Future<void> gotoItemlistItems(Itemlist itemlist) async {

    AppItemController appItemController;
    try {
      appItemController = Get.find<AppItemController>();
      appItemController.itemlist = itemlist;
      appItemController.loadItemsFromList();
    } catch (e) {
      logger.e(e.toString());
      logger.i("Controller is not active");
    }

    await Get.toNamed(AppRouteConstants.listItems, arguments: [itemlist]);
    update([AppPageIdConstants.itemlist, AppPageIdConstants.itemlistItem]);

  }

  RxString itemName = "".obs;
  RxInt itemNumber = 0.obs;
  int totalItemsToSynch = 0;

  Future<bool> synchronizeItemlist(Itemlist itemlist) async {
    logger.i("Synchronizing Itemlist ${itemlist.name}");
    isButtonDisabled = true;
    isLoading = true;
    bool wasSync = false;
    try {

      String itemlistId = "";
      Itemlist? existingItemlist;
      List<Itemlist>? existingItemlists = userController.profile.itemlists?.values.where((element) => element.name == itemlist.name).toList();

      if(existingItemlists?.isNotEmpty ?? false) {
        existingItemlist= existingItemlists?.first;
      }

      if(existingItemlist?.id.isNotEmpty ?? false) {

        List<AppItem> currentItems = [];
        itemlistId = existingItemlist?.id ?? "";

        itemlist.appItems?.forEach((appItem) {
          List<AppItem>? itemlistItems = existingItemlist?.appItems?.where((element) => element.id == appItem.id).toList();
          if(itemlistItems?.isNotEmpty ?? false) {
            currentItems.add(appItem);
          }
        });

        for (AppItem currentItem in currentItems) {
          itemlist.appItems?.removeWhere((appItem) => appItem.id == currentItem.id);
          logger.d("Removing item ${currentItem.name} from being synchronized");
        }

        totalItemsToSynch -= currentItems.length;
      }

      if(itemlistId.isEmpty) {
        if(itemlistOwner == ItemlistOwner.profile) {
          itemlistId = await ItemlistFirestore().insert(profile.id, itemlist);
        } else if(itemlistOwner == ItemlistOwner.band) {
          //TODO Add sync for band itemlist
          //itemlistId = await BandItemlistFirestore().insert(_gigBand.id, itemlist);
        }

        logger.i("Itemlist inserted with id $itemlistId");
      }

      if(itemlistId.isNotEmpty && (itemlist.appItems?.isNotEmpty ?? false)) {
        itemlist.id = itemlistId;

        if(itemlistOwner == ItemlistOwner.profile) {
          userController.profile.itemlists![itemlist.id] = itemlist;
          currentItemlist = itemlist;

          for (AppItem appItem in itemlist.appItems ?? []) {

            itemName.value = appItem.name;
            itemNumber++;
            update([AppPageIdConstants.itemlist, AppPageIdConstants.playlistSong]);

            AppItemFirestore().existsOrInsert(appItem);

            if(await ProfileFirestore().addAppItem(profile.id, appItem.id)) {
              if (userController.profile.itemlists!.isNotEmpty) {
                logger.d("Adding item to global itemlist from userController");
                userController.profile.appItems!.add(appItem.id);
              }
            }


          }

        } else if(itemlistOwner == ItemlistOwner.band) {
          userController.band.itemlists![itemlist.id] = itemlist;
          for (var appItem in itemlist.appItems ?? []) {

            AppItemFirestore().existsOrInsert(appItem);
            //TODO Add sync for band itemlist
          }
        }
        logger.d("Items added successfully from Itemlist");
        wasSync = true;
      } else {
        Get.snackbar(
            MessageTranslationConstants.spotifySynchronization.tr,
            "Itemlist ${itemlist.name} ${MessageTranslationConstants.upToDate.tr}",
            snackPosition: SnackPosition.bottom,
            duration: const Duration(seconds: 1)
        );
      }
      isButtonDisabled = false;
    } catch (e) {
      logger.e(e.toString());
    }

    update();
    return wasSync;
  }

}
