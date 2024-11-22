import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/auth/ui/login/login_controller.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/firestore/user_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/model/band.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/domain/use_cases/itemlist_service.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/itemlist_type.dart';
import 'package:neom_commons/core/utils/enums/owner_type.dart';
import 'package:spotify/spotify.dart' as spotify;

import '../data/api_services/spotify/spotify_api_calls.dart';
import 'app_media_item/app_media_item_controller.dart';
import 'sync/spotify_playlist_page.dart';

class ItemlistController extends GetxController implements ItemlistService {

  final userController = Get.find<UserController>();

  Itemlist currentItemlist = Itemlist();

  TextEditingController newItemlistNameController = TextEditingController();
  TextEditingController newItemlistDescController = TextEditingController();

  final RxMap<String, Itemlist> itemlists = <String, Itemlist>{}.obs;
  final RxList<Itemlist> addedItemlists = <Itemlist>[].obs;
  final RxMap<String, Itemlist> spotifyItemlists = <String, Itemlist>{}.obs;
  final RxList<spotify.Playlist> spotifyPlaylists = <spotify.Playlist>[].obs;
  final RxList<spotify.PlaylistSimple> spotifyPlaylistSimples = <spotify.PlaylistSimple>[].obs;

  ///DEPRECATED
  // Itemlist _favItemlist = Itemlist();
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

  bool outOfSync = false;
  bool spotifyAvailable = true;

  RxString itemName = "".obs;
  RxInt itemNumber = 0.obs;
  int totalItemsToSync = 0;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t("onInit Itemlist Controller");

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

      AppUtilities.logger.t('Itemlists being loaded from ${ownerType.name}');
      if(ownerType == OwnerType.profile) {
        itemlists.value = Map.from(profile.itemlists ?? {});
      } else if(ownerType == OwnerType.band){
        itemlists.value = Map.from(band.itemlists ?? {});
      }

      if(itemlists.isEmpty) {
        itemlists.value = await ItemlistFirestore().getByOwnerId(ownerId, ownerType: ownerType,
            itemlistType: AppFlavour.appInUse == AppInUse.e ? ItemlistType.readlist : null
        );
      } else {
        if(itemlistType == ItemlistType.readlist) {
          itemlists.removeWhere((id, itemlist) {
            return AppFlavour.appInUse == AppInUse.e &&
                (itemlist.type != ItemlistType.readlist
                    && itemlist.type != ItemlistType.publication);
          });
        } else {
          itemlists.removeWhere((id,list) => list.type == ItemlistType.readlist || list.type == ItemlistType.publication);
        }


      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    try {
      if(AppFlavour.appInUse == AppInUse.g && !Platform.isIOS) {
        getSpotifyToken();
        if (userController.user.spotifyToken.isNotEmpty
            && userController.profile.lastSpotifySync < DateTime
                .now().subtract(const Duration(days: 30))
                .millisecondsSinceEpoch
        ) {
          AppUtilities.logger.d("Spotify Last Sync was more than 30 days");
          outOfSync = true;
        } else {
          AppUtilities.logger.i("Spotify Last Sync in scope");
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.spotifySynchronization.tr,
        message: e.toString(),
      );
      spotifyAvailable = false;
    }
    isLoading.value = false;
    update([AppPageIdConstants.itemlist]);
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
  Future<void> createItemlist() async {
    AppUtilities.logger.d("Start ${newItemlistNameController.text} and ${newItemlistDescController.text}");

    try {
      errorMsg.value = '';
      if((isPublicNewItemlist.value && newItemlistNameController.text.isNotEmpty && newItemlistDescController.text.isNotEmpty)
          || (!isPublicNewItemlist.value && newItemlistNameController.text.isNotEmpty)) {
        Itemlist newItemlist = Itemlist(
          name: newItemlistNameController.text,
          description: newItemlistDescController.text,
          ownerId: ownerId,
          ownerName: ownerName,
          ownerType: ownerType,
          type: itemlistType,
          public: isPublicNewItemlist.value,
        );

        String newItemlistId = "";

        if (profile.position?.latitude != 0.0) {
          newItemlist.position = profile.position!;
        }

        newItemlistId = await ItemlistFirestore().insert(newItemlist);

        ///DEPRECATED
        // if(isPublicNewItemlist.value) {
        //   AppUtilities.logger.i("Inserting Public Itemlist to Public collection");
        //   newItemlistId = await ItemlistFirestore().insert(newItemlist);
        // } else {
        //   AppUtilities.logger.i("Inserting Private Itemlist to collection for profileId ${newItemlist.ownerId}");
        //   newItemlistId = await ItemlistFirestore().insert(newItemlist);
        // }

        AppUtilities.logger.i("Empty Itemlist created successfully for profile ${newItemlist.ownerId}");
        newItemlist.id = newItemlistId;

        if(newItemlistId.isNotEmpty){
          itemlists[newItemlistId] = newItemlist;
          if(userController.profile.itemlists == null) {
            userController.profile.itemlists = {};
            userController.profile.itemlists![newItemlistId] = newItemlist;
          } else {
            userController.profile.itemlists![newItemlistId] = newItemlist;
          }

          AppUtilities.logger.t("Itemlists $itemlists");

          clearNewItemlist();
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.itemlistPrefs.tr,
              message: AppTranslationConstants.itemlistCreated.tr
          );
        } else {
          AppUtilities.logger.d("Something happens trying to insert itemlist");
        }
      } else {
        AppUtilities.logger.d(MessageTranslationConstants.pleaseFillItemlistInfo.tr);
        errorMsg.value = newItemlistNameController.text.isEmpty ? MessageTranslationConstants.pleaseAddName
            : MessageTranslationConstants.pleaseAddDescription;

        AppUtilities.showSnackBar(
          title: MessageTranslationConstants.addNewItemlist.tr,
          message: MessageTranslationConstants.pleaseFillItemlistInfo.tr,
        );
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.itemlist]);
  }

  ///DEPRECATED Verify if in use
  // Future<void> searchItemlist() async {
  //
  //   AppUtilities.logger.d("Start ${newItemlistNameController.text} and ${newItemlistDescController.text}");
  //
  //   Get.back();
  //
  //   try {
  //     if(newItemlistNameController.text.isNotEmpty) {
  //       await Get.toNamed(AppRouteConstants.playlistSearch,
  //           arguments: [SpotifySearchType.playlist, newItemlistNameController.text]
  //       );
  //     } else {
  //       AppUtilities.showSnackBar(
  //         title: MessageTranslationConstants.searchPlaylist.tr,
  //         message: MessageTranslationConstants.missingPlaylistName.tr,
  //       );
  //     }
  //   } catch (e) {
  //     AppUtilities.logger.e(e.toString());
  //   }
  //
  //   update([AppPageIdConstants.itemlist]);
  // }


  @override
  Future<void> deleteItemlist(Itemlist itemlist) async {
    AppUtilities.logger.d("Removing for $itemlist");

    try {
      isLoading.value = true;
      update([AppPageIdConstants.itemlist]);

      if(await ItemlistFirestore().delete(itemlist.id)) {
        AppUtilities.logger.d("Itemlist ${itemlist.id} removed");

        if((itemlist.appMediaItems?.isNotEmpty ?? false) && ownerType == OwnerType.profile) {
          List<String> appMediaItemsIds = itemlist.appMediaItems!.map((e) => e.id).toList();

          if(await ProfileFirestore().removeFavoriteItems(profile.id, appMediaItemsIds)) {
            for (var itemId in appMediaItemsIds) {
              if (userController.profile.favoriteItems != null && userController.profile.favoriteItems!.isNotEmpty) {
                AppUtilities.logger.d("Removing item from global state items for profile from userController");
                userController.profile.favoriteItems!.remove(itemId);
              }
            }
          }

          ///DEPRECATED
          // for(var appItem in itemlist.appMediaItems ?? []) {
          //   if(await ProfileFirestore().removeFavoriteItem(profile.id, appItem.id)) {
          //     if (userController.profile.favoriteItems != null &&
          //         userController.profile.favoriteItems!.isNotEmpty) {
          //       AppUtilities.logger.d("Removing item from global state items for profile from userController");
          //       userController.profile.favoriteItems!.remove(appItem.id);
          //     }
          //   }
          // }
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
        AppUtilities.logger.e("Something happens trying to remove itemlist");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.itemlist]);
  }


  ///DEPRECATED
  // @override
  // Future<void> setAsFavorite(Itemlist itemlist) async {
  //   AppUtilities.logger.d("Making favorite for $itemlist");
  //
  //   try {
  //     if(await ItemlistFirestore().setAsFavorite(profile.id, itemlist)){
  //       itemlist.isFav = true;
  //       itemlists[itemlist.id] = itemlist;
  //       AppUtilities.logger.i("Itemlist ${itemlist.id} set as favorite");
  //       if(await ItemlistFirestore().unsetOfFavorite(profile.id, _favItemlist)) {
  //         AppUtilities.logger.i("Itemlist ${profile.id} unset from favorite");
  //         _favItemlist.isFav = false;
  //         itemlists[_favItemlist.id] = _favItemlist;
  //       }
  //       _favItemlist = itemlist;
  //     } else {
  //       AppUtilities.logger.e("Something happens trying to remove itemlist");
  //     }
  //   } catch (e) {
  //     AppUtilities.logger.e(e.toString());
  //   }
  //
  //   Get.back();
  //   update([AppPageIdConstants.itemlist]);
  // }


  @override
  Future<void> updateItemlist(String itemlistId, Itemlist itemlist) async {

    AppUtilities.logger.d("Updating to $itemlist");

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
          AppUtilities.logger.d("Itemlist $itemlistId updated");
          itemlists[itemlist.id] = itemlist;
          clearNewItemlist();
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.itemlistPrefs.tr,
              message: AppTranslationConstants.itemlistUpdated.tr
          );
        } else {
          AppUtilities.logger.i("Something happens trying to update itemlist");
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
      AppUtilities.logger.e(e.toString());
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
        AppUtilities.logger.w(e.toString());
        AppUtilities.logger.i("Controller is not active");
      }

      await Get.toNamed(AppRouteConstants.listItems, arguments: [itemlist]);
      update([AppPageIdConstants.itemlist, AppPageIdConstants.itemlistItem]);
    }

  }

  @override
  Future<bool> synchronizeItemlist(Itemlist itemlist) async {
    AppUtilities.logger.i("Synchronizing Itemlist ${itemlist.name}");
    isButtonDisabled.value = true;
    isLoading.value = true;
    bool wasSync = false;
    try {

      String itemlistId = "";
      Itemlist? existingItemlist;
      List<Itemlist>? existingItemlists;
      if(ownerType == OwnerType.profile) {
        existingItemlists = userController.profile.itemlists?.values
            .where((element) => element.name == itemlist.name).toList();
      } else {
        existingItemlists = userController.band.itemlists?.values
            .where((element) => element.name == itemlist.name).toList();
      }

      if(existingItemlists?.isNotEmpty ?? false) {
        existingItemlist = existingItemlists?.first;
      }

      if(existingItemlist?.id.isNotEmpty ?? false) {

        List<AppMediaItem> currentItems = [];
        itemlistId = existingItemlist?.id ?? "";

        itemlist.appMediaItems?.forEach((appItem) {
          List<AppMediaItem>? itemlistItems = existingItemlist?.appMediaItems?.where((element) => element.id == appItem.id).toList();
          if(itemlistItems?.isNotEmpty ?? false) {
            currentItems.add(appItem);
          }
        });

        for (AppMediaItem currentItem in currentItems) {
          itemlist.appMediaItems?.removeWhere((appItem) => appItem.id == currentItem.id);
          AppUtilities.logger.d("Removing item ${currentItem.name} from being synchronized");
        }

        totalItemsToSync -= currentItems.length;
      }

      if(itemlistId.isEmpty) {
        itemlist.ownerId = ownerId;
        itemlist.ownerType = ownerType;
        itemlist.ownerName = ownerName;

        itemlistId = await ItemlistFirestore().insert(itemlist);
        AppUtilities.logger.i("Itemlist inserted with id $itemlistId");
      }

      if(itemlistId.isNotEmpty && (itemlist.appMediaItems?.isNotEmpty ?? false)) {
        itemlist.id = itemlistId;

        if(ownerType == OwnerType.profile) {
          userController.profile.itemlists![itemlist.id] = itemlist;
          currentItemlist = itemlist;

          List<String> appMediaItemsIds = itemlist.appMediaItems!.map((e) => e.id).toList();
          if(await ProfileFirestore().addFavoriteItems(profile.id, appMediaItemsIds)) {

          }
          for (AppMediaItem appItem in itemlist.appMediaItems ?? []) {
            itemName.value = appItem.name;
            itemNumber++;
            update([AppPageIdConstants.itemlist, AppPageIdConstants.playlistSong]);
            if (userController.profile.itemlists!.isNotEmpty) {
              AppUtilities.logger.d("Adding item to global itemlist from userController");
              userController.profile.favoriteItems!.add(appItem.id);
            }
            AppMediaItemFirestore().existsOrInsert(appItem);
          }
        } else if(ownerType == OwnerType.band) {
          userController.band.itemlists![itemlist.id] = itemlist;
          for (var appItem in itemlist.appMediaItems ?? []) {
            AppMediaItemFirestore().existsOrInsert(appItem);
            //TODO Add sync for band itemlist
          }
        }
        AppUtilities.logger.d("Items added successfully from Itemlist");
        wasSync = true;
      } else {
        Get.snackbar(
            MessageTranslationConstants.spotifySynchronization.tr,
            "Playlist ${itemlist.name} ${MessageTranslationConstants.upToDate.tr}",
            snackPosition: SnackPosition.bottom,
            duration: const Duration(seconds: 1)
        );
      }
      isButtonDisabled.value = false;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update();
    return wasSync;
  }

  Future<void> gotoSuggestedItem() async {
    AppReleaseItem suggestedItem = AppReleaseItem(
      previewUrl: Get.find<LoginController>().appInfo.value.suggestedUrl,
      duration: 107,
    );

    Get.toNamed(AppRouteConstants.pdfViewer, arguments: [suggestedItem, true, true]);
  }

  @override
  Future<void> getSpotifyToken() async {
    AppUtilities.logger.d("Getting SpotifyToken");
    AppUtilities.logger.w("DEPRECATED - spotify_sdk was working for android and not allowing to build on ios");

    String spotifyToken = await SpotifyApiCalls.getSpotifyToken();
    // String spotifyToken = '';

    if(spotifyToken.isNotEmpty) {
      AppUtilities.logger.t("Spotify access token is: $spotifyToken");
      userController.user.spotifyToken = spotifyToken;
      await UserFirestore().updateSpotifyToken(userController.user.id, spotifyToken);
    }
    update([AppPageIdConstants.itemlist]);
  }

  @override
  Future<void> synchronizeSpotifyPlaylists() async {
    AppUtilities.logger.i("Getting Spotify Information with token: ${userController.user.spotifyToken}");

    isLoading.value = true;
    update([AppPageIdConstants.itemlist]);

    spotify.User spotifyUser = await SpotifyApiCalls.getUserProfile(spotifyToken: userController.user.spotifyToken);

    try {
      if(spotifyUser.id?.isNotEmpty ?? false) {
        spotifyPlaylistSimples.value =  await SpotifyApiCalls.getUserPlaylistSimples(spotifyToken: userController.user.spotifyToken, userId: spotifyUser.id!);

        for (var playlist in spotifyPlaylistSimples.value) {
          if(playlist.id?.isNotEmpty ?? false) {
            spotifyItemlists[playlist.id!] = Itemlist.mapPlaylistSimpleToItemlist(playlist);
          }
        }

        Get.to(() => const SpotifyPlaylistsPage(), transition: Transition.rightToLeft);
        ///DEPRECATED
        // Get.toNamed(AppRouteConstants.spotifyPlaylists);
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.itemlist]);
  }

  @override
  void handlePlaylistList(Itemlist spotifyItemlist) {

    try {
      if (addedItemlists.contains(spotifyItemlist)) {
        AppUtilities.logger.d("Removing gigList ${spotifyItemlist.name}");
        addedItemlists.remove(spotifyItemlist);
        totalItemsToSync -= spotifyPlaylistSimples.value.where((element) => element.id == spotifyItemlist.id).first.tracksLink?.total ?? 0;
      } else {
        AppUtilities.logger.d("Adding giglist with name ${spotifyItemlist.name}");
        addedItemlists.add(spotifyItemlist);
        totalItemsToSync += spotifyPlaylistSimples.value.where((element) => element.id == spotifyItemlist.id).first.tracksLink?.total ?? 0;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.playlistSong]);
  }

  ///DEPRECATED TODO Verify if needed
  // void loadSongsForPlaylist(spotify.PlaylistSimple playlist) {
  //   itemlists.forEach((playlistId, giglist) async {
  //     giglist.appMediaItems = await SpotifySearch().loadSongsFromPlaylist(playlistId);
  //     AppUtilities.logger.i("Adding ${giglist.appMediaItems?.length} song to Giglist ${giglist.name}");
  //     itemlists[playlistId] = giglist;
  //   });
  // }

  @override
  Future<void> gotoPlaylistSongs(Itemlist itemlist) async {

    spotify.Playlist spotifyPlaylist = spotify.Playlist();

    try {
      spotify.PlaylistSimple playlistSimple = spotifyPlaylistSimples.value.where((element) => element.href == itemlist.href).first;

      if(playlistSimple.id?.isNotEmpty ?? false) {
        spotifyPlaylist = await SpotifyApiCalls.getPlaylist(spotifyToken: userController.user.spotifyToken, playlistId: playlistSimple.id!);
      }

      if(spotifyPlaylist.href?.isNotEmpty ?? false) {
        itemlist.appMediaItems = AppMediaItem.mapTracksToSongs(spotifyPlaylist.tracks!);
        AppUtilities.logger.d("${itemlist.appMediaItems?.length ?? 0} songs were mapped from ${spotifyPlaylist.name}");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    await Get.toNamed(AppRouteConstants.listItems, arguments: [itemlist, true]);
    update([AppPageIdConstants.itemlist, AppPageIdConstants.itemlistItem]);

  }

  @override
  Future<void> synchronizeItemlists() async {
    AppUtilities.logger.i("Synchronizing ${addedItemlists.length} Giglists from Spotify Playlists");

    Map<Itemlist, bool> wereSynchronized = {};
    isLoading.value = true;
    isButtonDisabled.value = true;
    update([AppPageIdConstants.itemlist]);

    try {
      spotify.Playlist playlistToSync = spotify.Playlist();
      for (var addedItemlist in addedItemlists) {
        spotify.PlaylistSimple playlistSimple = spotifyPlaylistSimples.value.where((element) => element.href == addedItemlist.href).first;

        if(playlistSimple.id?.isNotEmpty ?? false) {
          playlistToSync = await SpotifyApiCalls.getPlaylist(spotifyToken: userController.user.spotifyToken, playlistId: playlistSimple.id!);
        }

        if(playlistToSync.href?.isNotEmpty ?? false) {
          addedItemlist.appMediaItems = AppMediaItem.mapTracksToSongs(playlistToSync.tracks!);
          AppUtilities.logger.i("${addedItemlist.appMediaItems?.length ?? 0} songs were mapped from ${playlistToSync.name}");
          wereSynchronized[addedItemlist] = await synchronizeItemlist(addedItemlist);
        }

      }

      if(wereSynchronized.values.firstWhere((element) => true)) {
        ProfileFirestore().updateLastSpotifySync(userController.profile.id);
        Get.toNamed(AppRouteConstants.finishingSpotifySync, arguments: [AppRouteConstants.finishingSpotifySync]);
      } else {
        AppUtilities.logger.i("No giglist was updated. Each one is up to date");
      }
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }


    wereSynchronized.forEach((giglist, wasSync) {
      if(!wasSync) {
        AppUtilities.logger.d("Removing added Giglist ${giglist.name} as it's up to date");
        addedItemlists.remove(giglist);
      }
    });

    isLoading.value = false;
    isButtonDisabled.value = false;
    update();
  }

  @override
  Future<void> setPrivacyOption() async {
    AppUtilities.logger.t('setPrivacyOption for Playlist');
    isPublicNewItemlist.value = !isPublicNewItemlist.value;
    AppUtilities.logger.d("New Itemlist would be ${isPublicNewItemlist.value ? 'Public':'Private'}");
    update([AppPageIdConstants.itemlist, AppPageIdConstants.itemlistItem]);
  }

}
