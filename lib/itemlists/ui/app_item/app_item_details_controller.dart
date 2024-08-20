//DEPRECATED
// // ignore_for_file: use_build_context_synchronously
//
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';
// import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
//
// import 'package:neom_commons/core/domain/model/app_release_item.dart';
// import 'package:neom_commons/neom_commons.dart';
// import 'package:neom_events/events/ui/event_details_controller.dart';
// import '../../data/firestore/app_item_firestore.dart';
// import 'app_item_controller.dart';
//
//
// class AppItemDetailsController extends GetxController {
//
//   var logger = AppUtilities.logger;
//   final userController = Get.find<UserController>();
//
//   AppProfile profile = AppProfile();
//   Band band = Band();
//   OwnerType itemlistOwner = OwnerType.profile;
//   AppItem appItem = AppItem();
//
//   final RxString _itemlistId = "".obs;
//   String get itemlistId => _itemlistId.value;
//   set itemlistId(String itemlistId) => _itemlistId.value = itemlistId;
//
//   final RxString _durationMinutes = "".obs;
//   String get durationMinutes => _durationMinutes.value;
//   set durationMinutes(String durationMinutes) => _durationMinutes.value = durationMinutes;
//
//   final RxInt _appItemState = 0.obs;
//   int get appItemState => _appItemState.value;
//   set appItemState(int appItemState) => _appItemState.value = appItemState;
//
//   final RxBool _isPlaying = false.obs;
//   bool get isPlaying.value => _isPlaying.value;
//   set isPlaying.value(bool isPlaying.value) => _isPlaying.value = isPlaying.value;
//
//   final RxBool _wasAdded = false.obs;
//   bool get wasAdded => _wasAdded.value;
//   set wasAdded(bool wasAdded) => _wasAdded.value = wasAdded;
//
//   final RxBool _existsInItemlist = false.obs;
//   bool get existsInItemlist => _existsInItemlist.value;
//   set existsInItemlist(bool existsInItemlist) => _existsInItemlist.value = existsInItemlist;
//
//   final RxMap<String, Itemlist> _itemlists = <String, Itemlist>{}.obs;
//   Map<String, Itemlist> get itemlists => _itemlists;
//   set itemlists(Map<String, Itemlist> itemlists) => _itemlists.value = itemlists;
//
//   final RxBool _isLoading = true.obs;
//   bool get isLoading.value => _isLoading.value;
//   set isLoading.value(bool isLoading.value) => _isLoading.value = isLoading.value;
//
//   final RxBool _isButtonDisabled = false.obs;
//   bool get isButtonDisabled.value => _isButtonDisabled.value;
//   set isButtonDisabled.value(bool isButtonDisabled.value) => _isButtonDisabled.value = isButtonDisabled.value;
//
//   final AudioPlayer audioPlayer = AudioPlayer(playerId: AppInUse.gigmeout.value);
//
//   AppReleaseItem releasedItem = AppReleaseItem();
//   String releasedItemId = "";
//   bool isReleaseItem = false;
//   bool allowFullAccess = true;
//
//   AppCurrency currentCurrency = AppCurrency.mxn;
//   double digitalAmount = 0;
//   double physicalAmount = 0;
//
//   @override
//   void onInit() async {
//     super.onInit();
//     logger.d("AppItem Details Controller init");
//
//     try {
//       profile = userController.profile;
//       band = userController.band;
//       itemlistOwner = userController.itemlistOwner;
//
//       audioPlayer.setReleaseMode(ReleaseMode.stop);
//       audioPlayer.stop();
//       audioPlayer.release();
//       if(itemlistOwner == OwnerType.profile) {
//         itemlists.assignAll(profile.itemlists ?? {});
//       } else if(itemlistOwner == OwnerType.band) {
//         itemlists.assignAll(band.itemlists ?? {});
//       }
//
//       List<dynamic> arguments  = Get.arguments ?? [];
//
//       if(arguments.isNotEmpty) {
//         if(Get.arguments[0] is AppItem) {
//           appItem =  arguments.elementAt(0);
//           releasedItemId = appItem.id;
//         } else if(Get.arguments[0] is String) {
//           releasedItemId = Get.arguments[0];
//         }
//
//         existsInItemlist = itemAlreadyInList();
//
//         if (arguments.length > 1) { //to save in previously selected itemlist
//           itemlistId =  arguments.elementAt(1);
//         }
//       }
//
//       if(itemlists.isNotEmpty && itemlists.isNotEmpty && itemlistId.isEmpty) {
//         itemlistId = itemlists.values.first.id;
//       }
//
//     } catch (e) {
//       logger.e(e.toString());
//     }
//
//   }
//
//
//   @override
//   void onReady() async {
//     super.onReady();
//     logger.i("AppItem ${appItem.id} Details Controller Ready");
//
//     try {
//
//       if(releasedItemId.isNotEmpty) {
//         releasedItem = await AppReleaseItemFirestore().retrieve(releasedItemId);
//         if(releasedItem.id.isNotEmpty) {
//           isReleaseItem = true;
//           appItem = AppItem.fromReleaseItem(releasedItem);
//           digitalAmount = releasedItem.digitalPrice!.amount;
//           physicalAmount = releasedItem.physicalPrice?.amount ?? 0;
//           currentCurrency = releasedItem.digitalPrice!.currency;
//           if((releasedItem.boughtUsers?.contains(userController.user!.id) ?? false)
//               || (userController.user!.releaseItemIds?.contains(releasedItem.id) ?? false)
//               || (userController.user!.boughtItems?.contains(releasedItem.id) ?? false)
//           ) {
//             allowFullAccess = true;
//           }
//         }
//       }
//
//       if(itemlists.isEmpty) {
//         Get.offAllNamed(AppRouteConstants.home);
//         AppUtilities.showSnackBar(AppTranslationConstants.noItemlistsMsg, AppTranslationConstants.noItemlistsMsg2);
//       }
//     } catch(e) {
//       logger.e(e.toString());
//     }
//
//     isLoading.value = false;
//     update([AppPageIdConstants.appItemDetails]);
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     clear();
//     audioPlayer.stop();
//     audioPlayer.release();
//     isPlaying.value = false;
//   }
//
//   void clear() {
//     appItem = AppItem();
//     itemlistId = "";
//   }
//
//   void setAppItemState(AppItemState newState){
//     logger.d("Setting new appItemState $newState");
//     appItemState = newState.value;
//     update([AppPageIdConstants.appItemDetails]);
//   }
//
//   void setSelectedItemlist(String selectedItemlist){
//     logger.d("Setting selectedItemlist $selectedItemlist");
//     itemlistId  = selectedItemlist;
//     existsInItemlist = itemAlreadyInList();
//     update([AppPageIdConstants.appItemDetails]);
//   }
//
//   void getAppItemDetails(String itemId) async {
//     logger.d("");
//
//     try {
//       appItem = await AppItemFirestore().retrieve(itemId);
//       durationMinutes = AppUtilities.getDurationInMinutes(appItem.durationMs);
//     } catch (e) {
//       logger.d(e.toString());
//     }
//     update([AppPageIdConstants.appItemDetails]);
//   }
//
//
//   Future<void> addItemlistItem(BuildContext context, {int fanItemState = 0}) async {
//
//     if(!isButtonDisabled.value) {
//
//       isButtonDisabled.value = true;
//       isLoading.value = true;
//       update([AppPageIdConstants.appItemDetails]);
//
//       logger.i("AppItem ${appItem.name} would be added as $appItemState for Itemlist $itemlistId");
//
//       if(fanItemState > 0) appItemState = fanItemState;
//       if(itemlistId.isEmpty) itemlistId = itemlists.values.first.id;
//
//       await audioPlayer.stop();
//       isPlaying.value = false;
//
//       AppItemController appItemController;
//
//       try {
//         appItemController = Get.find<AppItemController>();
//       } catch (e) {
//         appItemController = Get.put(AppItemController());
//       }
//
//       try {
//         if(!await AppItemFirestore().exists(appItem.id)) {
//           await AppItemFirestore().insert(appItem);
//         }
//
//         if(!existsInItemlist) {
//           appItem.state = appItemState;
//
//           if(await appItemController.addItemToItemlist(appItem, itemlistId)){
//             logger.d("Setting existsInItemlist and wasAdded true");
//             existsInItemlist = true;
//             wasAdded = true;
//           }
//         }
//
//
//       } catch (e) {
//         logger.d(e.toString());
//       }
//
//       update([AppPageIdConstants.itemlistItem,
//         AppPageIdConstants.itemlist,
//         AppPageIdConstants.appItemDetails,
//         AppPageIdConstants.profile]);
//
//       try {
//         if(itemlistOwner == OwnerType.profile) {
//           if(Get.find<EventDetailsController>().initialized) {
//             Get.find<EventDetailsController>().addToMatchedItems(appItem);
//             Navigator.of(context).popUntil(ModalRoute.withName(AppRouteConstants.eventDetails));
//           } else {
//             Get.offAllNamed(AppRouteConstants.home);
//             Get.toNamed(AppRouteConstants.listItems);
//           }
//         } else {
//           Get.offAllNamed(AppRouteConstants.home);
//           Get.toNamed(AppRouteConstants.bandsRoom);
//           Get.toNamed(AppRouteConstants.bandLists);
//         }
//
//       } catch (e) {
//         Get.offAllNamed(AppRouteConstants.home);
//         Get.toNamed(AppRouteConstants.listItems);
//       }
//     }
//
//   }
//
//   Future<void> removeItem() async {
//     logger.d("removing Item ${appItem.toString()} from itemlist");
//
//     await audioPlayer.stop();
//     isPlaying.value = false;
//
//     AppItemController appItemController;
//     try {
//       appItemController = Get.find<AppItemController>();
//     } catch (e) {
//       appItemController = Get.put(AppItemController());
//     }
//
//
//     try {
//       if(await appItemController.removeItemFromList(appItem)) {
//         logger.d("YEAH");
//       } else {
//         logger.d("Item not removed from Itemlist");
//       }
//     } catch (e) {
//       logger.d(e.toString());
//     }
//
//     Get.back();
//     update([AppPageIdConstants.appItemDetails]);
//   }
//
//
//   //TODO Push Notification (GigPRofile added a item)
//   bool itemAlreadyInList() {
//     logger.d("Verifying if item already exists in itemlists");
//     bool itemAlreadyInList = false;
//
//     itemlists.forEach((key, iList) {
//       for (var item in iList.appItems!) {
//         if (item.id == appItem.id) {
//           itemAlreadyInList = true;
//           appItem.state = item.state;
//           _itemlistId.value = iList.id;
//         }
//       }
//     });
//
//     logger.d("Item already exists in itemlists: $itemAlreadyInList");
//     return itemAlreadyInList;
//   }
//
//   Future<void> playPreview() async {
//
//     logger.d("Previewing appItem ${appItem.name}");
//
//     try {
//       audioPlayer.onDurationChanged.listen((duration) {
//         AppUtilities.logger.i(duration);
//         durationMinutes = AppUtilities.getDurationInMinutes(duration.inMilliseconds);
//       });
//
//       await audioPlayer.play(UrlSource(appItem.previewUrl));
//
//
//       isPlaying.value = true;
//     } catch(e) {
//       logger.e(e.toString());
//     }
//
//     update([AppPageIdConstants.appItemDetails]);
//   }
//
//   Future<void> pausePreview() async {
//     try {
//       await audioPlayer.pause();
//       isPlaying.value = false;
//     } catch(e) {
//       logger.e(e.toString());
//     }
//
//     update([AppPageIdConstants.appItemDetails]);
//   }
//
//
//   Future<void> stopPreview() async {
//     logger.d("Stopping appItem ${appItem.name}");
//
//     try {
//       await audioPlayer.stop();
//       await audioPlayer.release();
//       isPlaying.value = false;
//     } catch(e) {
//       logger.e(e.toString());
//     }
//
//     update([AppPageIdConstants.appItemDetails]);
//   }
//
// }
