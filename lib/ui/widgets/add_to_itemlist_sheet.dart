import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/itemlist_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/profile_type.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/itemlist_translation_constants.dart';

/// Shared bottom sheet for adding items to itemlists.
/// Replaces duplicated alert dialogs in neom_audio_player and neom_books.
class AddToItemlistSheet {

  /// Shows a bottom sheet to add an item to a user's itemlist.
  /// For non-artists with a single list, adds directly without showing UI.
  /// [item] should be an AppMediaItem for audio flows.
  /// [onAdd] optional callback for custom add logic (e.g. books use BookDetailController).
  /// Returns true if the item was added.
  static Future<bool> show(
    BuildContext context, {
    required AppMediaItem item,
    required ItemlistType listType,
    Future<bool> Function(String itemlistId, int state)? onAdd,
  }) async {
    try {
      final itemlistService = Sint.find<ItemlistService>();
      final userService = Sint.find<UserService>();
      final isArtist = userService.profile.type == ProfileType.appArtist;

      List<Itemlist> lists = CoreUtilities.filterItemlists(
        itemlistService.getItemlists(), listType,
      );
      lists.removeWhere((l) => !l.isModifiable);

      if (lists.isEmpty) {
        lists.add(await itemlistService.createBasicItemlist());
      }

      // One-tap add: single list + non-artist → add directly
      if (lists.length == 1 && !isArtist) {
        itemlistService.setSelectedItemlist(lists.first.id);
        itemlistService.setAppMediaItem(item);
        if (onAdd != null) {
          return await onAdd(lists.first.id, AppItemState.heardIt.value);
        }
        await itemlistService.addItemlistItem(context, fanItemState: AppItemState.heardIt.value);
        return true;
      }

      // Show bottom sheet for multiple lists or artist
      itemlistService.setSelectedItemlist(lists.first.id);
      itemlistService.setAppMediaItem(item);

      final result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppColor.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        isScrollControlled: true,
        builder: (ctx) => _AddToItemlistSheetBody(
          lists: lists,
          isArtist: isArtist,
          itemlistService: itemlistService,
          item: item,
          onAdd: onAdd,
        ),
      );

      return result ?? false;
    } catch (e) {
      AppConfig.logger.e('AddToItemlistSheet error: $e');
      return false;
    }
  }
}

class _AddToItemlistSheetBody extends StatefulWidget {
  final List<Itemlist> lists;
  final bool isArtist;
  final ItemlistService itemlistService;
  final AppMediaItem item;
  final Future<bool> Function(String itemlistId, int state)? onAdd;

  const _AddToItemlistSheetBody({
    required this.lists,
    required this.isArtist,
    required this.itemlistService,
    required this.item,
    this.onAdd,
  });

  @override
  State<_AddToItemlistSheetBody> createState() => _AddToItemlistSheetBodyState();
}

class _AddToItemlistSheetBodyState extends State<_AddToItemlistSheetBody> {
  late String _selectedListId;
  AppItemState _selectedState = AppItemState.heardIt;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _selectedListId = widget.lists.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColor.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            ItemlistTranslationConstants.addToList.tr,
            style: TextStyle(color: AppColor.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (widget.item.name.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.item.name,
              style: TextStyle(color: AppColor.textSecondary, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),

          // State selector (artists only)
          if (widget.isArtist) ...[
            Text(
              CommonTranslationConstants.appItemPrefs.tr,
              style: TextStyle(color: AppColor.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppItemState>(
              value: _selectedState,
              dropdownColor: AppColor.surfaceCard,
              style: TextStyle(color: AppColor.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColor.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColor.borderMedium),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: AppItemState.values
                  .where((s) => s != AppItemState.noState)
                  .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name.tr),
                  )).toList(),
              onChanged: (v) => setState(() => _selectedState = v ?? AppItemState.heardIt),
            ),
            const SizedBox(height: 16),
          ],

          // List selector
          if (widget.lists.length > 1) ...[
            Text(
              ItemlistTranslationConstants.selectList.tr,
              style: TextStyle(color: AppColor.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ...widget.lists.map((list) => RadioListTile<String>(
              value: list.id,
              groupValue: _selectedListId,
              activeColor: AppColor.getMain(),
              title: Text(
                list.name,
                style: TextStyle(color: AppColor.textPrimary, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                list.description.isNotEmpty
                    ? '${list.allItems.length} items · ${list.description}'
                    : '${list.allItems.length} items',
                style: TextStyle(color: AppColor.textSecondary, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
              onChanged: (v) => setState(() => _selectedListId = v ?? _selectedListId),
            )),
            const SizedBox(height: 8),
          ] else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.playlist_add_check, color: AppColor.getMain()),
              title: Text(
                widget.lists.first.name,
                style: TextStyle(color: AppColor.textPrimary, fontSize: 14),
              ),
              trailing: Text(
                '${widget.lists.first.allItems.length} items',
                style: TextStyle(color: AppColor.textSecondary, fontSize: 12),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Add button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isAdding ? null : _addItem,
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.getMain(),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isAdding
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(AppTranslationConstants.add.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem() async {
    setState(() => _isAdding = true);

    try {
      final state = widget.isArtist ? _selectedState.value : AppItemState.heardIt.value;

      if (widget.onAdd != null) {
        await widget.onAdd!(_selectedListId, state);
      } else {
        widget.itemlistService.setSelectedItemlist(_selectedListId);
        widget.itemlistService.setAppItemState(
          widget.isArtist ? _selectedState : AppItemState.heardIt,
        );
        await widget.itemlistService.addItemlistItem(context, fanItemState: state);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      AppConfig.logger.e('AddToItemlistSheet._addItem error: $e');
      if (mounted) {
        setState(() => _isAdding = false);
        AppUtilities.showSnackBar(message: 'Error adding item');
      }
    }
  }
}
