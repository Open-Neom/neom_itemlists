import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/url_constants.dart';
import 'package:neom_commons/core/utils/enums/spotify_search_type.dart';
import '../itemlist_controller.dart';

Widget buildItemlistList(BuildContext context, ItemlistController _) {
  return ListView.separated(
    separatorBuilder: (context, index) => const Divider(),
    itemCount: _.itemlists.length,
    itemBuilder: (context, index) {
      Itemlist itemlist = _.itemlists.values.elementAt(index);
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: SizedBox(
            width: 50,
            child: itemlist.imgUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: itemlist.imgUrl)
                : (itemlist.appItems?.isNotEmpty ?? false)
                ? (itemlist.appItems!.first.albumImgUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: itemlist.appItems!.first.albumImgUrl)
                : CachedNetworkImage(imageUrl: UrlConstants.noImageUrl))
                : Container()
        ),
        title: Row(
            children: <Widget>[
              Text(itemlist.name.length > AppConstants.maxItemlistNameLength
                  ? "${itemlist.name.substring(0,AppConstants.maxItemlistNameLength).capitalizeFirst!}..."
                  : itemlist.name.capitalizeFirst!),
              itemlist.isFav
                  ? const Icon(Icons.favorite, size: 10,)
                  : Container()]),
        subtitle: Text(itemlist.description.capitalizeFirst!),
        trailing: ActionChip(
          labelPadding: EdgeInsets.zero,
          backgroundColor: AppColor.main25,
          avatar: CircleAvatar(
            backgroundColor: AppColor.white80,
            child: Text(itemlist.appItems!.length.toString()),
          ),
          label: Icon(Icons.book, color: AppColor.white80),
          onPressed: () {
            Get.toNamed(AppRouteConstants.itemSearch,
                arguments: [SpotifySearchType.song, itemlist]);
            },
        ),
        onTap: () async {
          await _.gotoItemlistItems(itemlist);
        },
        onLongPress: () {
          Alert(
              context: context,
              title: AppTranslationConstants.itemlistName.tr,
              style: AlertStyle(
                  backgroundColor: AppColor.main50,
                  titleStyle: const TextStyle(color: Colors.white)
              ),
              content: Obx(()=> _.isLoading ? const Center(child: CircularProgressIndicator())
              : Column(
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
                      decoration: InputDecoration(
                        labelText: '${AppTranslationConstants.changeDesc.tr}: ',
                        hintText: itemlist.description,
                      ),
                    ),
                  ]),
              ),
              buttons: [
                DialogButton(
                  color: AppColor.bondiBlue75,
                  onPressed: () => {
                    _.updateItemlist(itemlist.id, itemlist)
                  },
                  child: Text(
                    AppTranslationConstants.update.tr,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DialogButton(
                  color: AppColor.bondiBlue75,
                  child: Text(AppTranslationConstants.remove.tr),
                  onPressed: () async => {
                    itemlist.isFav ?
                    AppUtilities.showAlert(context,
                        AppTranslationConstants.itemlistPrefs.tr,
                        AppTranslationConstants.cantRemoveMainItemlist.tr)
                        : await _.deleteItemlist(itemlist)
                  },
                ),
                if(!itemlist.isFav) DialogButton(
                  color: AppColor.bondiBlue75,
                  onPressed: () => {
                    _.setAsFavorite(itemlist)
                  },
                  child: Text(AppTranslationConstants.setFav.tr,
                  ),
                ),
              ]
          ).show();
        },
      );
    },
  );
}
