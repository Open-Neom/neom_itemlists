import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
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
                : CachedNetworkImage(imageUrl: AppFlavour.getNoImageUrl()))
                : CachedNetworkImage(imageUrl: AppFlavour.getAppLogoUrl())
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

Widget buildSyncPlaylistList(BuildContext context, ItemlistController _) {
  return ListView.separated(
    separatorBuilder: (context, index) => const Divider(),
    itemCount: _.spotifyItemlists.length,
    itemBuilder: (context, index) {
      Itemlist  spotifyGiglist = _.spotifyItemlists.values.elementAt(index);
      return ListTile(
          title: Text((spotifyGiglist.name.isEmpty) ? ""
              : spotifyGiglist.name.length > AppConstants.maxAppItemNameLength
              ? "${spotifyGiglist.name.substring(0,AppConstants.maxAppItemNameLength)}..."
              : spotifyGiglist.name),
          subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text((spotifyGiglist.description.isEmpty) ? ""
                      : spotifyGiglist.description.length > AppConstants.maxArtistNameLength
                      ? "${spotifyGiglist.description.substring(0,AppConstants.maxArtistNameLength)}..."
                      : spotifyGiglist.description),
                ),
                AppTheme.widthSpace5,
              ]),
          trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Chip(
                  backgroundColor: AppColor.main50,
                  avatar: CircleAvatar(
                    backgroundColor: AppColor.white80,
                    child: Obx(()=>_.isLoading && _.currentItemlist.href == spotifyGiglist.href
                        ? const Center(child: CircularProgressIndicator())
                        : Text(("${(spotifyGiglist.appItems?.isEmpty ?? true)
                        ? _.spotifyPlaylistSimples.where((element) => element.id == spotifyGiglist.id).first.tracksLink?.total
                        : spotifyGiglist.appItems?.length ?? 0
                    }")
                    ),
                    ),
                  ),
                  label: Icon(Icons.music_note, color: AppColor.white80),
                  labelPadding: const EdgeInsets.all(5),
                ),
              ]
          ),
          tileColor: _.addedItemlists.contains(spotifyGiglist) ? AppColor.getMain() : Colors.transparent,
          onTap: () => {
            _.handlePlaylistList(spotifyGiglist),
          },
          onLongPress: () => {
            _.gotoPlaylistSongs(spotifyGiglist)
          },
          leading: Image.network(
            spotifyGiglist.imgUrl.isNotEmpty
                ? spotifyGiglist.imgUrl
                : AppFlavour.getNoImageUrl(),
            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
              return Image.network(AppFlavour.getNoImageUrl());
            },
          )
      );
    },
  );
}

Widget buildSyncPlaylistsButton(BuildContext context, ItemlistController _) {
  return Center(
    child: SizedBox(
      width: AppTheme.fullWidth(context) * 0.5,
      height: AppTheme.fullHeight(context) * 0.06,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: AppColor.bondiBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onPressed: () async {
          if(!_.isButtonDisabled) await _.synchronizeGiglists();
        },
        child: Obx(()=>_.isLoading ? const Center(child: CircularProgressIndicator())
            : Text(AppTranslationConstants.synchronizePlaylists.tr,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15
          ),
        ),
        ),
      ),
    ),
  );
}