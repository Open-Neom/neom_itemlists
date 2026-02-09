import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/itemlist_translation_constants.dart';
import '../itemlist_controller.dart';


class ItemlistAppBar extends StatelessWidget implements PreferredSizeWidget {

  final ItemlistController controller;

  const ItemlistAppBar({
    required this.controller,
    super.key
  });

  @override
  Size get preferredSize => AppTheme.appBarHeight;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              if(controller.itemlists.isNotEmpty) {
                Sint.toNamed(AppRouteConstants.itemSearch,
                    arguments: [MediaSearchType.song]
                );
              } else {
                AppUtilities.showSnackBar(
                    title: ItemlistTranslationConstants.noItemlistsMsg,
                    message: ItemlistTranslationConstants.noItemlistsMsg2
                );
              }
            },
          ),
        ),
      ],
      title: Text(ItemlistTranslationConstants.myItemlists.tr,
        style: TextStyle(
          fontSize: 18,
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
      centerTitle: true,
      backgroundColor: AppColor.main75,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: EdgeInsets.zero,
        child: Transform.rotate(
          angle: 22 / 7 * 2,
          child: IconButton(
            icon: const Icon(
              Icons.horizontal_split_rounded,
            ),
            // color: Theme.of(context).iconTheme.color,
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ),
      ),
    );
  }

}
