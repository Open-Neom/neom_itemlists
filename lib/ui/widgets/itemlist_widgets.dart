import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_commons/ui/widgets/rating_heart_bar.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/mappers/base_item_mapper.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/base_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/itemlist_translation_constants.dart';
import '../../utils/itemlist_utilities.dart';
import '../itemlist_controller.dart';
import '../itemlist_items_controller.dart';

Widget buildItemlistList(BuildContext context, ItemlistController controller, {VoidCallback? onCreateNew}) {
  if (controller.itemlists.isEmpty) {
    return _buildEmptyListState(context, onCreateNew: onCreateNew);
  }

  return ListView.separated(
    separatorBuilder: (context, index) => const Divider(height: 1),
    itemCount: controller.itemlists.length,
    shrinkWrap: true,
    itemBuilder: (context, index) {
      Itemlist itemlist = controller.itemlists.values.elementAt(index);
      return itemlist.type == controller.itemlistType ? ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: SizedBox(
          width: 50, height: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: HandledCachedNetworkImage(
              itemlist.getImgUrls().isNotEmpty
                ? itemlist.getImgUrls().first
                : AppProperties.getAppLogoUrl(),
              enableFullScreen: false,
            ),
          ),
        ),
        title: Text(
          TextUtilities.capitalizeFirstLetter(
            itemlist.name.length > AppConstants.maxItemlistNameLength
              ? "${itemlist.name.substring(0,AppConstants.maxItemlistNameLength)}..."
              : itemlist.name,
          ),
          style: TextStyle(color: AppColor.textPrimary, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            Text(
              '${itemlist.allItems.length} items',
              style: TextStyle(color: AppColor.textSecondary, fontSize: 12),
            ),
            if (itemlist.description.isNotEmpty) ...[
              Text(' \u00B7 ', style: TextStyle(color: AppColor.textSecondary, fontSize: 12)),
              Expanded(
                child: Text(
                  TextUtilities.capitalizeFirstLetter(itemlist.description),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColor.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColor.textSecondary, size: 20),
          color: AppColor.surfaceElevated,
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 18, color: AppColor.textPrimary),
                const SizedBox(width: 8),
                Text(AppTranslationConstants.update.tr, style: TextStyle(color: AppColor.textPrimary)),
              ]),
            ),
            PopupMenuItem(
              value: 'search',
              child: Row(children: [
                Icon(Icons.add, size: 18, color: AppColor.textPrimary),
                const SizedBox(width: 8),
                Text(ItemlistTranslationConstants.addItems.tr, style: TextStyle(color: AppColor.textPrimary)),
              ]),
            ),
            if (controller.itemlists.length > 1)
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outlined, size: 18, color: AppColor.red),
                  const SizedBox(width: 8),
                  Text(AppTranslationConstants.remove.tr, style: const TextStyle(color: AppColor.red)),
                ]),
              ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditItemlistDialog(context, controller, itemlist);
                break;
              case 'search':
                Sint.toNamed(AppRouteConstants.itemSearch,
                    arguments: [ItemlistUtilities.getMediaSearchType(itemlist.type), itemlist]);
                break;
              case 'delete':
                _showDeleteConfirmation(context, controller, itemlist);
                break;
            }
          },
        ),
        onTap: () => Sint.toNamed(AppRouteConstants.listItems, arguments: [itemlist]),
      ) : const SizedBox.shrink();
    },
  );
}

Widget buildItemListItems(BuildContext context, ItemlistItemsController controller) {
  if (controller.itemlist.allItems.isEmpty) {
    return _buildEmptyItemsState(context);
  }

  final isModifiable = controller.itemlist.isModifiable && !controller.isFixed;

  return ListView.separated(
    separatorBuilder: (context, index) => const Divider(height: 1),
    itemCount: controller.itemlist.allItems.length,
    itemBuilder: (context, index) {
      dynamic item = controller.itemlist.allItems.elementAt(index);
      BaseItem baseItem = BaseItemMapper.fromDynamicItem(item);

      final tile = ListTile(
        leading: SizedBox(
          width: 44, height: 44,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: HandledCachedNetworkImage(
              baseItem.imgUrl.isNotEmpty ? baseItem.imgUrl : controller.itemlist.imgUrl,
              enableFullScreen: false, width: 44,
            ),
          ),
        ),
        title: Text(
          TextUtilities.getMediaName(baseItem.name),
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColor.textPrimary, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                baseItem.ownerName,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColor.textSecondary, fontSize: 12),
              ),
            ),
            if ((AppConfig.instance.appInUse == AppInUse.c || controller.userServiceImpl.profile.type == ProfileType.appArtist)
                && baseItem.state > 0)
              RatingHeartBar(state: baseItem.state.toDouble()),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.arrow_forward_ios, size: 16, color: AppColor.textSecondary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => AppUtilities.gotoItemDetails(item),
        ),
        onTap: () => AppConfig.instance.appInUse == AppInUse.c || !controller.isFixed
            ? controller.getItemlistItemDetails(baseItem.id) : {},
        onLongPress: isModifiable && controller.userServiceImpl.profile.type == ProfileType.appArtist
            ? () => _showItemStateDialog(context, controller, item)
            : null,
      );

      if (!isModifiable) return tile;

      return Dismissible(
        key: Key(baseItem.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red.shade700,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColor.surfaceElevated,
              title: Text(AppTranslationConstants.remove.tr, style: TextStyle(color: AppColor.textPrimary)),
              content: Text(
                '${AppTranslationConstants.remove.tr} "${baseItem.name}"?',
                style: TextStyle(color: AppColor.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(AppTranslationConstants.cancel.tr),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(AppTranslationConstants.remove.tr, style: const TextStyle(color: AppColor.red)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await controller.removeItemFromList(baseItem.id);
            return true;
          }
          return false;
        },
        child: tile,
      );
    },
  );
}

// ---------- Private helpers ----------

Widget _buildEmptyListState(BuildContext context, {VoidCallback? onCreateNew}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppFlavour.getAppItemIcon(), size: 64, color: AppColor.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 15),
          Text(
            ItemlistTranslationConstants.noItemlistsMsg.tr,
            style: TextStyle(color: AppColor.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            ItemlistTranslationConstants.noItemlistsMsg2.tr,
            style: TextStyle(color: AppColor.textSecondary.withValues(alpha: 0.7), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (onCreateNew != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Icons.add),
              label: Text(ItemlistTranslationConstants.createItemlist.tr),
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.getMain(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildEmptyItemsState(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppFlavour.getAppItemIcon(), size: 64, color: AppColor.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 15),
          Text(
            ItemlistTranslationConstants.noItemsYet.tr,
            style: TextStyle(color: AppColor.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            ItemlistTranslationConstants.tapToAddItems.tr,
            style: TextStyle(color: AppColor.textSecondary.withValues(alpha: 0.7), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

void _showEditItemlistDialog(BuildContext context, ItemlistController controller, Itemlist itemlist) {
  controller.newItemlistNameController.text = itemlist.name;
  controller.newItemlistDescController.text = itemlist.description;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColor.surfaceElevated,
      title: Text(CommonTranslationConstants.itemlistName.tr, style: TextStyle(color: AppColor.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller.newItemlistNameController,
            decoration: InputDecoration(labelText: AppTranslationConstants.changeName.tr),
            style: TextStyle(color: AppColor.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.newItemlistDescController,
            minLines: 2, maxLines: 5,
            decoration: InputDecoration(labelText: AppTranslationConstants.changeDesc.tr),
            style: TextStyle(color: AppColor.textPrimary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppTranslationConstants.cancel.tr),
        ),
        FilledButton(
          onPressed: () => AuthGuard.protect(ctx, () async {
            await controller.updateItemlist(itemlist.id, itemlist);
            Navigator.pop(ctx);
          }),
          style: FilledButton.styleFrom(backgroundColor: AppColor.getMain()),
          child: Text(AppTranslationConstants.update.tr),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmation(BuildContext context, ItemlistController controller, Itemlist itemlist) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColor.surfaceElevated,
      title: Text(AppTranslationConstants.remove.tr, style: TextStyle(color: AppColor.textPrimary)),
      content: Text(
        '${AppTranslationConstants.remove.tr} "${itemlist.name}"?',
        style: TextStyle(color: AppColor.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppTranslationConstants.cancel.tr),
        ),
        TextButton(
          onPressed: () => AuthGuard.protect(ctx, () async {
            await controller.deleteItemlist(itemlist);
            Navigator.pop(ctx);
          }),
          child: Text(AppTranslationConstants.remove.tr, style: const TextStyle(color: AppColor.red)),
        ),
      ],
    ),
  );
}

void _showItemStateDialog(BuildContext context, ItemlistItemsController controller, dynamic item) {
  Alert(
    context: context,
    title: CommonTranslationConstants.appItemPrefs.tr,
    style: AlertStyle(
      backgroundColor: AppColor.scaffold,
      titleStyle: const TextStyle(color: Colors.white),
    ),
    content: Column(
      children: <Widget>[
        Obx(() => DropdownButton<String>(
          items: AppItemState.values.map((AppItemState appItemState) {
            return DropdownMenuItem<String>(
              value: appItemState.name,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(appItemState.name.tr),
                  appItemState.value == 0 ? const SizedBox.shrink() : const Text(" - "),
                  appItemState.value == 0 ? const SizedBox.shrink() :
                  RatingHeartBar(state: appItemState.value.toDouble()),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newItemState) {
            controller.setItemState(EnumToString.fromString(AppItemState.values, newItemState!) ?? AppItemState.noState);
          },
          value: CoreUtilities.getItemState(controller.itemState.value).name,
          icon: const Icon(Icons.arrow_downward),
          iconSize: 15,
          elevation: 15,
          style: const TextStyle(color: Colors.white),
          dropdownColor: AppColor.getMain(),
          underline: Container(height: 1, color: Colors.grey),
        )),
      ],
    ),
    buttons: [
      DialogButton(
        color: AppColor.bondiBlue75,
        child: Text(AppTranslationConstants.update.tr, style: const TextStyle(fontSize: 15)),
        onPressed: () => AuthGuard.protect(context, () => controller.updateItemlistItem(item)),
      ),
    ],
  ).show();
}
