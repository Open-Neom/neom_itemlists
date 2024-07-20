import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/spotify_search_type.dart';
import 'app_media_item/app_media_item_controller.dart';
import 'widgets/app_item_widgets.dart';

class ItemlistItemsPage extends StatelessWidget {
  const ItemlistItemsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppMediaItemController>(
      id: AppPageIdConstants.itemlistItem,
      init: AppMediaItemController(),
      builder: (_) => Scaffold(
        backgroundColor: AppColor.getMain(),
        appBar: AppBarChild(title: _.itemlist.name.length > AppConstants.maxItemlistNameLength
            ? "${_.itemlist.name.substring(0,AppConstants.maxItemlistNameLength)}..."
            : _.itemlist.name),
        body: Container(
          width: AppTheme.fullWidth(context),
          height: AppTheme.fullHeight(context),
          decoration: AppTheme.appBoxDecoration, 
          child: _.isLoading.value ? const Center(child: CircularProgressIndicator())
              : Obx(()=> buildItemList(context, _)),
        ),
        floatingActionButton: _.isFixed || !_.itemlist.isModifiable ? const SizedBox.shrink()
            : FloatingActionButton(
          tooltip: AppTranslationConstants.addItem.tr,
          onPressed: ()=> {
            Get.toNamed(AppRouteConstants.itemSearch,
                arguments: [SpotifySearchType.song, _.itemlist])
          },
          child: const Icon(Icons.playlist_add),
        ),
      ),
    );
  }
}
