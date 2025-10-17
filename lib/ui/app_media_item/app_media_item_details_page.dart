import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_commons/ui/widgets/rating_heart_bar.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../utils/constants/itemlist_translation_constants.dart';
import 'app_media_item_details_controller.dart';

class AppMediaItemDetailsPage extends StatelessWidget {

  const AppMediaItemDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppMediaItemDetailsController>(
      id: AppPageIdConstants.appMediaItemDetails,
      init: AppMediaItemDetailsController(),
      builder: (controller) => Scaffold(
        appBar: AppBarChild(),
        body: SingleChildScrollView(
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          height: AppTheme.fullHeight(context),
          decoration: AppTheme.appBoxDecoration,
          child: controller.isLoading.value ? const Center(child: CircularProgressIndicator())
            : Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Column(
                    children: [
                      AppTheme.heightSpace20,
                      SizedBox(width: 200, child: controller.appMediaItem.imgUrl.isEmpty ? const Text("") : HandledCachedNetworkImage(controller.appMediaItem.imgUrl, enableFullScreen: false,)),
                      AppTheme.heightSpace20,
                      Text(controller.appMediaItem.name.isEmpty ? ""
                          : controller.appMediaItem.name.length > AppConstants.maxAppItemNameLength ?
                      "${controller.appMediaItem.name.substring(0,AppConstants.maxAppItemNameLength)}...": controller.appMediaItem.name,
                          style: AppTheme.textStyle.merge(const TextStyle(fontSize: 24))),
                      AppTheme.heightSpace5,
                      Text(controller.appMediaItem.artist,
                        style: AppTheme.textStyle.merge(
                            const TextStyle(
                                fontSize: 18,
                                color: Colors.white54
                            )
                        )
                      ),
                      AppTheme.heightSpace20,
                      Row(
                          children: <Widget>[
                            Container(
                              width: 150,
                              height: 2,
                              color: Colors.white54,
                            ),
                            Flexible(
                              child: Container(
                                height: 1.0,
                                color: Colors.white54,
                              ),
                            ),
                          ]
                        ),
                        AppTheme.heightSpace5,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              CoreConstants.initialTimeSeconds,
                              style: AppTheme.textStyle.merge(const TextStyle(
                                  fontSize: 12,
                                  color: Color.fromRGBO(250, 250, 250, 0.46))),
                            ),
                            Text(controller.durationMinutes.value,
                              style: AppTheme.textStyle.merge(
                                const TextStyle(
                                  fontSize: 12,
                                  color: Color.fromRGBO(250, 250, 250, 0.46)
                                )
                              ),
                            )
                          ],
                        ),
                        AppTheme.heightSpace10,
                        GestureDetector(
                          child: Icon(
                            controller.isPlaying.value ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 100,
                          ),
                          onTap: () async {
                            if(controller.appMediaItem.url.isNotEmpty) {
                              controller.isPlaying.value ? await controller.pausePreview() : await controller.playPreview();
                            } else {
                              AppUtilities.showSnackBar(
                                  title: CommonTranslationConstants.noAvailablePreviewUrl,
                                  message: ItemlistTranslationConstants.noAvailablePreviewUrlMsg
                              );
                            }
                          }
                        ),
                    ]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                      ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: WidgetStateProperty
                              .all<Color>(AppColor.bondiBlue75),
                          minimumSize: WidgetStateProperty.all<Size>(
                              Size(AppTheme.fullWidth(context)/2,AppTheme.fullHeight(context)/15))
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add, color: Colors.grey, size: 25),
                            controller.existsInItemlist.value ? Text(CommonTranslationConstants.removeFromItemlist.tr)
                                : Text(AppTranslationConstants.releaseItem.tr)],
                        ),
                      onPressed: () async => {
                        if (controller.existsInItemlist.value) {
                          await controller.removeItem()
                        } else {
                          controller.itemlists.isNotEmpty ? Alert(
                            context: context,
                            style: AlertStyle(
                              backgroundColor: AppColor.main50,
                              titleStyle: const TextStyle(color: Colors.white)
                            ),
                            title: CommonTranslationConstants.appItemPrefs.tr,
                            content: Column(
                              children: <Widget>[
                                controller.userServiceImpl.profile.type == ProfileType.appArtist ?
                                Obx(()=>
                                  DropdownButton<String>(
                                    items: AppItemState.values.map((AppItemState itemState) {
                                      return DropdownMenuItem<String>(
                                          value: itemState.name,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(itemState.name.tr),
                                              itemState.value == 0 ? const SizedBox.shrink() : const Text(" - "),
                                              itemState.value == 0 ? const SizedBox.shrink() :
                                              RatingHeartBar(state: itemState.value.toDouble()),
                                            ],
                                          )
                                      );
                                    }).toList(),
                                    onChanged: (String? newState) {
                                      controller.setAppItemState(EnumToString.fromString(AppItemState.values, newState!) ?? AppItemState.noState);
                                    },
                                    value: CoreUtilities.getItemState(controller.appItemState.value).name,
                                    alignment: Alignment.center,
                                    icon: const Icon(Icons.arrow_downward),
                                    iconSize: 20,
                                    elevation: 16,
                                    style: const TextStyle(color: Colors.white),
                                    dropdownColor: AppColor.main75,
                                    underline: Container(
                                      height: 1,
                                      color: Colors.grey,
                                    ),
                                  )) : const SizedBox.shrink(),
                                  controller.itemlists.length > 1 ? Obx(()=> DropdownButton<String>(
                                  items: controller.itemlists.values.map((itemlist) =>
                                    DropdownMenuItem<String>(
                                      value: itemlist.id,
                                      child: Center(
                                          child: Text(
                                              itemlist.name.length > AppConstants.maxItemlistNameLength
                                                  ? "${itemlist.name.substring(0,AppConstants.maxItemlistNameLength)}..."
                                                  : itemlist.name
                                          )
                                      ),
                                    )
                                  ).toList(),
                                  onChanged: (String? selectedItemlist) {
                                    controller.setSelectedItemlist(selectedItemlist!);
                                  },
                                  value: controller.itemlistId.value,
                                  icon: const Icon(Icons.arrow_downward),
                                  alignment: Alignment.center,
                                  iconSize: 20,
                                  elevation: 16,
                                  style: const TextStyle(color: Colors.white),
                                  dropdownColor: AppColor.main75,
                                  underline: Container(
                                    height: 1,
                                    color: Colors.grey,
                                  ),
                                )) : const SizedBox.shrink()
                                ],
                              ),
                              buttons: [
                              DialogButton(
                                color: AppColor.bondiBlue75,
                                child: Obx(()=>controller.isLoading.value ? const Center(child: CircularProgressIndicator())
                                    : Text(AppTranslationConstants.add.tr,
                                )),
                                onPressed: () async => {
                                  controller.userServiceImpl.profile.type == ProfileType.appArtist ?
                                  (controller.appItemState > 0 ? await controller.addItemlistItem(context, fanItemState: controller.appItemState.value) :
                                    AppUtilities.showSnackBar(
                                      title: CommonTranslationConstants.appItemPrefs.tr,
                                      message: MessageTranslationConstants.selectItemStateMsg.tr,
                                    )
                                  ) : await controller.addItemlistItem(context,
                                      fanItemState: AppItemState.heardIt.value)
                                },
                              )],
                          ).show() : await controller.addItemlistItem(context,
                            fanItemState: AppItemState.heardIt.value)
                        }
                      }
                    ),
                  ],
                ),
                Obx(()=> controller.wasAdded.value ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(AppColor.bondiBlue75)
                    ),
                    child: SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.playlist_add_check, color: Colors.grey, size: 30),
                          Text(AppTranslationConstants.goHome.tr),]
                        ),
                      ),
                      onPressed: () => Get.offAllNamed(AppRouteConstants.home)
                  )
                ) : const SizedBox.shrink()),
              ]
            ),
          ),
        ),
      ),
    );
  }
}
