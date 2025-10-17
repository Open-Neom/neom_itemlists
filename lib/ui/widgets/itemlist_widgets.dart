import 'package:cached_network_image/cached_network_image.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_commons/ui/widgets/rating_heart_bar.dart';
import 'package:neom_commons/utils/app_alerts.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/media_search_type.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../app_media_item/app_media_item_controller.dart';
import '../itemlist_controller.dart';

Widget buildItemlistList(BuildContext context, ItemlistController controller) {
  return ListView.separated(
    separatorBuilder: (context, index) => const Divider(),
    itemCount: controller.itemlists.length,
    shrinkWrap: true,
    itemBuilder: (context, index) {
      Itemlist itemlist = controller.itemlists.values.elementAt(index);
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: SizedBox(
            width: 50,
            child: itemlist.imgUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: itemlist.imgUrl)
                : ((itemlist.appMediaItems?.isNotEmpty ?? false) && (itemlist.appMediaItems!.first.imgUrl.isNotEmpty))
                ? CachedNetworkImage(imageUrl: itemlist.appMediaItems!.first.imgUrl)
                : ((itemlist.appReleaseItems?.isNotEmpty ?? false) && (itemlist.appReleaseItems!.first.imgUrl.isNotEmpty))
                ? CachedNetworkImage(imageUrl: itemlist.appReleaseItems!.first.imgUrl)
                : CachedNetworkImage(imageUrl: AppProperties.getAppLogoUrl())
        ),
        title: Row(
            children: <Widget>[
              Text(TextUtilities.capitalizeFirstLetter(itemlist.name.length > AppConstants.maxItemlistNameLength
                  ? "${itemlist.name.substring(0,AppConstants.maxItemlistNameLength)}..."
                  : itemlist.name)),
              ///DEPRECATE .isFav ? const Icon(Icons.favorite, size: 10,) : SizedBox.shrink()
            ]),
        subtitle: itemlist.description.isNotEmpty ? Text(TextUtilities.capitalizeFirstLetter(itemlist.description), maxLines: 3, overflow: TextOverflow.ellipsis,) : null,
        trailing: ActionChip(
          labelPadding: EdgeInsets.zero,
          backgroundColor: AppColor.main25,
          avatar: CircleAvatar(
            backgroundColor: AppColor.white80,
            child: Text(((itemlist.appMediaItems?.length ?? 0) + (itemlist.appReleaseItems?.length ?? 0)).toString(),
                style: const TextStyle(color: Colors.black87),
            ),
          ),
          label: Icon(AppFlavour.getAppItemIcon(), color: AppColor.white80),
          onPressed: () async {
            if(AppConfig.instance.appInUse == AppInUse.c || !itemlist.isModifiable) {
              await controller.gotoItemlistItems(itemlist);
            } else {
              Get.toNamed(AppRouteConstants.itemSearch,
                  arguments: [MediaSearchType.song, itemlist]
              );
            }
          },
        ),
        onTap: () async {
          await controller.gotoItemlistItems(itemlist);
        },
        onLongPress: () async {
          (await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
            backgroundColor: AppColor.main75,
            title: Text(CommonTranslationConstants.itemlistName.tr,),
            content: SizedBox(
              height: AppTheme.fullHeight(context)*0.25,
              child: Obx(()=> controller.isLoading.value ? const Center(child: CircularProgressIndicator())
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextField(
                      controller: controller.newItemlistNameController,
                      decoration: InputDecoration(
                        labelText: '${AppTranslationConstants.changeName.tr}: ',
                        hintText: itemlist.name,
                      ),
                    ),
                    TextField(
                      controller: controller.newItemlistDescController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: '${AppTranslationConstants.changeDesc.tr}: ',
                        hintText: itemlist.description,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              DialogButton(
                color: AppColor.bondiBlue75,
                onPressed: () async {
                  await controller.updateItemlist(itemlist.id, itemlist);
                  Navigator.pop(ctx);
                },
                child: Text(AppTranslationConstants.update.tr,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              DialogButton(
                color: AppColor.bondiBlue75,
                child: Text(AppTranslationConstants.remove.tr,
                  style: const TextStyle(fontSize: 14),
                ),
                onPressed: () async {
                  if(controller.itemlists.length == 1) {
                    AppAlerts.showAlert(context,
                        title: CommonTranslationConstants.itemlistPrefs.tr,
                        message: CommonTranslationConstants.cantRemoveMainItemlist.tr);
                  } else {
                    await controller.deleteItemlist(itemlist);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
          )) ?? false;
        },
      );
    },
  );
}

Widget buildItemList(BuildContext context, AppMediaItemController controller) {
  return ListView.separated(
    separatorBuilder: (context, index) => const Divider(),
    itemCount: controller.itemlistItems.length,
    itemBuilder: (context, index) {
      AppMediaItem appMediaItem = controller.itemlistItems.values.elementAt(index);
      return ListTile(
          leading: HandledCachedNetworkImage(appMediaItem.imgUrl.isNotEmpty
              ? appMediaItem.imgUrl : controller.itemlist.imgUrl, enableFullScreen: false,
            width: 40,
          ),
          title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: AppTheme.fullWidth(context)*0.4,
                  child: Text(appMediaItem.name, maxLines: 5, overflow: TextOverflow.ellipsis,),
                ),
                (AppConfig.instance.appInUse == AppInUse.c || (controller.userServiceImpl.profile.type == ProfileType.appArtist && !controller.isFixed)) ?
                RatingHeartBar(state: appMediaItem.state.toDouble()) : const SizedBox.shrink(),
              ]
          ),
          subtitle: SizedBox(
            width: AppTheme.fullWidth(context)*0.4,
            child: (AppConfig.instance.appInUse == AppInUse.c && (appMediaItem.description?.isNotEmpty ?? false)) ?
            Text(appMediaItem.description ?? '', textAlign: TextAlign.justify,) :
            Text(appMediaItem.artist, maxLines: 2, overflow: TextOverflow.ellipsis,),
          ),
          trailing: IconButton(
              icon: const Icon(
                  CupertinoIcons.forward
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Get.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [appMediaItem]);
              }
          ),
          onTap: () => AppConfig.instance.appInUse == AppInUse.c || !controller.isFixed ? controller.getItemlistItemDetails(appMediaItem) : {},
          onLongPress: () => controller.itemlist.isModifiable && (AppConfig.instance.appInUse != AppInUse.c || !controller.isFixed) ? Alert(
              context: context,
              title: CommonTranslationConstants.appItemPrefs.tr,
              style: AlertStyle(
                  backgroundColor: AppColor.main50,
                  titleStyle: const TextStyle(color: Colors.white)
              ),
              content: Column(
                children: <Widget>[
                  Obx(() =>
                      DropdownButton<String>(
                        items: AppItemState.values.map((AppItemState appItemState) {
                          return DropdownMenuItem<String>(
                              value: appItemState.name,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(appItemState.name.tr),
                                  appItemState.value == 0 ? const SizedBox.shrink() : const Text(" - "),
                                  appItemState.value == 0 ? const SizedBox.shrink() :
                                  RatingHeartBar(state: appItemState.value.toDouble(),),
                                ],
                              )
                          );
                        }).toList(),
                        onChanged: (String? newItemState) {
                          controller.setItemState(EnumToString.fromString(AppItemState.values, newItemState!) ?? AppItemState.noState);
                        },
                        value: CoreUtilities.getItemState(controller.itemState.value).name,
                        icon: const Icon(Icons.arrow_downward),
                        iconSize: 15,
                        elevation: 15,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: AppColor.getMain(),
                        underline: Container(
                          height: 1,
                          color: Colors.grey,
                        ),
                      ),
                  ),
                ],
              ),
              buttons: [
                DialogButton(
                  color: AppColor.bondiBlue75,
                  child: Text(AppTranslationConstants.update.tr,
                    style: const TextStyle(fontSize: 15),
                  ),
                  onPressed: () => {
                    controller.updateItemlistItem(appMediaItem)
                  },
                ),
                DialogButton(
                  color: AppColor.bondiBlue75,
                  child: Text(AppTranslationConstants.remove.tr,
                    style: const TextStyle(fontSize: 15),
                  ),
                  onPressed: () async => {
                    await controller.removeItemFromList(appMediaItem)
                  },
                ),
              ]
          ).show() : {}
      );
    },
  );
}
