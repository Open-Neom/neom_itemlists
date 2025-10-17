import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';

import 'app_media_item/app_media_item_controller.dart';
import 'widgets/itemlist_widgets.dart';

class ItemlistItemsPage extends StatelessWidget {
  const ItemlistItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppMediaItemController>(
      id: AppPageIdConstants.itemlistItem,
      init: AppMediaItemController(),
      builder: (controller) => Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        appBar: AppBarChild(title: controller.itemlist.name.length > AppConstants.maxItemlistNameLength
            ? "${controller.itemlist.name.substring(0,AppConstants.maxItemlistNameLength)}..."
            : controller.itemlist.name),
        body: Container(
          width: AppTheme.fullWidth(context),
          height: AppTheme.fullHeight(context),
          decoration: AppTheme.appBoxDecoration, 
          child: controller.isLoading.value ? const Center(child: CircularProgressIndicator())
              : Obx(()=> buildItemList(context, controller)),
        ),
        floatingActionButton: controller.isFixed || !controller.itemlist.isModifiable ? const SizedBox.shrink()
            : FloatingActionButton(
          tooltip: CommonTranslationConstants.addItem.tr,
          ///IMPROVE FILTER TO ADD ITEM TO DIFFERENT LISTS
          onPressed: ()=> Get.toNamed(AppRouteConstants.itemSearch, arguments: [controller.itemlist.type == ItemlistType.readlist ? MediaSearchType.book : MediaSearchType.song, controller.itemlist]),
          child: const Icon(Icons.playlist_add),
        ),
      ),
    );
  }
}
