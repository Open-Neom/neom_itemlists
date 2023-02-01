import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_item_state.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';
import '../app_item/app_item_controller.dart';
import '../search/spotify_search_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget buildItemList(BuildContext context, AppItemController _) {
  return ListView.separated(
    separatorBuilder: (context, index) => const Divider(),
    itemCount: _.itemlistItems.length,
    itemBuilder: (context, index) {
      AppItem appItem = _.itemlistItems.values.elementAt(index);
      return GestureDetector(
          child: ListTile(
            title: Text(appItem.name.isEmpty ? ""
                : appItem.name.length > AppConstants.maxAppItemNameLength
                ? "${appItem.name.substring(0,AppConstants.maxAppItemNameLength)}..."
                : appItem.name),
            subtitle: Row(children: [Text(appItem.artist.isEmpty ? ""
                : appItem.artist.length > AppConstants.maxArtistNameLength
                ? "${appItem.artist.substring(0,AppConstants.maxArtistNameLength)}..."
                : appItem.artist),
              const SizedBox(width:5),
              (_.userController.profile.type == ProfileType.instrumentist && !_.isFixed) ?
              RatingBar(
                initialRating: appItem.state.toDouble(),
                minRating: 1,
                ignoreGestures: true,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                ratingWidget: RatingWidget(
                  full: CoreUtilities.ratingImage(AppAssets.heart),
                  half: CoreUtilities.ratingImage(AppAssets.heartHalf),
                  empty: CoreUtilities.ratingImage(AppAssets.heartBorder),
                ),
                itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
                itemSize: 15,
                onRatingUpdate: (rating) {
                  _.logger.i("New Rating set to $rating");
                },
              ) : Container(),
            ]),
            onTap: () => _.isFixed ? {} : _.getItemlistItemDetails(appItem),
            leading: Hero(
              tag: CoreUtilities.getAppItemHeroTag(index),
              child: Image.network(
                  appItem.albumImgUrl.isNotEmpty ? appItem.albumImgUrl
                      : appItem.artistImgUrl.isNotEmpty ? appItem.artistImgUrl
                      : AppFlavour.getNoImageUrl()
              ),
            ),
          ),
          onLongPress: () => _.isFixed ? {} : Alert(
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
                                appItemState.value == 0 ? Container() : const Text(" - "),
                                appItemState.value == 0 ? Container() :
                                  RatingBar(
                                    initialRating: appItemState.value.toDouble(),
                                    minRating: 1,
                                    ignoreGestures: true,
                                    direction: Axis.horizontal,
                                    allowHalfRating: false,
                                    itemCount: 5,
                                    ratingWidget: RatingWidget(
                                      full: CoreUtilities.ratingImage(AppAssets.heart),
                                      half: CoreUtilities.ratingImage(AppAssets.heartHalf),
                                      empty: CoreUtilities.ratingImage(AppAssets.heartBorder),
                                    ),
                                    itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
                                    itemSize: 12,
                                    onRatingUpdate: (rating) {
                                      _.logger.i("New Rating set to $rating");
                                    },
                                  ),
                                ],
                              )
                        );
                      }).toList(),
                      onChanged: (String? newItemState) {
                        _.setItemState(EnumToString.fromString(AppItemState.values, newItemState!) ?? AppItemState.noState);
                      },
                      value: CoreUtilities.getItemState(_.itemState).name,
                      icon: const Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
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
                    _.updateItemlistItem(appItem)
                  },
                ),
                DialogButton(
                  color: AppColor.bondiBlue75,
                  child: Text(AppTranslationConstants.remove.tr,
                    style: const TextStyle(fontSize: 15),
                  ),
                  onPressed: () async => {
                    await _.removeItemFromList(appItem)
                  },
                ),
              ]
          ).show()
      );
    },
  );
}

Widget buildItemSearchList(BuildContext context, SpotifySearchController _) {
  return ListView.builder(
    padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
    itemCount: _.appItems.length,
    itemBuilder: (context, index) {
      AppItem appItem = _.appItems.values.elementAt(index);
      return ListTile(
        contentPadding: const EdgeInsets.all(10.0),
        title: Text(appItem.name),
        subtitle: Text(appItem.artist),
        onTap: () => _.getAppItemDetails(appItem),
        leading: Hero(
          tag: CoreUtilities.getAppItemHeroTag(index),
          child: Image.network(appItem.albumImgUrl.isNotEmpty
              ? appItem.albumImgUrl : AppFlavour.getNoImageUrl(),
              width: 56.0
          ),
        ),
      );
    },
  );
}

Widget buildSpotifySongList(BuildContext context, SpotifySearchController _) {
  return ListView.separated(
    separatorBuilder: (context, index) => const Divider(),
    itemCount: _.appItems.length,
    itemBuilder: (context, index) {
      AppItem song = _.appItems.values.elementAt(index);
      return ListTile(
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
        onLongPress: () => _.getAppItemDetails(song),
        leading: Image.network(
            song.albumImgUrl.isNotEmpty ? song.albumImgUrl
                : song.artistImgUrl.isNotEmpty ? song.artistImgUrl
                : AppFlavour.getNoImageUrl()
        ),
      );
    },
  );
}
