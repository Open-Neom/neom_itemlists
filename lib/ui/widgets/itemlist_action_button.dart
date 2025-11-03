
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';

class ItemlistActionButton extends StatelessWidget {
  const ItemlistActionButton({
    super.key,
    required this.itemlistType,
    this.ownerType,
  });

  final ItemlistType? itemlistType;
  final OwnerType? ownerType;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            itemlistType == ItemlistType.readlist ?
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    child: AnimatedTextKit(
                      repeatForever: true,
                      animatedTexts: [
                        FlickerAnimatedText(AppFlavour.getSuggestedItemText())
                      ],
                      onTap: () => AppFlavour.gotoSuggestedItem(),
                    ),
                  ),
                ),
                AppTheme.widthSpace5,
                FloatingActionButton(
                  elevation: AppTheme.elevationFAB,
                  child: Icon(AppFlavour.getSyncIcon()),
                  onPressed: () => AppFlavour.gotoSuggestedItem(),
                ),
              ],
            ) : const SizedBox.shrink(),
            if(ownerType == OwnerType.profile && AppConfig.instance.appInUse == AppInUse.g) AppTheme.heightSpace75,
          ]
      ),);
  }
}
