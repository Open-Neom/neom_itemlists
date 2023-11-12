// ignore_for_file: use_build_context_synchronously

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';

import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:neom_events/events/ui/event_details_controller.dart';
import '../../data/firestore/app_media_item_firestore.dart';
import 'app_media_item_controller.dart';


class AppMediaItemDetailsController extends GetxController {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  AppProfile profile = AppProfile();
  Band band = Band();
  OwnerType itemlistOwner = OwnerType.profile;
  AppMediaItem appMediaItem = AppMediaItem();

  final RxString itemlistId = "".obs;
  final RxString durationMinutes = "".obs;
  final RxInt appItemState = 0.obs;
  final RxMap<String, Itemlist> itemlists = <String, Itemlist>{}.obs;

  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;
  final RxBool existsInItemlist = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool wasAdded = false.obs;

  ///VerifY IF NEEDED with music player
  final AudioPlayer audioPlayer = AudioPlayer(playerId: AppFlavour.getAppName());

  AppReleaseItem releasedItem = AppReleaseItem();
  String releasedItemId = "";
  bool isReleaseItem = false;
  bool allowFullAccess = true;

  AppCurrency currentCurrency = AppCurrency.mxn;
  double digitalAmount = 0;
  double physicalAmount = 0;

  @override
  void onInit() async {
    super.onInit();
    logger.d("AppMediaItem Details Controller init");

    try {
      profile = userController.profile;
      band = userController.band;
      itemlistOwner = userController.itemlistOwner;

      audioPlayer.setReleaseMode(ReleaseMode.stop);
      audioPlayer.stop();
      audioPlayer.release();
      if(itemlistOwner == OwnerType.profile) {
        itemlists.assignAll(profile.itemlists ?? {});
      } else if(itemlistOwner == OwnerType.band) {
        itemlists.assignAll(band.itemlists ?? {});
      }

      List<dynamic> arguments  = Get.arguments ?? [];

      if(arguments.isNotEmpty) {
        if(Get.arguments[0] is AppMediaItem) {
          appMediaItem =  arguments.elementAt(0);
          releasedItemId = appMediaItem.id;
        } else if(Get.arguments[0] is String) {
          releasedItemId = Get.arguments[0];
        }

        existsInItemlist.value = itemAlreadyInList();

        if (arguments.length > 1) { //to save in previously selected itemlist
          itemlistId.value =  arguments.elementAt(1);
        }
      }

      if(itemlists.isNotEmpty && itemlists.isNotEmpty && itemlistId.isEmpty) {
        itemlistId.value = itemlists.values.first.id;
      }

    } catch (e) {
      logger.e(e.toString());
    }

  }


  @override
  void onReady() async {
    super.onReady();
    logger.i("AppMediaItem ${appMediaItem.id} Details Controller Ready");

    try {

      if(releasedItemId.isNotEmpty) {
        releasedItem = await AppReleaseItemFirestore().retrieve(releasedItemId);
        if(releasedItem.id.isNotEmpty) {
          isReleaseItem = true;
          appMediaItem = AppMediaItem.fromAppReleaseItem(releasedItem);
          digitalAmount = releasedItem.digitalPrice!.amount;
          physicalAmount = releasedItem.physicalPrice?.amount ?? 0;
          currentCurrency = releasedItem.digitalPrice!.currency;
          if((releasedItem.boughtUsers?.contains(userController.user!.id) ?? false)
              || (userController.user!.releaseItemIds?.contains(releasedItem.id) ?? false)
              || (userController.user!.boughtItems?.contains(releasedItem.id) ?? false)
          ) {
            allowFullAccess = true;
          }
        }
      }

      if(itemlists.isEmpty) {
        Get.offAllNamed(AppRouteConstants.home);
        AppUtilities.showSnackBar(title: AppTranslationConstants.noItemlistsMsg, message: AppTranslationConstants.noItemlistsMsg2);
      }
    } catch(e) {
      logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.appItemDetails]);
  }

  @override
  void dispose() {
    super.dispose();
    clear();
    audioPlayer.stop();
    audioPlayer.release();
    isPlaying.value = false;
  }

  void clear() {
    appMediaItem = AppMediaItem();
    itemlistId.value = "";
  }

  void setAppItemState(AppItemState newState){
    logger.d("Setting new appItemState $newState");
    appItemState.value = newState.value;
    update([AppPageIdConstants.appItemDetails]);
  }

  void setSelectedItemlist(String selectedItemlist){
    logger.d("Setting selectedItemlist $selectedItemlist");
    itemlistId.value  = selectedItemlist;
    existsInItemlist.value = itemAlreadyInList();
    update([AppPageIdConstants.appItemDetails]);
  }

  void getAppItemDetails(String itemId) async {
    logger.d("");

    try {
      appMediaItem = await AppMediaItemFirestore().retrieve(itemId);
      durationMinutes.value = AppUtilities.getDurationInMinutes(appMediaItem.duration);
    } catch (e) {
      logger.d(e.toString());
    }
    update([AppPageIdConstants.appItemDetails]);
  }


  Future<void> addItemlistItem(BuildContext context, {int fanItemState = 0}) async {

    if(!isButtonDisabled.value) {

      isButtonDisabled.value = true;
      isLoading.value = true;
      update([AppPageIdConstants.appItemDetails]);

      logger.i("AppMediaItem ${appMediaItem.name} would be added as $appItemState for Itemlist $itemlistId");

      if(fanItemState > 0) appItemState.value = fanItemState;
      if(itemlistId.isEmpty) itemlistId.value = itemlists.values.first.id;

      await audioPlayer.stop();
      isPlaying.value = false;

      AppMediaItemController appMediaItemController;

      try {
        appMediaItemController = Get.find<AppMediaItemController>();
      } catch (e) {
        appMediaItemController = Get.put(AppMediaItemController());
      }

      try {
        if(!await AppMediaItemFirestore().exists(appMediaItem.id)) {
          await AppMediaItemFirestore().insert(appMediaItem);
        }

        if(!existsInItemlist.value) {
          appMediaItem.state = appItemState.value;

          if(await appMediaItemController.addItemToItemlist(appMediaItem, itemlistId.value)){
            logger.d("Setting existsInItemlist and wasAdded true");
            existsInItemlist.value = true;
            wasAdded.value = true;
          }
        }


      } catch (e) {
        logger.d(e.toString());
      }

      update([AppPageIdConstants.itemlistItem,
        AppPageIdConstants.itemlist,
        AppPageIdConstants.appItemDetails,
        AppPageIdConstants.profile]);

      try {
        if(itemlistOwner == OwnerType.profile) {
          if(Get.find<EventDetailsController>().initialized) {
            Get.find<EventDetailsController>().addToMatchedItems(appMediaItem);
            Navigator.of(context).popUntil(ModalRoute.withName(AppRouteConstants.eventDetails));
          } else {
            Get.offAllNamed(AppRouteConstants.home);
            Get.toNamed(AppRouteConstants.listItems);
          }
        } else {
          Get.offAllNamed(AppRouteConstants.home);
          Get.toNamed(AppRouteConstants.bandsRoom);
          Get.toNamed(AppRouteConstants.bandLists);
        }

      } catch (e) {
        Get.offAllNamed(AppRouteConstants.home);
        Get.toNamed(AppRouteConstants.listItems);
      }
    }

  }

  Future<void> removeItem() async {
    logger.d("removing Item ${appMediaItem.toString()} from itemlist");

    await audioPlayer.stop();
    isPlaying.value = false;

    AppMediaItemController appMediaItemController;
    try {
      appMediaItemController = Get.find<AppMediaItemController>();
    } catch (e) {
      appMediaItemController = Get.put(AppMediaItemController());
    }


    try {
      if(await appMediaItemController.removeItemFromList(appMediaItem)) {
        logger.d("YEAH");
      } else {
        logger.d("Item not removed from Itemlist");
      }
    } catch (e) {
      logger.d(e.toString());
    }

    Get.back();
    update([AppPageIdConstants.appItemDetails]);
  }

  bool itemAlreadyInList() {
    logger.d("Verifying if item already exists in itemlists");
    bool itemAlreadyInList = false;

    itemlists.forEach((key, iList) {
      for (var item in iList.appMediaItems!) {
        if (item.id == appMediaItem.id) {
          itemAlreadyInList = true;
          appMediaItem.state = item.state;
          itemlistId.value = iList.id;
        }
      }
    });

    logger.d("Item already exists in itemlists: $itemAlreadyInList");
    return itemAlreadyInList;
  }

  Future<void> playPreview() async {

    logger.d("Previewing appMediaItem ${appMediaItem.name}");

    try {
      audioPlayer.onDurationChanged.listen((duration) {
        AppUtilities.logger.i(duration);
        durationMinutes.value = AppUtilities.getDurationInMinutes(duration.inMilliseconds);
      });

      await audioPlayer.play(UrlSource(appMediaItem.url));


      isPlaying.value = true;
    } catch(e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.appItemDetails]);
  }

  Future<void> pausePreview() async {
    try {
      await audioPlayer.pause();
      isPlaying.value = false;
    } catch(e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.appItemDetails]);
  }


  Future<void> stopPreview() async {
    logger.d("Stopping appMediaItem ${appMediaItem.name}");

    try {
      await audioPlayer.stop();
      await audioPlayer.release();
      isPlaying.value = false;
    } catch(e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.appItemDetails]);
  }

}
