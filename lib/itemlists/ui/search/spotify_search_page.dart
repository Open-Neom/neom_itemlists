import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/spotify_search_type.dart';
import '../widgets/app_item_widgets.dart';
import 'appbar_spotify_search.dart';
import 'spotify_search_controller.dart';

class SpotifySearchPage extends StatelessWidget {
  const SpotifySearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SpotifySearchController>(
        id: AppPageIdConstants.spotifySearch,
        init: SpotifySearchController(),
        builder: (_) => Scaffold(
          appBar: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: AppBarSpotifySearch(_)),
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: _.isLoading ? const Center(child: CircularProgressIndicator())
            : Obx(()=>
                  _.spotifySearchType == SpotifySearchType.song ?
                  buildItemSearchList(context, _)
                    : buildItemSearchList(context, _) //TODO Verify if needed
            )
          ),
        )
    );
  }
}
