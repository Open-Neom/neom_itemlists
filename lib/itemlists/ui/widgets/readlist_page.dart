
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/app_flavour.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/core/utils/enums/itemlist_type.dart';
import 'package:neom_core/core/utils/enums/owner_type.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../itemlist_controller.dart';
import 'itemlist_widgets.dart';

class ReadlistPage extends StatelessWidget {
  const ReadlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemlistController>(
        id: AppPageIdConstants.itemlist,
        init: ItemlistController(),
        builder: (_) => Scaffold(
          backgroundColor: AppColor.main50,
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            padding: EdgeInsets.only(bottom: _.ownerType == OwnerType.profile ? 80 : 0),
            child: _.isLoading.value ? const Center(child: CircularProgressIndicator())
            : Column(
              children: [
                ListTile(
                  title: Text(AppTranslationConstants.createReadlist.tr),
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
                    await showAddItemlistDialog(context, _);
                  },
                ),
                Expanded(
                  child: buildItemlistList(context, _),
                ),
              ],
            )
          ),
          floatingActionButton: _.isLoading.value ? const SizedBox.shrink() : Container(
            margin: const EdgeInsets.only(bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        child: AnimatedTextKit(
                          repeatForever: true,
                          animatedTexts: [
                            FlickerAnimatedText(AppTranslationConstants.suggestedReading.tr)
                          ],
                          onTap: () {
                            _.gotoSuggestedItem();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 5,),
                    FloatingActionButton(
                      elevation: AppTheme.elevationFAB,
                      child: Icon(AppFlavour.getSyncIcon()),
                      onPressed: () => {
                        _.gotoSuggestedItem()
                      },
                    ),

                  ],
                ),
              ]
          ),),
        )
    );
  }

  Future<void> showAddItemlistDialog(BuildContext context, ItemlistController _) async {
    (await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.main75,
        title: Text(AppTranslationConstants.addNewItemlist.tr,),
        content: Obx(() => SizedBox(
          height: AppTheme.fullHeight(context)*0.3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //TODO Change lines colors to white.
              TextField(
                controller: _.newItemlistNameController,
                decoration: InputDecoration(
                  labelText: AppTranslationConstants.itemlistName.tr,
                ),
              ),
              TextField(
                controller: _.newItemlistDescController,
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
                        value: _.isPublicNewItemlist.value,
                        onChanged: (bool? newValue) => _.setPrivacyOption(),
                      ),
                      Text(AppTranslationConstants.publicList.tr, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  onTap: () => _.setPrivacyOption(),
                ),
              ),
              _.errorMsg.isNotEmpty ? Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(_.errorMsg.value.tr, style: const TextStyle(fontSize: 12, color: AppColor.red)),
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
              await _.createItemlist(type: ItemlistType.readlist);
              if(_.errorMsg.value.isEmpty) Navigator.pop(ctx);
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
