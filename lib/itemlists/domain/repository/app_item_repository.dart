import 'dart:async';
import 'package:neom_commons/core/domain/model/app_media_item.dart';

abstract class AppItemRepository {

  Future<AppMediaItem> retrieve(String itemId);
  Future<Map<String, AppMediaItem>> retrieveFromList(List<String> itemIds);
  Future<Map<String, AppMediaItem>> fetchAll();
  Future<bool> exists(String itemId);
  Future<void> existsOrInsert(AppMediaItem item);

  Future<void> insert(AppMediaItem item);
  Future<bool> remove(AppMediaItem item);

  Future<bool> removeItemFromList(String profileId, String itemlistId, AppMediaItem appItem);
}
