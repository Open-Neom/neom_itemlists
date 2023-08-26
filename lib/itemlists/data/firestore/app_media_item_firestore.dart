import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_media_source.dart';
import '../../domain/repository/app_item_repository.dart';

class AppMediaItemFirestore implements AppItemRepository {

  var logger = AppUtilities.logger;
  final appMediaItemReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.appMediaItems);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<AppMediaItem> retrieve(String itemId) async {
    logger.d("Getting item $itemId");
    AppMediaItem appMediaItem = AppMediaItem();
    try {
      await appMediaItemReference.doc(itemId).get().then((doc) {
        if (doc.exists) {
          appMediaItem = AppMediaItem.fromJSON(jsonEncode(doc.data()));
          logger.d("AppMediaItem ${appMediaItem.name} was retrieved with details");
        } else {
          logger.d("AppMediaItem not found");
        }
      });
    } catch (e) {
      logger.d(e);
      rethrow;
    }
    return appMediaItem;
  }

  @override
  Future<Map<String, AppMediaItem>> fetchAll() async {
    logger.d("Getting appMediaItems from list");

    Map<String, AppMediaItem> appMediaItems = {};

    try {
      QuerySnapshot querySnapshot = await appMediaItemReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          AppMediaItem appMediaItem = AppMediaItem.fromJSON(documentSnapshot.data());
          appMediaItem.id = documentSnapshot.id;
          appMediaItems[appMediaItem.id] = appMediaItem;
        }
      }
    } catch (e) {
      logger.d(e);
    }
    return appMediaItems;
  }

  @override
  Future<Map<String, AppMediaItem>> retrieveFromList(List<String> appMediaItemIds) async {
    logger.d("Getting appMediaItems from list");

    Map<String, AppMediaItem> appMediaItems = {};

    try {
      QuerySnapshot querySnapshot = await appMediaItemReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(appMediaItemIds.contains(documentSnapshot.id)){
            AppMediaItem appMediaItemm = AppMediaItem.fromJSON(documentSnapshot.data().toString());
            logger.d("AppMediaItem ${appMediaItemm.name} was retrieved with details");
            appMediaItems[documentSnapshot.id] = appMediaItemm;
          }
        }
      }

    } catch (e) {
      logger.d(e);
    }
    return appMediaItems;
  }

  @override
  Future<bool> exists(String appMediaItemId) async {
    logger.d("Getting appMediaItem $appMediaItemId");

    try {
      await appMediaItemReference.doc(appMediaItemId).get().then((doc) {
        if (doc.exists) {
          logger.d("AppMediaItem found");
          return true;
        }
      });
    } catch (e) {
      logger.e(e);
    }
    logger.d("AppMediaItem not found");
    return false;
  }

  @override
  Future<void> insert(AppMediaItem appMediaItem) async {
    logger.d("Adding appMediaItem to database collection");
    try {
      if((!appMediaItem.url.contains("gig-me-out") || !appMediaItem.url.contains("firebasestorage.googleapis.com"))
          && appMediaItem.mediaSource == AppMediaSource.internal) {

        if(appMediaItem.url.contains("spotify") || appMediaItem.url.contains("p.scdn.co")) {
          appMediaItem.mediaSource = AppMediaSource.spotify;
        } else if(appMediaItem.url.contains("youtube")) {
          appMediaItem.mediaSource = AppMediaSource.spotify;
        } else {
          appMediaItem.mediaSource = AppMediaSource.other;
        }
    }

      await appMediaItemReference.doc(appMediaItem.id).set(appMediaItem.toJSON());
      logger.d("AppMediaItem inserted into Firestore");
    } catch (e) {
      logger.e(e.toString());
      logger.i("AppMediaItem not inserted into Firestore");
    }
  }

  @override
  Future<bool> remove(AppMediaItem appMediaItem) async {
    logger.d("Removing appMediaItem from database collection");
    try {
      await appMediaItemReference.doc(appMediaItem.id).delete();
      return true;
    } catch (e) {
      logger.d(e.toString());
      return false;
    }
  }

  @override
  Future<bool> removeItemFromList(String profileId, String itemlistId, AppMediaItem appMediaItem) async {
    logger.d("Removing ItemlistItem for user $profileId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            DocumentSnapshot snapshot  = await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
                .doc(itemlistId).get();

            Itemlist itemlist = Itemlist.fromJSON(snapshot.data());
            itemlist.appMediaItems?.removeWhere((element) => element.id == appMediaItem.id);
            await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
                .doc(itemlistId).update(itemlist.toJSON());

          }
        }
      });

      logger.i("ItemlistItem ${appMediaItem.name} was updated to ${appMediaItem.state}");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("ItemlistItem ${appMediaItem.name} was not updated");
    return false;
  }

  @override
  Future<void> existsOrInsert(AppMediaItem appMediaItem) async {
    logger.d("Getting appMediaItem ${appMediaItem.id}");

    try {
      appMediaItemReference.doc(appMediaItem.id).get().then((doc) {
        if (doc.exists) {
          logger.d("AppMediaItem found");
        } else {
          logger.d("AppMediaItem not found. Inserting");
          insert(appMediaItem);
        }
      });
    } catch (e) {
      logger.e(e);
    }

  }

}
