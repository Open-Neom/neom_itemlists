import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../itemlist_controller.dart';
import '../widgets/itemlist_widgets.dart';

class SpotifyPlaylistsPage extends StatelessWidget {
  const SpotifyPlaylistsPage({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemlistController>(
      id: AppPageIdConstants.playlistSong,
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: "${_.spotifyPlaylistSimples.value.length} Playlists ${AppTranslationConstants.found.tr}"),
        body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: _.addedItemlists.isNotEmpty
                      ? _.itemNumber > 0 ? AppTheme.fullHeight(context) * 0.7 : AppTheme.fullHeight(context) * 0.8
                      : AppTheme.fullHeight(context) * 0.9,
                  child: Obx(()=> buildSyncPlaylistList(context, _)),
                ),
                _.addedItemlists.isNotEmpty ? Obx(()=> _.itemNumber > 0 ?
                Center(
                    child: LinearPercentIndicator(
                      width: AppTheme.fullWidth(context),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      lineHeight: 25.0,
                      percent: _.itemNumber/_.totalItemsToSynch,
                      center: Text("${AppTranslationConstants.adding.tr} "
                          "${_.itemNumber} ${AppTranslationConstants.outOf.tr} "
                          "${_.totalItemsToSynch}"
                      ),
                      progressColor: AppColor.bondiBlue,
                    )
                  ): buildSyncPlaylistsButton(context, _)
                ) : Container(),
                Obx(()=> _.itemName.isNotEmpty
                    ? Text(_.currentItemlist.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ) : Container()),
                Obx(()=> _.itemName.isNotEmpty
                    ? Text(_.itemName.value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ) : Container()),
              ],
            )
        ),
      ),
    );
  }
}
