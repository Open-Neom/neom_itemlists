import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/api_services/google_books/google_books_api.dart';
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/band_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/firestore/public_itemlist_firestore.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/model/band.dart';
import 'package:neom_commons/core/domain/model/google_book.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_commons/core/utils/enums/itemlist_owner.dart';
import 'package:neom_commons/core/utils/enums/spotify_search_type.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import 'package:neom_itemlists/itemlists/data/api_services/spotify/spotify_search.dart';
import 'package:neom_itemlists/itemlists/data/firestore/app_media_item_firestore.dart';
import 'package:neom_itemlists/itemlists/data/firestore/band_itemlist_firestore.dart';
import 'package:neom_music_player/ui/player/media_player_page.dart';
import 'package:neom_posts/posts/ui/add/post_upload_controller.dart';
import '../../domain/use_cases/spotify_search_service.dart';


class SpotifySearchController extends GetxController implements AppItemSearchService   {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();
  final postUploadController = Get.put(PostUploadController());
  TextEditingController searchParamController = TextEditingController();

  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final RxMap<String, AppMediaItem> _appMediaItems = <String, AppMediaItem>{}.obs;
  Map<String, AppMediaItem> get appMediaItems => _appMediaItems;
  set appMediaItems(Map<String, AppMediaItem> appMediaItems) => _appMediaItems.value = appMediaItems;

  final RxMap<String, Itemlist> _itemlists = <String, Itemlist>{}.obs;
  Map<String, Itemlist> get itemlists => _itemlists;
  set itemlists(Map<String, Itemlist> itemlists) => _itemlists.value = itemlists;

  final RxList<AppMediaItem> _addedItems = <AppMediaItem>[].obs;
  List<AppMediaItem> get addedItems => _addedItems;
  set addedItems(List<AppMediaItem> addedItems) => _addedItems.value = addedItems;

  SpotifySearchType _spotifySearchType = SpotifySearchType.song;
  SpotifySearchType get spotifySearchType => _spotifySearchType;

  final RxString _searchParam = "".obs;
  String get searchParam => _searchParam.value;
  set searchParam(String searchParam) => _searchParam.value = searchParam;

  AppProfile _profile = AppProfile();
  Band _band = Band();
  Itemlist itemlist = Itemlist();
  ItemlistOwner itemlistOwner = ItemlistOwner.profile;

  Map<String, AppReleaseItem> items = {};

  @override
  void onInit() async {
    super.onInit();
    try {

      _profile = userController.profile;
      _band = userController.band;
      itemlistOwner = userController.itemlistOwner;

      if(Get.arguments != null) {
        _spotifySearchType = Get.arguments[0];

        if(Get.arguments.length == 2) {
          switch(_spotifySearchType) {
            case(SpotifySearchType.song):
              itemlist =  Get.arguments[1];
              break;
            case(SpotifySearchType.playlist):
              await initSearchParam(Get.arguments[1]);
              break;
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }
  }


  @override
  void onReady() async {
    super.onReady();
    isLoading = false;
    update([AppPageIdConstants.spotifySearch]);
  }


  void clear() {
    appMediaItems = <String, AppMediaItem>{};
  }


  Future<void> initSearchParam(String text) async {
    searchParam = text;
    searchParamController.text = text;

    try {
      await searchAppMediaItem();
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.spotifySearch]);
  }


  @override
  Future<void> setSearchParam(String text) async {
    searchParam = text;
    try {
      await searchAppMediaItem();
    } catch (e) {
      logger.e(e.toString());
    }
    update([AppPageIdConstants.spotifySearch]);
  }


  @override
  Future<void> searchAppMediaItem() async {
    logger.i(searchParam);
    clear();
    try {
      switch(_spotifySearchType) {
        case(SpotifySearchType.song):

          if(items.isEmpty) {
            items = await AppReleaseItemFirestore().retrieveAll();
          }

          items.values.forEach((value) {
            if(value.name.toLowerCase().contains(searchParam) || value.ownerName.toLowerCase().contains(searchParam)){
              appMediaItems[value.id] = AppMediaItem.fromAppReleaseItem(value);
            }
          });

          switch(AppFlavour.appInUse){
            case AppInUse.gigmeout:
              Map<String, AppMediaItem> spotifySongs = await SpotifySearch().searchSongs(searchParam);

              appMediaItems.addAll(spotifySongs);
              break;
            case AppInUse.emxi:

              List<GoogleBook> googleBooks = await GoogleBooksApi.searchBooks(searchParam);
              for (var googleBook in googleBooks) {
                AppMediaItem book = GoogleBook.toAppMediaItem(googleBook);
                appMediaItems[book.id] = book;
              }
              break;
            case AppInUse.cyberneom:
              break;
          }

          logger.d("${appMediaItems.length} appMediaItems retrieved");
          break;
        case(SpotifySearchType.playlist):
          itemlists = await SpotifySearch().searchPlaylists(searchParam);

          itemlists.forEach((playlistId, itemlist) async {
            itemlist.appMediaItems = await SpotifySearch().loadSongsFromPlaylist(playlistId);
            itemlists[playlistId] = itemlist;
          });

          logger.d("${itemlists.length} playlists retrieved");
          break;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.spotifySearch]);
  }


  void handleItemlistItems(AppMediaItem appMediaItem, AppItemState appItemState) {

    try {
      if (addedItems.contains(appMediaItem) && appMediaItem.state == appItemState.value) {
        logger.d("Removing item with name ${appMediaItem.name} from itemlist");
        setItemState(appMediaItem.id, AppItemState.noState );
        addedItems.remove(appMediaItem);
      } else {
        logger.d("Adding item with name ${appMediaItem.name} to itemlist");
        addedItems.add(appMediaItem);
        setItemState(appMediaItem.id, appItemState);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.playlistSong]);
  }

  void setItemState(String itemId, AppItemState newState){
    logger.d("Setting new itemState $newState");
    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.appMediaItem, AppPageIdConstants.playlistSong]);
  }

  @override
  void getAppMediaItemDetails(AppMediaItem appMediaItem) {
    logger.d("Sending appMediaItem with title ${appMediaItem.name} to item controller");
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => MediaPlayerPage(appMediaItem: appMediaItem), opaque: false,
    );
    //
    // NeomPlayerInvoke.init(
    //   appMediaItems: [appMediaItem],
    //   index: 0, isOffline: false,
    // );
    // Get.back();
    // Get.toNamed(AppFlavour.getItemDetailsRoute(), arguments: [appMediaItem, itemlist.id]);

  }


  @override
  void getItemListDetails(Itemlist playlist) {
    logger.d("Going to itemlist with name ${playlist.name}");

    if(itemlist.name != playlist.name) {
      addedItems.clear();
    }
    itemlist = playlist;
    //items = loadItemsFromPlaylist(playlist);
    nameController.text = playlist.name;
    descController.text = playlist.description;
    Get.toNamed(AppRouteConstants.playlistItems);
  }

  Map<String, AppMediaItem> loadItemsFromPlaylist(Itemlist itemlist){
    Map<String, AppMediaItem> gItems = {};

    itemlist.appMediaItems?.forEach((gItem) {
      logger.d(gItem.name);
      gItems[gItem.id] = gItem;
    });

    return gItems;
  }


  void setItemlistName() {
    logger.d("");
    itemlist.name = nameController.text.trim();
    update([AppPageIdConstants.playlistNameDesc]);
  }


  void setItemlistDesc() {
    logger.d("");
    itemlist.description = descController.text.trim();
    update([AppPageIdConstants.playlistNameDesc]);
  }


  void addItemlistImage() async {
    logger.d("");
    try {
      await postUploadController.handleImage();
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.playlistNameDesc]);
  }


  void clearItemlistImage() async {
    logger.d("");
    try {
      postUploadController.clearImage();
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.playlistNameDesc]);
  }


  bool validateNameDesc(){
    return nameController.text.isEmpty ? false :
    descController.text.isEmpty ? false : true;
  }

  Future<void> createItemlist() async {

    isButtonDisabled = true;
    isLoading = true;
    update([AppPageIdConstants.playlistNameDesc]);
    itemlist.appMediaItems = addedItems;


    try {
      if(postUploadController.imageFile.path.isNotEmpty) {
        String itemlistImgUrl = await postUploadController.handleUploadImage(UploadImageType.itemlist);
        if(itemlistImgUrl.isNotEmpty) {
          itemlist.imgUrl = itemlistImgUrl;
        }
      }

      String itemlistId = "";
      if(itemlistOwner == ItemlistOwner.profile) {
        itemlist.ownerId = _profile.id;
        itemlistId = await PublicItemlistFirestore().insert(itemlist);
      } else if(itemlistOwner == ItemlistOwner.band) {
        itemlist.ownerId = _band.id;
        itemlistId = await BandItemlistFirestore().insert(itemlist);
      }

      logger.d("Itemlist inserted with id $itemlistId");


      if(itemlistId.isNotEmpty) {
        itemlist.id = itemlistId;

        if(itemlistOwner == ItemlistOwner.profile) {
          userController.profile.itemlists![itemlist.id] = itemlist;

          for (var appMediaItem in itemlist.appMediaItems ?? []) {

            if(!await AppMediaItemFirestore().exists(appMediaItem.id)) {
              await AppMediaItemFirestore().insert(appMediaItem);
            }

            if(await ProfileFirestore().addAppMediaItem(_profile.id, appMediaItem.id)) {
              if (userController.profile.itemlists!.isNotEmpty) {
                logger.d("Adding item to global itemlist from userController");
                userController.profile.favoriteItems!.add(appMediaItem.id);
              }
            }
          }

        } else if(itemlistOwner == ItemlistOwner.band) {
          userController.band.itemlists![itemlist.id] = itemlist;
          for (var appMediaItem in itemlist.appMediaItems ?? []) {

            if(!await AppMediaItemFirestore().exists(appMediaItem.id)) {
              await AppMediaItemFirestore().insert(appMediaItem);
            }

            if(await BandFirestore().addAppMediaItem(_band.id, appMediaItem.id)){
              if (userController.band.itemlists!.isNotEmpty) {
                logger.d("Adding item to global itemlist from band");
                userController.band.appMediaItems!.add(appMediaItem.id);
              }
            }
          }

        }
        logger.d("Items added successfully from Itemlist");
      }
      isButtonDisabled = false;
    } catch (e) {
      logger.e(e.toString());
    }

    if(itemlistOwner == ItemlistOwner.profile) {
      Get.offAllNamed(AppRouteConstants.home);
    } else if(itemlistOwner == ItemlistOwner.band) {
      Get.offAllNamed(AppRouteConstants.home);
    }

    update();

  }


}
