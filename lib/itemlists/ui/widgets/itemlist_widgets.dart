import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../itemlist_controller.dart';

Widget buildItemlistList(BuildContext context, ItemlistController _) {
  return ListView.separated(
    separatorBuilder: (context, index) => const Divider(),
    itemCount: _.itemlists.length,
    shrinkWrap: true,
    itemBuilder: (context, index) {
      Itemlist itemlist = _.itemlists.values.elementAt(index);
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
                : CachedNetworkImage(imageUrl: AppFlavour.getAppLogoUrl())
        ),
        title: Row(
            children: <Widget>[
              Text(CoreUtilities.capitalizeFirstLetter(itemlist.name.length > AppConstants.maxItemlistNameLength
                  ? "${itemlist.name.substring(0,AppConstants.maxItemlistNameLength)}..."
                  : itemlist.name)),
              ///DEPRECATE .isFav ? const Icon(Icons.favorite, size: 10,) : SizedBox.shrink()
            ]),
        subtitle: itemlist.description.isNotEmpty ? Text(CoreUtilities.capitalizeFirstLetter(itemlist.description), maxLines: 3, overflow: TextOverflow.ellipsis,) : null,
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
            // await _.gotoItemlistItems(itemlist);

            if(AppFlavour.appInUse == AppInUse.c || !itemlist.isModifiable) {
              await _.gotoItemlistItems(itemlist);
            } else {
              Get.toNamed(AppRouteConstants.itemSearch,
                  arguments: [MediaSearchType.song, itemlist]
              );
            }
          },
        ),
        onTap: () async {
          await _.gotoItemlistItems(itemlist);
        },
        onLongPress: () async {
          (await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
            backgroundColor: AppColor.main75,
            title: Text(AppTranslationConstants.itemlistName.tr,),
            content: SizedBox(
              height: AppTheme.fullHeight(context)*0.25,
              child: Obx(()=> _.isLoading.value ? const Center(child: CircularProgressIndicator())
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextField(
                      controller: _.newItemlistNameController,
                      decoration: InputDecoration(
                        labelText: '${AppTranslationConstants.changeName.tr}: ',
                        hintText: itemlist.name,
                      ),
                    ),
                    TextField(
                      controller: _.newItemlistDescController,
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
                  await _.updateItemlist(itemlist.id, itemlist);
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
                  if(_.itemlists.length == 1) {
                    AppUtilities.showAlert(context,
                        title: AppTranslationConstants.itemlistPrefs.tr,
                        message: AppTranslationConstants.cantRemoveMainItemlist.tr);
                  } else {
                    await _.deleteItemlist(itemlist);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
          )) ?? false;

          ///DEPRECATED
          // Alert(
          //     context: context,
          //     title: AppTranslationConstants.itemlistName.tr,
          //     style: AlertStyle(
          //         backgroundColor: AppColor.main50,
          //         titleStyle: const TextStyle(color: Colors.white)
          //     ),
          //     content: Obx(()=> _.isLoading.value ? const Center(child: CircularProgressIndicator())
          //     : Column(
          //         children: <Widget>[
          //           TextField(
          //             controller: _.newItemlistNameController,
          //             decoration: InputDecoration(
          //               labelText: '${AppTranslationConstants.changeName.tr}: ',
          //               hintText: itemlist.name,
          //             ),
          //           ),
          //           TextField(
          //             controller: _.newItemlistDescController,
          //             decoration: InputDecoration(
          //               labelText: '${AppTranslationConstants.changeDesc.tr}: ',
          //               hintText: itemlist.description,
          //             ),
          //           ),
          //         ]),
          //     ),
          //     buttons: [
          //       DialogButton(
          //         color: AppColor.bondiBlue75,
          //         onPressed: () async {
          //           // Navigator.of(context).pop();
          //           await _.updateItemlist(itemlist.id, itemlist);
          //           // Get.back();
          //           // Get.toNamed(AppRouteConstants.musicPlayerHome);
          //         },
          //         child: Text(
          //           AppTranslationConstants.update.tr,
          //           style: const TextStyle(fontSize: 12),
          //         ),
          //       ),
          //       DialogButton(
          //         color: AppColor.bondiBlue75,
          //         child: Text(AppTranslationConstants.remove.tr),
          //         onPressed: () async {
          //           if(_.itemlists.length == 1) {
          //             AppUtilities.showAlert(context,
          //                 title: AppTranslationConstants.itemlistPrefs.tr,
          //                 message: AppTranslationConstants.cantRemoveMainItemlist.tr);
          //           } else {
          //             // Navigator.of(context).pop();
          //             await _.deleteItemlist(itemlist);
          //             AppUtilities.showAlert(context,
          //                 title: AppTranslationConstants.itemlistPrefs.tr,
          //                 message: AppTranslationConstants.itemlistRemoved.tr);
          //             // Get.back();
          //             // Get.toNamed(AppRouteConstants.musicPlayerHome);
          //           }
          //         },
          //       ),
          //       ///VERIFY IF DEPRECATED
          //       // if(!itemlist.isFav) DialogButton(
          //       //   color: AppColor.bondiBlue75,
          //       //   onPressed: () => {
          //       //     _.setAsFavorite(itemlist)
          //       //   },
          //       //   child: Text(AppTranslationConstants.setFav.tr,
          //       //   ),
          //       // ),
          //     ]
          // ).show();
        },
      );
    },
  );
}
