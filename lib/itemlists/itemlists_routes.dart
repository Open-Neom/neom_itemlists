import 'package:get/get.dart';
import 'package:neom_commons/core/ui/static/splash_page.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'ui/app_media_item/app_media_item_details_page.dart';

import 'ui/itemlist_items_page.dart';
import 'ui/itemlist_page.dart';
import 'ui/search/app_media_item_search_page.dart';
import 'ui/search/playlist_name_desc_page.dart';
import 'ui/search/playlist_songs_page.dart';

class ItemlistsRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.lists,
      page: () => const ItemlistPage(),
    ),
    GetPage(
      name: AppRouteConstants.itemSearch,
      page: () => const AppMediaItemSearchPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.playlistSearch,
      page: () => const AppMediaItemSearchPage(),
      transition: Transition.zoom,
    ),
    GetPage(
        name: AppRouteConstants.playlistItems,
        page: () => const PlaylistItemsPage(),
        transition: Transition.leftToRight
    ),
    GetPage(
        name: AppRouteConstants.playlistNameDesc,
        page: () => const PlaylistNameDescPage(),
        transition: Transition.leftToRight
    ),
    GetPage(
      name: AppRouteConstants.itemDetails,
      page: () => const AppMediaItemDetailsPage(),
      transition: Transition.leftToRightWithFade,
    ),
    GetPage(
        name: AppRouteConstants.listItems,
        page: () => const ItemlistItemsPage(),
        transition: Transition.leftToRight
    ),
    GetPage(
        name: AppRouteConstants.finishingSpotifySync,
        page: () => const SplashPage(),
    ),
  ];

}
