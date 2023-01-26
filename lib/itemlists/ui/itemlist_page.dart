import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
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
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: _.isLoading ? const Center(child: CircularProgressIndicator())
            : Column(
              children: <Widget>[
                Expanded(
                  child: buildItemlistList(context, _),
                ),
              ]
            ),
          ),
          floatingActionButton: _.isLoading ? Container() :Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                heroTag: AppPageIdConstants.itemlist,
                elevation: AppTheme.elevationFAB,
                tooltip: AppTranslationConstants.createItemlist.tr,
                child: const Icon(Icons.playlist_add),
                onPressed: () => {
                  Alert(
                      context: context,
                      style: AlertStyle(backgroundColor: AppColor.main50, titleStyle: const TextStyle(color: Colors.white)),
                      title: AppTranslationConstants.addNewItemlist.tr,
                      content: Column(
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
                              decoration: InputDecoration(
                                labelText: AppTranslationConstants.description.tr,
                              ),
                            ),
                          ]),
                      buttons: [
                        DialogButton(
                          height: 50,
                          color: AppColor.bondiBlue75,
                          onPressed: () async => {
                            await _.createItemlist(),
                          },
                          child: Text(
                            AppTranslationConstants.add.tr,
                          ),
                        ),
                      ]
                  ).show()
                }),
                AppTheme.heightSpace20,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _.outOfSync ? Column(
                      children: [
                        SizedBox(
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            child: AnimatedTextKit(
                              repeatForever: true,
                              animatedTexts: [
                                FlickerAnimatedText("${AppTranslationConstants.suggestedReading.tr}  "),
                              ],
                              onTap: () {
                                Get.toNamed(AppRouteConstants.PDFViewer,
                                    arguments: ["https://www.escritoresmxi.org/wp-content/uploads/2022/09/Insignificante-Flipbok.pdf", 0, 150]);
                              },
                            ),
                          ),
                        ),
                      ],
                    ) : Container(),
                    FloatingActionButton(
                      heroTag: AppPageIdConstants.spotifySync,
                      elevation: AppTheme.elevationFAB,
                      tooltip: AppTranslationConstants.createItemlist.tr,
                      child: const Icon(FontAwesomeIcons.bookOpenReader),
                      onPressed: () => {
                        Get.toNamed(AppRouteConstants.PDFViewer,
                        arguments: ["https://www.escritoresmxi.org/wp-content/uploads/2022/09/Insignificante-Flipbok.pdf", 0, 150])
                      },
                    ),
                  ],
                )
              ]
          )
        )
      )
    );
  }
}
