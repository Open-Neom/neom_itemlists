import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_audio_player/data/implementations/app_hive_controller.dart';
import 'package:neom_audio_player/ui/player/media_player_controller.dart';
import 'package:neom_audio_player/ui/widgets/download_button.dart';
import 'package:neom_audio_player/ui/widgets/go_spotify_button.dart';
import 'package:neom_audio_player/ui/widgets/like_button.dart';
import 'package:neom_audio_player/ui/widgets/song_tile_trailing_menu.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/ui/widgets/handled_cached_network_image.dart';
import 'package:neom_commons/core/ui/widgets/neom_image_card.dart';
import 'package:neom_commons/core/ui/widgets/rating_heart_bar.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../app_media_item/app_media_item_controller.dart';
import '../search/app_media_item_search_controller.dart';

Widget buildItemList(BuildContext context, AppMediaItemController _) {
  return ListView.separated(
    separatorBuilder: (context, index) => const Divider(),
    itemCount: _.itemlistItems.length,
    itemBuilder: (context, index) {
      AppMediaItem appMediaItem = _.itemlistItems.values.elementAt(index);
      return ListTile(
          leading: HandledCachedNetworkImage(appMediaItem.imgUrl.isNotEmpty
              ? appMediaItem.imgUrl : _.itemlist.imgUrl, enableFullScreen: false,
            width: 40,
          ),
          title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: AppTheme.fullWidth(context)*0.4,
                  child: Text(appMediaItem.name, maxLines: 5, overflow: TextOverflow.ellipsis,),
                ),
                (AppFlavour.appInUse == AppInUse.c || (_.userController.profile.type == ProfileType.artist && !_.isFixed)) ?
                RatingHeartBar(state: appMediaItem.state.toDouble()) : const SizedBox.shrink(),
              ]
          ),
          subtitle: SizedBox(
            width: AppTheme.fullWidth(context)*0.4,
            child: (AppFlavour.appInUse == AppInUse.c && (appMediaItem.description?.isNotEmpty ?? false)) ?
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
                Get.toNamed(AppFlavour.getItemDetailsRoute(), arguments: [appMediaItem]);
              }
          ),
          onTap: () => AppFlavour.appInUse == AppInUse.c || !_.isFixed ? _.getItemlistItemDetails(appMediaItem) : {},
          onLongPress: () => _.itemlist.isModifiable && (AppFlavour.appInUse != AppInUse.c || !_.isFixed) ? Alert(
              context: context,
              title: AppTranslationConstants.appItemPrefs.tr,
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
                          _.setItemState(EnumToString.fromString(AppItemState.values, newItemState!) ?? AppItemState.noState);
                        },
                        value: CoreUtilities.getItemState(_.itemState.value).name,
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
                    _.updateItemlistItem(appMediaItem)
                  },
                ),
                DialogButton(
                  color: AppColor.bondiBlue75,
                  child: Text(AppTranslationConstants.remove.tr,
                    style: const TextStyle(fontSize: 15),
                  ),
                  onPressed: () async => {
                    await _.removeItemFromList(appMediaItem)
                  },
                ),
              ]
          ).show() : {}
      );
    },
  );
}

ListTile createCoolMediaItemTile(BuildContext context, AppMediaItem appMediaItem,
    {Itemlist? itemlist, String query = '', AppMediaItemSearchController? searchController, bool downloadAllowed = false}) {
  return ListTile(
    contentPadding: const EdgeInsets.only(left: 15.0,),
    title: Text(appMediaItem.name,
      style: const TextStyle(fontWeight: FontWeight.w500,),
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(appMediaItem.artist,
      overflow: TextOverflow.ellipsis,
    ),
    isThreeLine: false,
    leading: NeomImageCard(
      placeholderImage: const AssetImage(AppAssets.audioPlayerCover),
      imageUrl: appMediaItem.imgUrl
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LikeButton(appMediaItem: appMediaItem,),
        appMediaItem.mediaSource == AppMediaSource.internal
            ? (downloadAllowed ? DownloadButton(mediaItem: appMediaItem,) : const SizedBox.shrink())
            : (appMediaItem.mediaSource == AppMediaSource.spotify ? GoSpotifyButton(appMediaItem: appMediaItem, size: 22) : const SizedBox.shrink()),
        SongTileTrailingMenu(
          appMediaItem: appMediaItem,
          itemlist: itemlist,
          searchController: searchController,
        ),
      ],
    ),
    onLongPress: () {
      CoreUtilities.copyToClipboard(text: appMediaItem.permaUrl,);
    },
    onTap: () {
      AppHiveController().addQuery(appMediaItem.name);
      if (Get.isRegistered<MediaPlayerController>()) {
        Get.delete<MediaPlayerController>();
        Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);
      } else {
        Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);
      }
    },
  );
}

ListTile createMediaItemTile(BuildContext context, AppMediaItem appMediaItem,
    {Itemlist? itemlist, String query = '', AppMediaItemSearchController? searchController}) {
  return ListTile(
    contentPadding: const EdgeInsets.only(left: 15.0,),
    title: Text(appMediaItem.name,
      style: const TextStyle(fontWeight: FontWeight.w500,),
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(appMediaItem.artist,
      overflow: TextOverflow.ellipsis,
    ),
    isThreeLine: false,
    leading: NeomImageCard(
        placeholderImage: const AssetImage(AppAssets.audioPlayerCover),
        imageUrl: appMediaItem.imgUrl
    ),
    onLongPress: () {
      CoreUtilities.copyToClipboard(text: appMediaItem.permaUrl,);
    },
    onTap: () {
      AppHiveController().addQuery(appMediaItem.name);
      Get.toNamed(AppFlavour.getItemDetailsRoute(), arguments: [appMediaItem]);
    },
  );
}

Widget buildSpotifySongList(BuildContext context, AppMediaItemSearchController _) {
  return ListView.separated(
    separatorBuilder: (context, index) => const Divider(),
    itemCount: _.appMediaItems.length,
    itemBuilder: (context, index) {
      AppMediaItem song = _.appMediaItems.values.elementAt(index);
      return ListTile(
        leading: HandledCachedNetworkImage(song.imgUrl),
        title: Text(song.name.isEmpty ? ""
            : song.name.length > AppConstants.maxAppItemNameLength
            ? "${song.name.substring(0,AppConstants.maxAppItemNameLength)}..."
            : song.name),
        subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(song.artist.isEmpty ? ""
                  : song.artist.length > AppConstants.maxArtistNameLength
                  ? "${song.artist.substring(0,AppConstants.maxArtistNameLength)}..."
                  : song.artist),
              AppTheme.widthSpace5,
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(song.state > 0 ? FontAwesomeIcons.solidHeart
                        : FontAwesomeIcons.heart,
                        size:15),
                    onPressed: () => _.handleItemlistItems(song, AppItemState.heardIt),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(song.state > 1 ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                        size:15),
                    onPressed: () => _.handleItemlistItems(song, AppItemState.learningIt),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(song.state > 2 ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                        size:15),
                    onPressed: () => _.handleItemlistItems(song, AppItemState.needToPractice),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(song.state > 3 ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                        size:15),
                    onPressed: () => _.handleItemlistItems(song, AppItemState.readyToPlay),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(song.state > 4 ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                        size:15),
                    onPressed: () => _.handleItemlistItems(song, AppItemState.knowByHeart),
                  ),
                ],
              )
            ]),
        tileColor: _.addedItems.contains(song) ? AppColor.getMain() : Colors.transparent,
        onTap: () => _.handleItemlistItems(song, AppItemState.heardIt),
        onLongPress: () => _.getAppMediaItemDetails(song),
      );
    },
  );
}
