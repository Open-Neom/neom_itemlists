import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/band_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/band.dart';
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
import 'package:neom_commons/emxi/data/api_services/google_books/google_books_api.dart';
import 'package:neom_commons/emxi/domain/google_book.dart';
import 'package:neom_itemlists/itemlists/data/api_services/spotify/spotify_search.dart';
import 'package:neom_itemlists/itemlists/data/firestore/band_itemlist_firestore.dart';
import 'package:neom_posts/posts/ui/add/post_upload_controller.dart';
import '../../data/firestore/app_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
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

  final RxMap<String, AppItem> _appItems = <String, AppItem>{}.obs;
  Map<String, AppItem> get appItems => _appItems;
  set appItems(Map<String, AppItem> appItems) => _appItems.value = appItems;

  final RxMap<String, Itemlist> _itemlists = <String, Itemlist>{}.obs;
  Map<String, Itemlist> get itemlists => _itemlists;
  set itemlists(Map<String, Itemlist> itemlists) => _itemlists.value = itemlists;

  final RxList<AppItem> _addedItems = <AppItem>[].obs;
  List<AppItem> get addedItems => _addedItems;
  set addedItems(List<AppItem> addedItems) => _addedItems.value = addedItems;

  SpotifySearchType _spotifySearchType = SpotifySearchType.song;
  SpotifySearchType get spotifySearchType => _spotifySearchType;

  final RxString _searchParam = "".obs;
  String get searchParam => _searchParam.value;
  set searchParam(String searchParam) => _searchParam.value = searchParam;

  AppProfile _profile = AppProfile();
  Band _band = Band();
  Itemlist itemlist = Itemlist();
  ItemlistOwner itemlistOwner = ItemlistOwner.profile;

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
    appItems = <String, AppItem>{};
  }


  Future<void> initSearchParam(String text) async {
    searchParam = text;
    searchParamController.text = text;

    try {
      await searchAppItem();
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.spotifySearch]);
  }


  @override
  Future<void> setSearchParam(String text) async {
    searchParam = text;
    try {
      await searchAppItem();
    } catch (e) {
      logger.e(e.toString());
    }
    update([AppPageIdConstants.spotifySearch]);
  }


  @override
  Future<void> searchAppItem() async {
    logger.i(searchParam);
    clear();
    try {
      switch(_spotifySearchType) {
        case(SpotifySearchType.song):
          switch(AppFlavour.appInUse){
            case AppInUse.gigmeout:
              appItems = await SpotifySearch().searchSongs(searchParam);
              break;
            case AppInUse.emxi:
              List<GoogleBook> googleBooks = await GoogleBooksApi.searchBooks(searchParam);

              for (var googleBook in googleBooks) {
                AppItem book = GoogleBook.toAppItem(googleBook);
                appItems[book.id] = book;
              }
              break;
            case AppInUse.cyberneom:
              break;
          }

          logger.d("${appItems.length} appItems retrieved");
          break;
        case(SpotifySearchType.playlist):
          itemlists = await SpotifySearch().searchPlaylists(searchParam);

          itemlists.forEach((playlistId, itemlist) async {
            itemlist.appItems = await SpotifySearch().loadSongsFromPlaylist(playlistId);
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


  void handleItemlistItems(AppItem appItem, AppItemState appItemState) {

    try {
      if (addedItems.contains(appItem) && appItem.state == appItemState.value) {
        logger.d("Removing item with name ${appItem.name} from itemlist");
        setItemState(appItem.id, AppItemState.noState );
        addedItems.remove(appItem);
      } else {
        logger.d("Adding item with name ${appItem.name} to itemlist");
        addedItems.add(appItem);
        setItemState(appItem.id, appItemState);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.playlistSong]);
  }

  void setItemState(String itemId, AppItemState newState){
    logger.d("Setting new itemState $newState");
    update([AppPageIdConstants.itemlistItem, AppPageIdConstants.appItem, AppPageIdConstants.playlistSong]);
  }

  @override
  void getAppItemDetails(AppItem appItem) {
    logger.d("Sending appItem with title ${appItem.name} to item controller");
    Get.toNamed(AppFlavour.getItemDetailsRoute(), arguments: [appItem, itemlist.id]);
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

  Map<String, AppItem> loadItemsFromPlaylist(Itemlist itemlist){
    Map<String, AppItem> gItems = {};

    itemlist.appItems?.forEach((gItem) {
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
      await postUploadController.handleEventImage();
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
    itemlist.appItems = addedItems;


    try {
      if(postUploadController.imageFile.path.isNotEmpty) {
        String itemlistImgUrl = await postUploadController.handleUploadImage(UploadImageType.itemlist);
        if(itemlistImgUrl.isNotEmpty) {
          itemlist.imgUrl = itemlistImgUrl;
        }
      }

      String itemlistId = "";
      if(itemlistOwner == ItemlistOwner.profile) {
        itemlistId = await ItemlistFirestore().insert(_profile.id, itemlist);
      } else if(itemlistOwner == ItemlistOwner.band) {
        itemlistId = await BandItemlistFirestore().insert(_band.id, itemlist);
      }

      logger.d("Itemlist inserted with id $itemlistId");


      if(itemlistId.isNotEmpty) {
        itemlist.id = itemlistId;

        if(itemlistOwner == ItemlistOwner.profile) {
          userController.profile.itemlists![itemlist.id] = itemlist;

          for (var appItem in itemlist.appItems ?? []) {

            if(!await AppItemFirestore().exists(appItem.id)) {
              await AppItemFirestore().insert(appItem);
            }

            if(await ProfileFirestore().addAppItem(_profile.id, appItem.id)) {
              if (userController.profile.itemlists!.isNotEmpty) {
                logger.d("Adding item to global itemlist from userController");
                userController.profile.appItems!.add(appItem.id);
              }
            }
          }

        } else if(itemlistOwner == ItemlistOwner.band) {
          userController.band.itemlists![itemlist.id] = itemlist;
          for (var appItem in itemlist.appItems ?? []) {

            if(!await AppItemFirestore().exists(appItem.id)) {
              await AppItemFirestore().insert(appItem);
            }

            if(await BandFirestore().addAppItem(_band.id, appItem.id)){
              if (userController.band.itemlists!.isNotEmpty) {
                logger.d("Adding item to global itemlist from band");
                userController.band.appItems!.add(appItem.id);
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
