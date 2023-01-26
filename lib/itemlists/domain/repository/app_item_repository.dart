import 'dart:async';
import 'package:neom_commons/core/domain/model/app_item.dart';

abstract class AppItemRepository {

  Future<AppItem> retrieve(String itemId);
  Future<Map<String, AppItem>> retrieveFromList(List<String> itemIds);

  Future<bool> exists(String itemId);
  Future<void> existsOrInsert(AppItem item);

  Future<void> insert(AppItem item);
  Future<bool> remove(AppItem item);

  Future<bool> removeItemFromList(String profileId, String itemlistId, AppItem appItem);
}
