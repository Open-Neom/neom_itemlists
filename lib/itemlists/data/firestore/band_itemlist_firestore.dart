import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
import 'package:neom_commons/core/data/firestore/constants/app_firestore_constants.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

class BandItemlistFirestore {//implements ItemlistRepository {

  var logger = AppUtilities.logger;
  final appMediaItemReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.appMediaItems);
  final bandReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.bands);

  @override
  Future<bool> addAppMediaItem(String bandId, AppMediaItem item, String itemlistId) async {
    logger.i("Adding item for Band $bandId");
    logger.d("Adding item to itemlist $itemlistId");
    bool addedItem = false;

    try {

       QuerySnapshot querySnapshot = await bandReference.get();

       for (var document in querySnapshot.docs) {
         if(document.id == bandId) {
           await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
            .doc(itemlistId)
            .update({
              AppFirestoreConstants.appMediaItems: FieldValue.arrayUnion([item.toJSON()])
            });

           addedItem = true;
         }
      }
    } catch (e) {
      logger.e(e.toString());
    }
    await Future.delayed(const Duration(seconds: 2));
    addedItem ? logger.d("Item was added to itemlist $itemlistId") :
    logger.d("Item was not added to itemlist $itemlistId");
    return addedItem;
  }


  @override
  Future<bool> removeItem(String bandId, AppMediaItem appMediaItem, String itemlistId) async {
    logger.d("Removing item from itemlist $itemlistId");

    try {
      await bandReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == bandId) {
            await document.reference
                .collection(AppFirestoreCollectionConstants.itemlists)
                .doc(itemlistId)
                .update({
                  AppFirestoreConstants.appMediaItems: FieldValue.arrayRemove([appMediaItem.toJSON()])
                });
          }
        }
      });

      logger.d("Item was removed from itemlist $itemlistId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("Item was not  removed from itemlist $itemlistId");
    return false;
  }


  @override
  Future<String> insert(Itemlist itemlist) async {
    logger.d("Retrieving itemlists for ${itemlist.ownerId}");
    String itemlistId = "";

    try {
      DocumentReference? documentReference;

      await bandReference.get()
        .then((querySnapshot) {
          for (var document in querySnapshot.docs) {
          if (document.id == itemlist.ownerId) {
            documentReference = document.reference;
          }
        }
      });

      if(documentReference != null) {
        DocumentReference docRef = await documentReference!
            .collection(AppFirestoreCollectionConstants.itemlists)
            .add(itemlist.toJSON());
        itemlistId = docRef.id;
      }

      logger.d("Itemlist $itemlistId inserted to band ${itemlist.ownerId}");
    } catch (e) {
      logger.e(e.toString());
    }

    return itemlistId;
  }


  @override
  Future<Map<String, Itemlist>> retrieveItemlists(String bandId) async {
    logger.d("Retrieving itemlists for $bandId");
    Map<String, Itemlist> itemlists = <String,Itemlist>{};

    try {
      QuerySnapshot querySnapshot = await bandReference.get();
        for (var document in querySnapshot.docs) {
          if(document.id == bandId) {
            await document.reference.collection(
                AppFirestoreCollectionConstants.itemlists).get()
                .then((querySnapshot) {
                  for (var queryDocumentSnapshot in querySnapshot.docs) {
                    Itemlist itemlist = Itemlist.fromJSON(queryDocumentSnapshot.data());
                    itemlist.id = queryDocumentSnapshot.id;
                    itemlists[itemlist.id] = itemlist;
                  }
                });
          }
        }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("${itemlists.length} itemlists found");
    return itemlists;
  }

  @override
  Future<bool> remove(bandId, itemlistId) async {
    logger.d("Removing $itemlistId for by $bandId");
    try {

      await bandReference.get()
        .then((querySnapshot) async {
            for (var document in querySnapshot.docs) {
          if (document.id == bandId) {
            await document.reference.collection(
                AppFirestoreCollectionConstants.itemlists).doc(itemlistId).delete();
          }
        }
      });

      logger.d("Itemlist $itemlistId removed");
      return true;

    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> update(String bandId, Itemlist itemlist) async {
    logger.d("Updating Itemlist for user $bandId");

    try {

      await bandReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == bandId) {
            await document.reference.collection(
                AppFirestoreCollectionConstants.itemlists).doc(itemlist.id).update({
              AppFirestoreConstants.name: itemlist.name,
              AppFirestoreConstants.description: itemlist.description});
          }
        }
      });

      logger.d("Itemlist ${itemlist.id} was updated");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("Itemlist ${itemlist.id} was not updated");
    return false;
  }

  // @override
  // Future<bool> setAsFavorite(String bandId, Itemlist itemlist) async {
  //   logger.d("Updating to favorite Itemlist for user $bandId");
  //
  //   try {
  //     await bandReference.get()
  //         .then((querySnapshot) async {
  //       for (var document in querySnapshot.docs) {
  //         if(document.id == bandId) {
  //           await document.reference.collection(
  //               AppFirestoreCollectionConstants.itemlists)
  //               .doc(itemlist.id).update({AppFirestoreConstants.isFav: true});
  //         }
  //       }
  //     });
  //
  //     logger.d("Itemlist ${itemlist.id} was set as favorite");
  //     return true;
  //   } catch (e) {
  //     logger.e(e.toString());
  //   }
  //
  //   logger.d("Itemlist ${itemlist.id} was not updated");
  //   return false;
  // }


  // @override
  // Future<bool> unsetOfFavorite(String bandId, Itemlist itemlist) async {
  //   logger.d("Updating to unFavorite Itemlist for user $bandId");
  //   itemlist.isFav = false;
  //
  //   try {
  //     await bandReference.get()
  //         .then((querySnapshot) async {
  //       for (var document in querySnapshot.docs) {
  //         if(document.id == bandId) {
  //           await document.reference.collection(
  //               AppFirestoreCollectionConstants.itemlists)
  //               .doc(itemlist.id).update({AppFirestoreConstants.isFav: false});
  //         }
  //       }
  //     });
  //
  //     logger.d("Itemlist ${itemlist.id} was unset of favorite");
  //     return true;
  //   } catch (e) {
  //     logger.e(e.toString());
  //   }
  //
  //   logger.d("Itemlist ${itemlist.id} was not updated");
  //   return false;
  // }

  @override
  Future<bool> updateItem(String profileId, String itemlistId, AppMediaItem appMediaItem) async {
    logger.d("Updating ItemlistItem for profile $profileId");

    try {

      await bandReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
                .doc(itemlistId).update({
              AppFirestoreConstants.appMediaItems: FieldValue.arrayUnion([appMediaItem.toJSON()])
            });
          }}
      });

      logger.d("ItemlistItem ${appMediaItem.name} was updated to ${appMediaItem.state}");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("ItemlistItem ${appMediaItem.name} was not updated");
    return false;
  }

  @override
  Future<bool> addReleaseItem({required String profileId, required String itemlistId, required releaseItem}) {
    // TODO: implement addReleaseItem
    throw UnimplementedError();
  }

  @override
  Future<bool> removeReleaseItem({required String profileId, required String itemlistId, required releaseItem}) {
    // TODO: implement removeReleaseItem
    throw UnimplementedError();
  }

  @override
  Future<bool> addPreset({required String profileId, required String chamberId, required ChamberPreset preset}) {
    // TODO: implement addPreset
    throw UnimplementedError();
  }

  @override
  Future<bool> removePreset(String profileId, ChamberPreset preset, String chamberId) {
    // TODO: implement removePreset
    throw UnimplementedError();
  }

  @override
  Future<bool> updatePreset(String profileId, String chamberId, ChamberPreset preset) {
    // TODO: implement updatePreset
    throw UnimplementedError();
  }

  @override
  Future<List<Itemlist>> fetchAll({bool onlyPublic = false, bool excludeMyFavorites = true, int minItems = 0}) {
    // TODO: implement fetchAll
    throw UnimplementedError();
  }

}
