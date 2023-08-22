import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'spotify_search_controller.dart';


class AppBarSpotifySearch extends StatelessWidget implements PreferredSizeWidget {

  final SpotifySearchController spotifySearchController;
  const AppBarSpotifySearch(this.spotifySearchController, {Key? key}) : super(key: key);
  
  @override
  Size get preferredSize => AppTheme.appBarHeight;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: spotifySearchController.searchParamController,
        maxLines: 1,
        onChanged: (param) async => {await spotifySearchController.setSearchParam(param.trim())},
        decoration: InputDecoration(
          suffixIcon: const Icon(CupertinoIcons.search),
          contentPadding: const EdgeInsets.all(10),
          hintText: AppTranslationConstants.searchOnGigmeoutAndSpotify.tr,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
        ),
      ),
      backgroundColor: AppColor.appBar,
      elevation: 5,
    );
  }

}
