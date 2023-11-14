import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/auth/ui/login/login_controller.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/owner_type.dart';
import 'package:neom_commons/core/utils/enums/spotify_search_type.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'itemlist_controller.dart';
import 'widgets/itemlist_widgets.dart';

class ItemlistPage extends StatelessWidget {
  const ItemlistPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColor.getMain(),
            title: const Text(AppConstants.appTitle),
            content:  Text(AppTranslationConstants.wantToCloseApp.tr),
            actions: <Widget>[
              TextButton(
                child: Text(AppTranslationConstants.no.tr,
                  style: const TextStyle(color: AppColor.white),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(AppTranslationConstants.yes.tr,
                  style: const TextStyle(color: AppColor.white),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              )
            ],
          ),
        )) ?? false;
      },
      child: GetBuilder<ItemlistController>(
        id: AppPageIdConstants.itemlist,
        init: ItemlistController(),
        builder: (_) => Scaffold(
          backgroundColor: AppColor.main75,
          appBar: AppFlavour.appInUse == AppInUse.g ? AppBar(
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    if(_.itemlists.isNotEmpty) {
                      Get.toNamed(AppRouteConstants.itemSearch,
                          arguments: [SpotifySearchType.song]
                      );
                    } else {
                      AppUtilities.showSnackBar(
                          title: AppTranslationConstants.noItemlistsMsg,
                          message: AppTranslationConstants.noItemlistsMsg2
                      );
                    }
                  },
                ),
              ),
            ],
            title: Text(AppTranslationConstants.myItemlists.tr,
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
          ) : null,
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            padding: EdgeInsets.only(bottom: _.ownerType == OwnerType.profile ? 80 : 0),
            child: _.isLoading.value ? const Center(child: CircularProgressIndicator())
            : Column(
              children: [
                ListTile(
                  title: Text(AppTranslationConstants.createItemlist.tr),
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
                                minLines: 2,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  labelText: AppTranslationConstants.description.tr,
                                ),
                              ),
                              AppTheme.heightSpace10,
                              Container(
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
                                  Container(
                                    alignment: Alignment.center,
                                    child: Text(_.errorMsg.value.tr, style: const TextStyle(fontSize: 12, color: AppColor.red)),
                                  ),
                                ],) : Container()
                            ],
                          ),
                        ),),
                        actions: <Widget>[
                          DialogButton(
                            height: 50,
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              await _.createItemlist();
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
                  },
                ),
                Expanded(
                  child: buildItemlistList(context, _),
                ),
              ],
            )
          ),
          floatingActionButton: _.isLoading.value ? Container() : Container(
            margin: const EdgeInsets.only(bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppFlavour.appInUse != AppInUse.c
                    && (AppFlavour.appInUse == AppInUse.e || (Platform.isAndroid || kDebugMode)) ?
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppFlavour.appInUse == AppInUse.e || _.outOfSync
                        ? SizedBox(
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        child: AnimatedTextKit(
                          repeatForever: true,
                          animatedTexts: [
                            FlickerAnimatedText(
                                AppFlavour.appInUse == AppInUse.g ?
                                AppTranslationConstants.synchronizeSpotifyPlaylists.tr
                                : AppTranslationConstants.suggestedReading.tr),
                          ],
                          onTap: () {
                            AppFlavour.appInUse == AppInUse.g
                                ? _.synchronizeSpotifyPlaylists()
                                : Get.toNamed(AppRouteConstants.PDFViewer,
                                arguments: [Get.find<LoginController>().appInfo.suggestedUrl, 0, 150]);
                            },
                        ),
                      ),
                    ) : Container(),
                    const SizedBox(width: 5,),
                    FloatingActionButton(
                      heroTag: AppPageIdConstants.spotifySync,
                      elevation: AppTheme.elevationFAB,
                      child: Icon(AppFlavour.getSyncIcon()),
                      onPressed: () => {
                        AppFlavour.appInUse == AppInUse.g
                        ? _.synchronizeSpotifyPlaylists()
                        : Get.toNamed(AppRouteConstants.PDFViewer,
                        arguments: [Get.find<LoginController>().appInfo.suggestedUrl, true, 0, 250])
                      },
                    ),
                  ],
                ) : Container(),
                if(_.ownerType == OwnerType.profile) AppTheme.heightSpace75,
              ]
          ),),
        )
      )
    );
  }
}
