import 'package:flutter/cupertino.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/datetime_utilities.dart';
import 'package:neom_commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/band.dart';
import 'package:neom_core/domain/model/item_found_in_list.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:neom_core/domain/use_cases/event_details_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:sint/sint.dart';

import '../../domain/use_cases/app_media_item_details_service.dart';
import '../../utils/constants/itemlist_translation_constants.dart';
import 'app_media_item_controller.dart';


class AppMediaItemDetailsController extends SintController implements AppMediaItemDetailsService {
  
  final userServiceImpl = Sint.find<UserService>();

  AppProfile profile = AppProfile();
  Band band = Band();
  OwnerType itemlistOwner = OwnerType.profile;
  AppMediaItem appMediaItem = AppMediaItem();

  final RxString itemlistId = "".obs;
  final RxString durationMinutes = "".obs;
  final RxInt appItemState = 0.obs;
  final RxMap<String, Itemlist> itemlists = <String, Itemlist>{}.obs;

  final RxBool isLoading = true.obs;
  final RxBool existsInItemlist = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool wasAdded = false.obs;

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
    AppConfig.logger.d("AppMediaItem Details Controller init");

    try {
      profile = userServiceImpl.profile;
      band = userServiceImpl.band;
      itemlistOwner = userServiceImpl.itemlistOwnerType;

      if(itemlistOwner == OwnerType.profile) {
        itemlists.assignAll(profile.itemlists ?? {});
      } else if(itemlistOwner == OwnerType.band) {
        itemlists.assignAll(band.itemlists ?? {});
      }

      List<dynamic> arguments  = Sint.arguments ?? [];

      if(arguments.isNotEmpty) {
        if(Sint.arguments[0] is AppMediaItem) {
          appMediaItem =  arguments.elementAt(0);
          releasedItemId = appMediaItem.id;
        } else if(Sint.arguments[0] is String) {
          releasedItemId = Sint.arguments[0];
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
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    AppConfig.logger.i("AppMediaItem ${appMediaItem.id} Details Controller Ready");

    try {

      if(releasedItemId.isNotEmpty) {
        releasedItem = await AppReleaseItemFirestore().retrieve(releasedItemId);
        if(releasedItem.id.isNotEmpty) {
          isReleaseItem = true;
          appMediaItem = AppMediaItemMapper.fromAppReleaseItem(releasedItem);
          digitalAmount = releasedItem.digitalPrice!.amount;
          physicalAmount = releasedItem.physicalPrice?.amount ?? 0;
          currentCurrency = releasedItem.digitalPrice!.currency;
          if((releasedItem.boughtUsers?.contains(userServiceImpl.user.id) ?? false)
              || (userServiceImpl.user.releaseItemIds?.contains(releasedItem.id) ?? false)
              || (userServiceImpl.user.boughtItems?.contains(releasedItem.id) ?? false)
          ) {
            allowFullAccess = true;
          }
        }
      }

      if(itemlists.isEmpty) {
        Sint.offAllNamed(AppRouteConstants.home);
        AppUtilities.showSnackBar(title: ItemlistTranslationConstants.noItemlistsMsg, message: ItemlistTranslationConstants.noItemlistsMsg2);
      }
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.appItemDetails]);
  }

  @override
  void dispose() {
    super.dispose();
    clear();
    isPlaying.value = false;
  }

  @override
  void clear() {
    appMediaItem = AppMediaItem();
    itemlistId.value = "";
  }

  @override
  void setAppItemState(AppItemState newState){
    AppConfig.logger.d("Setting new appItemState $newState");
    appItemState.value = newState.value;
    update([AppPageIdConstants.appItemDetails]);
  }

  @override
  void setSelectedItemlist(String selectedItemlist){
    AppConfig.logger.d("Setting selectedItemlist $selectedItemlist");
    itemlistId.value  = selectedItemlist;
    existsInItemlist.value = itemAlreadyInList();
    update([AppPageIdConstants.appItemDetails]);
  }

  @override
  void getAppItemDetails(String itemId) async {
    AppConfig.logger.d("");

    try {
      appMediaItem = await AppMediaItemFirestore().retrieve(itemId);
      durationMinutes.value = DateTimeUtilities.getDurationInMinutes(appMediaItem.duration);
    } catch (e) {
      AppConfig.logger.d(e.toString());
    }
    update([AppPageIdConstants.appItemDetails]);
  }

  @override
  Future<void> addItemlistItem(BuildContext context, {int fanItemState = 0}) async {

    isLoading.value = true;
    update([AppPageIdConstants.appItemDetails]);

    AppConfig.logger.i("AppMediaItem ${appMediaItem.name} would be added as $appItemState for Itemlist $itemlistId");

    if(fanItemState > 0) appItemState.value = fanItemState;
    if(itemlistId.isEmpty) itemlistId.value = itemlists.values.first.id;

    isPlaying.value = false;

    AppMediaItemController appMediaItemController;

    if(Sint.isRegistered<AppMediaItemController>()) {
      appMediaItemController = Sint.find<AppMediaItemController>();
    } else {
      appMediaItemController = Sint.put(AppMediaItemController());
    }

    try {
      AppMediaItemFirestore().existsOrInsert(appMediaItem);
      if(!existsInItemlist.value) {
        appMediaItem.state = appItemState.value;
        if(await appMediaItemController.addItemToItemlist(appMediaItem, itemlistId.value)){
          AppConfig.logger.d("Setting existsInItemlist and wasAdded true");
          existsInItemlist.value = true;
          wasAdded.value = true;
        }
      }


    } catch (e) {
      AppConfig.logger.d(e.toString());
    }

    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.itemlist,
      AppPageIdConstants.appItemDetails, AppPageIdConstants.profile]);

    try {
      if(itemlistOwner == OwnerType.profile) {
        EventDetailsService? eventDetailsService = Sint.find<EventDetailsService?>();
        if(eventDetailsService != null) {
          eventDetailsService.addToMatchedItems(appMediaItem.id, CoreUtilities.getItemState(appMediaItem.state));
          Navigator.of(context).popUntil(ModalRoute.withName(AppRouteConstants.eventDetails));
        } else {
          Sint.offAllNamed(AppRouteConstants.home);
          Sint.toNamed(AppRouteConstants.listItems);
        }
      } else {
        Sint.offAllNamed(AppRouteConstants.home);
        Sint.toNamed(AppRouteConstants.bandsRoom);
        Sint.toNamed(AppRouteConstants.bandLists);
      }
    } catch (e) {
      Sint.offAllNamed(AppRouteConstants.home);
      Sint.toNamed(AppRouteConstants.listItems);
    }

  }

  @override
  Future<void> removeItem() async {
    AppConfig.logger.d("removing Item ${appMediaItem.toString()} from itemlist");

    isPlaying.value = false;

    AppMediaItemController appMediaItemController;
    try {
      appMediaItemController = Sint.find<AppMediaItemController>();
    } catch (e) {
      appMediaItemController = Sint.put(AppMediaItemController());
    }


    try {
      if(await appMediaItemController.removeItemFromList(appMediaItem.id)) {
        AppConfig.logger.d("YEAH");
      } else {
        AppConfig.logger.d("Item not removed from Itemlist");
      }
    } catch (e) {
      AppConfig.logger.d(e.toString());
    }

    Sint.back();
    update([AppPageIdConstants.appItemDetails]);
  }

  @override
  bool itemAlreadyInList() {
    AppConfig.logger.d("Verifying if item already exists in itemlists");
    bool itemAlreadyInList = false;

    ItemFoundInList? itemFoundInList = AppUtilities.getItemFoundInList(itemlists.values.toList(), appMediaItem.id);

    if(itemFoundInList != null) {
      itemAlreadyInList = true;
      itemlistId.value = itemFoundInList.listId;
      appMediaItem.state = itemFoundInList.itemState;
      AppConfig.logger.d("Item already exists in itemlist: ${itemlistId.value} with state: ${appMediaItem.state}");
    }

    AppConfig.logger.d("Item already exists in itemlists: $itemAlreadyInList");
    return itemAlreadyInList;
  }

  Future<void> playPreview() async {

    AppConfig.logger.d("Previewing appMediaItem ${appMediaItem.name}");

    try {
      await Sint.find<AudioPlayerInvokerService>().updateNowPlaying(items: [appMediaItem], index: 1);
      isPlaying.value = true;
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.appItemDetails]);
  }

  Future<void> pausePreview() async {
    try {
      ///DEPRECATED - INTEGRATE WITH NEOM AUDIO PLAYER SERVICE AS CONTRACT
      Sint.find<AudioPlayerInvokerService>().pause();
      isPlaying.value = false;
    } catch(e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.appItemDetails]);
  }


}
