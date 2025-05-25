import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/implementations/app_hive_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/ui/widgets/neom_image_card.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';

// ListTile createCoolMediaItemTile(BuildContext context, AppMediaItem appMediaItem, {Itemlist? itemlist,
//   String query = '', bool downloadAllowed = false}) {
//
//   bool isInternal = appMediaItem.mediaSource == AppMediaSource.internal || appMediaItem.mediaSource == AppMediaSource.offline;
//
//   return ListTile(
//     contentPadding: const EdgeInsets.only(left: 15.0,),
//     title: Text(appMediaItem.name,
//       style: const TextStyle(fontWeight: FontWeight.w500,),
//       overflow: TextOverflow.ellipsis,
//     ),
//     subtitle: Text(AppUtilities.getArtistName(appMediaItem.artist),
//       overflow: TextOverflow.ellipsis,
//     ),
//     isThreeLine: false,
//     leading: NeomImageCard(
//       placeholderImage: const AssetImage(AppAssets.audioPlayerCover),
//       imageUrl: appMediaItem.imgUrl
//     ),
//     trailing: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         isInternal ? LikeButton(appMediaItem: appMediaItem,)
//             : const SizedBox.shrink(),
//         if(downloadAllowed) DownloadButton(mediaItem: appMediaItem,),
//         isInternal ? SongTileTrailingMenu(
//           appMediaItem: appMediaItem,
//           itemlist: itemlist,
//         ) : AppTheme.widthSpace10,
//       ],
//     ),
//     onLongPress: () {
//       // CoreUtilities.copyToClipboard(text: appMediaItem.permaUrl,);
//       Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);
//     },
//     onTap: () {
//       PlayerHiveController().addQuery(appMediaItem.name);
//
//       if(appMediaItem.mediaSource == AppMediaSource.internal || appMediaItem.mediaSource == AppMediaSource.offline) {
//         if (Get.isRegistered<AudioPlayerController>()) {
//           Get.find<AudioPlayerController>().setMediaItem(appItem: appMediaItem);
//         } else {
//           Get.put(AudioPlayerController()).setMediaItem(appItem: appMediaItem);
//         }
//         NeomPlayerInvoker.updateNowPlaying([MediaItemMapper.fromAppMediaItem(appMediaItem:appMediaItem)], 0);
//       } else {
//         NeomPlayerInvoker.updateNowPlaying([MediaItemMapper.fromAppMediaItem(appMediaItem:appMediaItem)], 0);
//       }
//
//       // Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);
//     },
//   );
// }

ListTile createMediaItemTile(BuildContext context, AppMediaItem appMediaItem,
    {Itemlist? itemlist, String query = ''}) {
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
      Get.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [appMediaItem]);
    },
  );
}
