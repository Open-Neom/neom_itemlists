import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import '../widgets/app_item_widgets.dart';
import 'appbar_item_search.dart';
import 'app_media_item_search_controller.dart';

class AppMediaItemSearchPage extends StatelessWidget {
  const AppMediaItemSearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppMediaItemSearchController>(
        id: AppPageIdConstants.spotifySearch,
        init: AppMediaItemSearchController(),
        builder: (_) => Scaffold(
          appBar: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: AppBarSpotifySearch(_)),
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: _.isLoading ? const Center(child: CircularProgressIndicator())
            : Obx(()=> ListView.builder(
              padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
              itemCount: _.appMediaItems.length,
              itemBuilder: (context, index) {
                AppMediaItem appMediaItem = _.appMediaItems.values.elementAt(index);
                return createCoolMediaItemTile(context, appMediaItem, query: _.searchParam, itemlist: _.itemlist, searchController: _);
              },
            )),
          ),
        )
    );
  }
}
