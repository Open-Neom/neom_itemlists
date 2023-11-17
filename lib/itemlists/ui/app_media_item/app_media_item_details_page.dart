import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/handled_cached_network_image.dart';
import 'package:neom_commons/core/ui/widgets/rating_heart_bar.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'app_media_item_details_controller.dart';

class AppMediaItemDetailsPage extends StatelessWidget {

  const AppMediaItemDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: GetBuilder<AppMediaItemDetailsController>(
      id: AppPageIdConstants.appMediaItemDetails,
      init: AppMediaItemDetailsController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(),
        body: SingleChildScrollView(
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          height: AppTheme.fullHeight(context),
          decoration: AppTheme.appBoxDecoration,
          child: _.isLoading.value ? const Center(child: CircularProgressIndicator())
            : Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Column(
                    children: [
                      AppTheme.heightSpace20,
                      SizedBox(width: 200, child: _.appMediaItem.imgUrl.isEmpty ? const Text("") : HandledCachedNetworkImage(_.appMediaItem.imgUrl, enableFullScreen: false,)),
                      AppTheme.heightSpace20,
                      Text(_.appMediaItem.name.isEmpty ? ""
                          : _.appMediaItem.name.length > AppConstants.maxAppItemNameLength ?
                      "${_.appMediaItem.name.substring(0,AppConstants.maxAppItemNameLength)}...": _.appMediaItem.name,
                          style: AppTheme.textStyle.merge(const TextStyle(fontSize: 24))),
                      AppTheme.heightSpace5,
                      Text(_.appMediaItem.artist,
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
                              AppConstants.initialTimeSeconds,
                              style: AppTheme.textStyle.merge(const TextStyle(
                                  fontSize: 12,
                                  color: Color.fromRGBO(250, 250, 250, 0.46))),
                            ),
                            Text(_.durationMinutes.value,
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
                            _.isPlaying.value ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 100,
                          ),
                          onTap: () async {
                            if(_.appMediaItem.url.isNotEmpty) {
                              _.isPlaying.value ? await _.pausePreview() : await _.playPreview();
                            } else {
                              AppUtilities.showSnackBar(
                                  title: AppTranslationConstants.noAvailablePreviewUrl,
                                  message: AppTranslationConstants.noAvailablePreviewUrlMsg
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
                            backgroundColor: MaterialStateProperty
                              .all<Color>(AppColor.bondiBlue75),
                          minimumSize: MaterialStateProperty.all<Size>(
                              Size(AppTheme.fullWidth(context)/2,AppTheme.fullHeight(context)/15))
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add, color: Colors.grey, size: 25),
                            _.existsInItemlist.value ? Text(AppTranslationConstants.removeFromItemlist.tr)
                                : Text(AppTranslationConstants.releaseItem.tr)],
                        ),
                      onPressed: () async => {
                        if (_.existsInItemlist.value) {
                          await _.removeItem()
                        } else {
                          _.itemlists.isNotEmpty ? Alert(
                            context: context,
                            style: AlertStyle(
                              backgroundColor: AppColor.main50,
                              titleStyle: const TextStyle(color: Colors.white)
                            ),
                            title: AppTranslationConstants.appItemPrefs.tr,
                            content: Column(
                              children: <Widget>[
                                _.userController.profile.type == ProfileType.instrumentist ?
                                Obx(()=>
                                  DropdownButton<String>(
                                    items: AppItemState.values.map((AppItemState itemState) {
                                      return DropdownMenuItem<String>(
                                          value: itemState.name,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(itemState.name.tr),
                                              itemState.value == 0 ? Container() : const Text(" - "),
                                              itemState.value == 0 ? Container() :
                                              RatingHeartBar(state: itemState.value.toDouble()),
                                            ],
                                          )
                                      );
                                    }).toList(),
                                    onChanged: (String? newState) {
                                      _.setAppItemState(EnumToString.fromString(AppItemState.values, newState!) ?? AppItemState.noState);
                                    },
                                    value: CoreUtilities.getItemState(_.appItemState.value).name,
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
                                  )) : Container(),
                                  _.itemlists.length > 1 ? Obx(()=> DropdownButton<String>(
                                  items: _.itemlists.values.map((itemlist) =>
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
                                    _.setSelectedItemlist(selectedItemlist!);
                                  },
                                  value: _.itemlistId.value,
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
                                )) : Container()
                                ],
                              ),
                              buttons: [
                              DialogButton(
                                color: AppColor.bondiBlue75,
                                child: Obx(()=>_.isLoading.value ? const Center(child: CircularProgressIndicator())
                                    : Text(AppTranslationConstants.add.tr,
                                )),
                                onPressed: () async => {
                                  _.userController.profile.type == ProfileType.instrumentist ?
                                  (_.appItemState > 0 ? await _.addItemlistItem(context, fanItemState: _.appItemState.value) :
                                    AppUtilities.showSnackBar(
                                      title: AppTranslationConstants.appItemPrefs.tr,
                                      message: MessageTranslationConstants.selectItemStateMsg.tr,
                                    )
                                  ) : await _.addItemlistItem(context,
                                      fanItemState: AppItemState.heardIt.value)
                                },
                              )],
                          ).show() : await _.addItemlistItem(context,
                            fanItemState: AppItemState.heardIt.value)
                        }
                      }
                    ),
                  ],
                ),
                Obx(()=> _.wasAdded.value ? Container(
                  padding: const EdgeInsets.only(top: 10),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(AppColor.bondiBlue75)
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
                      onPressed: () => AppUtilities.goHome()
                  )
                ) : Container()),
              ]
            ),
          ),
        ),
      ),
    ),);
  }
}
