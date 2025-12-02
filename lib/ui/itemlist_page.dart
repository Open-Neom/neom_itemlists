
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'itemlist_controller.dart';
import 'widgets/itemlist_action_button.dart';
import 'widgets/itemlist_appbar.dart';
import 'widgets/itemlist_widgets.dart';

class ItemlistPage extends StatelessWidget {

  final ItemlistType? itemlistType;

  const ItemlistPage({super.key, this.itemlistType,});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemlistController>(
        id: AppPageIdConstants.itemlist,
        init: ItemlistController(type: itemlistType),
        builder: (controller) {
          return Scaffold(
          backgroundColor: AppFlavour.getBackgroundColor(),
          //TODO Verify when needed
          appBar: itemlistType != ItemlistType.readlist ? ItemlistAppBar(controller: controller) : null ,
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            padding: EdgeInsets.only(bottom: controller.ownerType == OwnerType.profile ? 80 : 0),
            child: controller.isLoading.value ? const Center(child: CircularProgressIndicator())
            : Column(
              children: [
                ListTile(
                  title: Text('${AppTranslationConstants.toCreate.tr.capitalize} ${(itemlistType?.name ?? AppFlavour.getDefaultItemlistType().name).tr}'),
                  leading: SizedBox.square(
                    dimension: 40,
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ),
                  onTap: () async {
                    await showAddItemlistDialog(context, controller);
                  },
                ),
                Expanded(
                  child: buildItemlistList(context, controller),
                ),
              ],
            )
          ),
          floatingActionButton: controller.isLoading.value ? const SizedBox.shrink()
              : ItemlistActionButton(itemlistType: itemlistType, ownerType: controller.ownerType,),
        );
      }
    );
  }

  Future<void> showAddItemlistDialog(BuildContext context, ItemlistController controller) async {
    (await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.main75,
        title: Text(CommonTranslationConstants.addNewItemlist.tr,),
        content: Obx(() => SizedBox(
          height: AppTheme.fullHeight(context)*0.3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //TODO Change lines colors to white.
              TextField(
                controller: controller.newItemlistNameController,
                decoration: InputDecoration(
                  labelText: CommonTranslationConstants.itemlistName.tr,
                ),
              ),
              TextField(
                controller: controller.newItemlistDescController,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: '${AppTranslationConstants.description.tr} (${AppTranslationConstants.optional})',
                ),
              ),
              AppTheme.heightSpace5,
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  child: Row(
                    children: <Widget>[
                      Checkbox(
                        value: controller.isPublicNewItemlist.value,
                        onChanged: (bool? newValue) => controller.setPrivacyOption(),
                      ),
                      Text(AppTranslationConstants.publicList.tr, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  onTap: () => controller.setPrivacyOption(),
                ),
              ),
              controller.errorMsg.isNotEmpty ? Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(controller.errorMsg.value.tr, style: const TextStyle(fontSize: 12, color: AppColor.red)),
                  ),
                ],) : const SizedBox.shrink()
            ],
          ),
        ),),
        actions: <Widget>[
          DialogButton(
            height: 50,
            color: AppColor.bondiBlue75,
            onPressed: () async {
              await controller.createItemlist(type: itemlistType);
              if(controller.errorMsg.value.isEmpty) Navigator.pop(ctx);
            },
            child: Text(
              AppTranslationConstants.add.tr,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    )) ?? false;
  }

}
