import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/spotify_search_type.dart';
import 'spotify_search_controller.dart';

class PlaylistItemsPage extends StatelessWidget {
  const PlaylistItemsPage({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GetBuilder<SpotifySearchController>(
      id: AppPageIdConstants.playlistSong,
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: _.itemlist.name.length > AppConstants.maxItemlistNameLength
            ? "${_.itemlist.name.substring(0,AppConstants.maxItemlistNameLength)}..."
            : _.itemlist.name),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: Container() //Obx(()=> buildSpotifySongList(context, _)),
        ),
        floatingActionButton: _.addedItems.isNotEmpty ?
          FloatingActionButton(
          tooltip: AppTranslationConstants.addItem.tr,
          onPressed: ()=>{
            Get.toNamed(AppRouteConstants.playlistNameDesc,
                arguments: [SpotifySearchType.song, _.itemlist])
          },
          child: const Icon(Icons.navigate_next),
        ) : Container(),
      ),
    );
  }
}
