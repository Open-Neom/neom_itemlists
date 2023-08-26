import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';

import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/firestore/user_firestore.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/domain/use_cases/itemlist_service.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/itemlist_owner.dart';
import 'package:neom_commons/core/utils/enums/spotify_search_type.dart';
import 'package:neom_itemlists/itemlists/data/api_services/spotify/spotify_api_calls.dart';
import 'package:neom_itemlists/itemlists/data/api_services/spotify/spotify_search.dart';
import 'package:neom_itemlists/itemlists/data/firestore/app_media_item_firestore.dart';
import 'package:neom_itemlists/itemlists/ui/app_media_item/app_media_item_controller.dart';
import 'package:spotify/spotify.dart' as spotify;

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

  final RxList<spotify.Playlist> _spotifyPlaylists = <spotify.Playlist>[].obs;
  List<spotify.Playlist> get spotifyPlaylists => _spotifyPlaylists;
  set spotifyPlaylists(List<spotify.Playlist> spotifyPlaylists) => _spotifyPlaylists.value = spotifyPlaylists;

  final RxList<spotify.PlaylistSimple> _spotifyPlaylistSimples = <spotify.PlaylistSimple>[].obs;
  List<spotify.PlaylistSimple> get spotifyPlaylistSimples => _spotifyPlaylistSimples;
  set spotifyPlaylistSimples(List<spotify.PlaylistSimple> spotifyPlaylistSimples) => _spotifyPlaylistSimples.value = spotifyPlaylistSimples;

  final RxList<Itemlist> _addedItemlists = <Itemlist>[].obs;
  List<Itemlist> get addedItemlists => _addedItemlists;
  set addedItemlists(List<Itemlist> addedItemlists) => _addedItemlists.value = addedItemlists;

  ///DEPRECATE
  // Itemlist _favItemlist = Itemlist();
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

  final RxBool _isPublicNewItemlist = true.obs;
  bool get isPublicNewItemlist => _isPublicNewItemlist.value;
  set isPublicNewItemlist(bool isPublicNewItemlist) => _isPublicNewItemlist.value = isPublicNewItemlist;

  final RxString _errorMsg = "".obs;
  String get errorMsg => _errorMsg.value;
  set errorMsg(String errorMsg) => _errorMsg.value = errorMsg;

  bool outOfSync = false;
  bool spotifyAvailable = true;

  RxString itemName = "".obs;
  RxInt itemNumber = 0.obs;
  int totalItemsToSynch = 0;

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
        itemlists = await ItemlistFirestore().fetchAll(profileId: profile.id);
      }
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    try {
      if(AppFlavour.appInUse == AppInUse.gigmeout && !Platform.isIOS) {
        await getSpotifyToken();
        if (userController.user!.spotifyToken.isNotEmpty
            && userController.profile.lastSpotifySync < DateTime
                .now().subtract(const Duration(days: 30))
                .millisecondsSinceEpoch
        ) {
          logger.d("Spotify Last Sync was more than 30 days");
          outOfSync = true;
        } else {
          logger.i("Spotify Last Sync in scope");
        }
      }
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
      errorMsg = '';
      if((isPublicNewItemlist && newItemlistNameController.text.isNotEmpty && newItemlistDescController.text.isNotEmpty)
          || (!isPublicNewItemlist && newItemlistNameController.text.isNotEmpty)) {
        Itemlist newItemlist = Itemlist.createBasic(newItemlistNameController.text, newItemlistDescController.text);
        newItemlist.ownerId = profile.id;
        String newItemlistId = "";
        if (profile.position?.latitude != 0.0) {
          newItemlist.position = profile.position!;
        }

        newItemlist.public = isPublicNewItemlist;
        newItemlistId = await ItemlistFirestore().insert(newItemlist);

        ///DEPRECATED
        // if(isPublicNewItemlist) {
        //   logger.i("Inserting Public Itemlist to Public collection");
        //   newItemlistId = await ItemlistFirestore().insert(newItemlist);
        // } else {
        //   logger.i("Inserting Private Itemlist to collection for profileId ${newItemlist.ownerId}");
        //   newItemlistId = await ItemlistFirestore().insert(newItemlist);
        // }

        logger.i("Empty Itemlist created successfully for profile ${newItemlist.ownerId}");
        newItemlist.id = newItemlistId;

        if(newItemlistId.isNotEmpty){
          itemlists[newItemlistId] = newItemlist;
          logger.v("Itemlists $itemlists");
          clearNewItemlist();
        } else {
          logger.d("Something happens trying to insert itemlist");
        }
      } else {
        logger.d(MessageTranslationConstants.pleaseFillItemlistInfo.tr);
        errorMsg = newItemlistNameController.text.isEmpty ? MessageTranslationConstants.pleaseAddName
            : MessageTranslationConstants.pleaseAddDescription;

        Get.snackbar(
            MessageTranslationConstants.addNewItemlist.tr,
            MessageTranslationConstants.pleaseFillItemlistInfo.tr,
            snackPosition: SnackPosition.bottom);      }
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

      if(await ItemlistFirestore().remove(itemlist.id)) {
        logger.d("Itemlist ${itemlist.id} removed");

        if(itemlist.appMediaItems?.isNotEmpty ?? false) {
          for(var appItem in itemlist.appMediaItems ?? []) {
            if(await ProfileFirestore().removeFavoriteItem(profile.id, appItem.id)) {
              if (userController.profile.favoriteItems != null &&
                  userController.profile.favoriteItems!.isNotEmpty) {
                logger.d("Removing item from global items for profile from userController");
                userController.profile.favoriteItems!.remove(appItem.id);
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
    update([AppPageIdConstants.itemlist]);
  }


  // @override
  // Future<void> setAsFavorite(Itemlist itemlist) async {
  //   logger.d("Making favorite for $itemlist");
  //
  //   try {
  //     if(await ItemlistFirestore().setAsFavorite(profile.id, itemlist)){
  //       itemlist.isFav = true;
  //       itemlists[itemlist.id] = itemlist;
  //       logger.i("Itemlist ${itemlist.id} set as favorite");
  //       if(await ItemlistFirestore().unsetOfFavorite(profile.id, _favItemlist)) {
  //         logger.i("Itemlist ${profile.id} unset from favorite");
  //         _favItemlist.isFav = false;
  //         itemlists[_favItemlist.id] = _favItemlist;
  //       }
  //       _favItemlist = itemlist;
  //     } else {
  //       logger.e("Something happens trying to remove itemlist");
  //     }
  //   } catch (e) {
  //     logger.e(e.toString());
  //   }
  //
  //   Get.back();
  //   update([AppPageIdConstants.itemlist]);
  // }


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

        if(await ItemlistFirestore().update(itemlist)){
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

    if(AppFlavour.appInUse == AppInUse.cyberneom) {
      await Get.toNamed(AppRouteConstants.listItems, arguments: [itemlist]);
    } else {
      AppMediaItemController appItemController;
      try {
        appItemController = Get.find<AppMediaItemController>();
        appItemController.itemlist = itemlist;
        appItemController.loadItemsFromList();
      } catch (e) {
        logger.w(e.toString());
        logger.i("Controller is not active");
      }

      await Get.toNamed(AppRouteConstants.listItems, arguments: [itemlist]);
      update([AppPageIdConstants.itemlist, AppPageIdConstants.itemlistItem]);
    }

  }

  Future<bool> synchronizeItemlist(Itemlist itemlist) async {
    logger.i("Synchronizing Itemlist ${itemlist.name}");
    isButtonDisabled = true;
    isLoading = true;
    bool wasSync = false;
    try {

      String itemlistId = "";
      Itemlist? existingItemlist;
      List<Itemlist>? existingItemlists = userController.profile.itemlists?.values
          .where((element) => element.name == itemlist.name).toList();

      if(existingItemlists?.isNotEmpty ?? false) {
        existingItemlist= existingItemlists?.first;
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
          logger.d("Removing item ${currentItem.name} from being synchronized");
        }

        totalItemsToSynch -= currentItems.length;
      }

      if(itemlistId.isEmpty) {
        if(itemlistOwner == ItemlistOwner.profile) {
          itemlist.ownerId = profile.id;
          itemlistId = await ItemlistFirestore().insert(itemlist);
        } else if(itemlistOwner == ItemlistOwner.band) {
          //TODO Add sync for band itemlist
          //itemlistId = await BandItemlistFirestore().insert(_gigBand.id, itemlist);
        }

        logger.i("Itemlist inserted with id $itemlistId");
      }

      if(itemlistId.isNotEmpty && (itemlist.appMediaItems?.isNotEmpty ?? false)) {
        itemlist.id = itemlistId;

        if(itemlistOwner == ItemlistOwner.profile) {
          userController.profile.itemlists![itemlist.id] = itemlist;
          currentItemlist = itemlist;

          for (AppMediaItem appItem in itemlist.appMediaItems ?? []) {

            itemName.value = appItem.name;
            itemNumber++;
            update([AppPageIdConstants.itemlist, AppPageIdConstants.playlistSong]);

            AppMediaItemFirestore().existsOrInsert(appItem);

            if(await ProfileFirestore().addFavoriteItem(profile.id, appItem.id)) {
              if (userController.profile.itemlists!.isNotEmpty) {
                logger.d("Adding item to global itemlist from userController");
                userController.profile.favoriteItems!.add(appItem.id);
              }
            }


          }

        } else if(itemlistOwner == ItemlistOwner.band) {
          userController.band.itemlists![itemlist.id] = itemlist;
          for (var appItem in itemlist.appMediaItems ?? []) {
            AppMediaItemFirestore().existsOrInsert(appItem);
            //TODO Add sync for band itemlist
          }
        }
        logger.d("Items added successfully from Itemlist");
        wasSync = true;
      } else {
        Get.snackbar(
            MessageTranslationConstants.spotifySynchronization.tr,
            "Playlist ${itemlist.name} ${MessageTranslationConstants.upToDate.tr}",
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

  Future<void> getSpotifyToken() async {
    logger.d("Getting SpotifyToken");
    String spotifyToken = await SpotifyApiCalls.getSpotifyToken();

    if(spotifyToken.isNotEmpty) {
      logger.v("Spotify access token is: $spotifyToken");
      userController.user!.spotifyToken = spotifyToken;
      await UserFirestore().updateSpotifyToken(userController.user!.id, spotifyToken);
    }
  }

  Future<void> synchronizeSpotifyPlaylists() async {
    logger.i("Getting Spotify Information with token: ${userController.user!.spotifyToken}");

    isLoading = true;
    update([AppPageIdConstants.itemlist]);

    spotify.User spotifyUser = await SpotifyApiCalls.getUserProfile(spotifyToken: userController.user!.spotifyToken);

    try {
      if(spotifyUser.id?.isNotEmpty ?? false) {
        spotifyPlaylistSimples =  await SpotifyApiCalls.getUserPlaylistSimples(spotifyToken: userController.user!.spotifyToken, userId: spotifyUser.id!);

        for (var playlist in spotifyPlaylistSimples) {
          if(playlist.id?.isNotEmpty ?? false) {
            spotifyItemlists[playlist.id!] = Itemlist.mapPlaylistSimpleToItemlist(playlist);
          }
        }

        Get.toNamed(AppRouteConstants.spotifyPlaylists);
      }
    } catch(e) {
      logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.itemlist]);
  }

  void handlePlaylistList(Itemlist spotifyItemlist) {

    try {
      if (addedItemlists.contains(spotifyItemlist)) {
        logger.d("Removing gigList ${spotifyItemlist.name}");
        addedItemlists.remove(spotifyItemlist);
        totalItemsToSynch -= spotifyPlaylistSimples.where((element) => element.id == spotifyItemlist.id).first.tracksLink?.total ?? 0;
      } else {
        logger.d("Adding giglist with name ${spotifyItemlist.name}");
        addedItemlists.add(spotifyItemlist);
        totalItemsToSynch += spotifyPlaylistSimples.where((element) => element.id == spotifyItemlist.id).first.tracksLink?.total ?? 0;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.playlistSong]);
  }

  //TODO Verify if needed
  void loadSongsForPlaylist(spotify.PlaylistSimple playlist) {
    itemlists.forEach((playlistId, giglist) async {
      giglist.appMediaItems = await SpotifySearch().loadSongsFromPlaylist(playlistId);
      logger.i("Adding ${giglist.appMediaItems?.length} song to Giglist ${giglist.name}");
      itemlists[playlistId] = giglist;
    });
  }

  Future<void> gotoPlaylistSongs(Itemlist itemlist) async {

    spotify.Playlist spotifyPlaylist = spotify.Playlist();

    try {
      spotify.PlaylistSimple playlistSimple = spotifyPlaylistSimples.where((element) => element.href == itemlist.href).first;

      if(playlistSimple.id?.isNotEmpty ?? false) {
        spotifyPlaylist = await SpotifyApiCalls.getPlaylist(spotifyToken: userController.user!.spotifyToken, playlistId: playlistSimple.id!);
      }

      if(spotifyPlaylist.href?.isNotEmpty ?? false) {
        itemlist.appMediaItems = AppMediaItem.mapTracksToSongs(spotifyPlaylist.tracks!);
        logger.d("${itemlist.appMediaItems?.length ?? 0} songs were mapped from ${spotifyPlaylist.name}");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    await Get.toNamed(AppRouteConstants.listItems, arguments: [itemlist, true]);
    update([AppPageIdConstants.itemlist, AppPageIdConstants.itemlistItem]);

  }

  Future<void> synchronizeItemlists() async {
    logger.i("Synchronizing ${addedItemlists.length} Giglists from Spotify Playlists");

    Map<Itemlist, bool> wereSynchronized = {};
    isLoading = true;
    isButtonDisabled = true;
    update([AppPageIdConstants.itemlist]);

    try {
      spotify.Playlist playlistToSync = spotify.Playlist();
      for (var addedItemlist in addedItemlists) {
        spotify.PlaylistSimple playlistSimple = spotifyPlaylistSimples.where((element) => element.href == addedItemlist.href).first;

        if(playlistSimple.id?.isNotEmpty ?? false) {
          playlistToSync = await SpotifyApiCalls.getPlaylist(spotifyToken: userController.user!.spotifyToken, playlistId: playlistSimple.id!);
        }

        if(playlistToSync.href?.isNotEmpty ?? false) {
          addedItemlist.appMediaItems = AppMediaItem.mapTracksToSongs(playlistToSync.tracks!);
          logger.i("${addedItemlist.appMediaItems?.length ?? 0} songs were mapped from ${playlistToSync.name}");
          wereSynchronized[addedItemlist] = await synchronizeItemlist(addedItemlist);
        }

      }

      if(wereSynchronized.values.firstWhere((element) => true)) {
        ProfileFirestore().updateLastSpotifySync(userController.profile.id);
        Get.toNamed(AppRouteConstants.finishingSpotifySync, arguments: [AppRouteConstants.finishingSpotifySync]);
      } else {
        logger.i("No giglist was updated. Each one is up to date");
      }
    } catch(e) {
      logger.e(e.toString());
    }


    wereSynchronized.forEach((giglist, wasSync) {
      if(!wasSync) {
        logger.d("Removing added Giglist ${giglist.name} as it's up to date");
        addedItemlists.remove(giglist);
      }
    });

    isLoading = false;
    isButtonDisabled = false;
    update();
  }

  Future<void> setPrivacyOption() async {
    logger.d("");
    isPublicNewItemlist = !isPublicNewItemlist;
    logger.d("New Itemlist would be ${isPublicNewItemlist ? 'Public':'Private'}");
    update([AppPageIdConstants.itemlist, AppPageIdConstants.itemlistItem]);
  }

}
