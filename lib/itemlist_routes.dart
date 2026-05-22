import 'package:neom_commons/ui/splash_page.dart';
import 'package:neom_core/ui/deferred_loader.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'ui/app_media_item/app_media_item_details_page.dart' deferred as itemDetails;
import 'ui/itemlist_items_page.dart' deferred as itemlistItems;
import 'ui/itemlist_page.dart' deferred as itemlist;

class ItemlistRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.lists,
      page: () => DeferredLoader(itemlist.loadLibrary, () => itemlist.ItemlistPage()),
    ),
    ///DEPRECATED
    // SintPage(
    //   name: AppRouteConstants.readlists,
    //   page: () => const ReadlistPage(),
    // ),
    SintPage(
      name: AppRouteConstants.itemDetails,
      page: () => DeferredLoader(itemDetails.loadLibrary, () => itemDetails.AppMediaItemDetailsPage()),
      transition: Transition.leftToRightWithFade,
    ),
    SintPage(
        name: AppRouteConstants.listItems,
        page: () => DeferredLoader(itemlistItems.loadLibrary, () => itemlistItems.ItemlistItemsPage()),
        transition: Transition.zoom
    ),
    SintPage(
        name: AppRouteConstants.finishingSpotifySync,
        page: () => const SplashPage(),
    ),
  ];

}
