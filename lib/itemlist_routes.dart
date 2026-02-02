import 'package:sint/sint.dart';
import 'package:neom_commons/ui/splash_page.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'ui/app_media_item/app_media_item_details_page.dart';
import 'ui/itemlist_items_page.dart';
import 'ui/itemlist_page.dart';

class ItemlistRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.lists,
      page: () => ItemlistPage(),
    ),
    ///DEPRECATED
    // SintPage(
    //   name: AppRouteConstants.readlists,
    //   page: () => const ReadlistPage(),
    // ),
    SintPage(
      name: AppRouteConstants.itemDetails,
      page: () => const AppMediaItemDetailsPage(),
      transition: Transition.leftToRightWithFade,
    ),
    SintPage(
        name: AppRouteConstants.listItems,
        page: () => const ItemlistItemsPage(),
        transition: Transition.zoom
    ),
    SintPage(
        name: AppRouteConstants.finishingSpotifySync,
        page: () => const SplashPage(),
    ),
  ];

}
