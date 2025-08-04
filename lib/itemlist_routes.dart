import 'package:get/get.dart';
import 'package:neom_commons/ui/splash_page.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'ui/app_media_item/app_media_item_details_page.dart';
import 'ui/itemlist_items_page.dart';
import 'ui/itemlist_page.dart';
import 'ui/widgets/readlist_page.dart';

class ItemlistRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.lists,
      page: () => const ItemlistPage(),
    ),
    GetPage(
      name: AppRouteConstants.readlists,
      page: () => const ReadlistPage(),
    ),
    GetPage(
      name: AppRouteConstants.itemDetails,
      page: () => const AppMediaItemDetailsPage(),
      transition: Transition.leftToRightWithFade,
    ),
    GetPage(
        name: AppRouteConstants.listItems,
        page: () => const ItemlistItemsPage(),
        transition: Transition.zoom
    ),
    GetPage(
        name: AppRouteConstants.finishingSpotifySync,
        page: () => const SplashPage(),
    ),
  ];

}
