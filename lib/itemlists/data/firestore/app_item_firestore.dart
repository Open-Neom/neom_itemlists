// import 'dart:async';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import 'package:neom_commons/core/data/firestore/constants/app_firestore_collection_constants.dart';
// import 'package:neom_commons/core/domain/model/app_item.dart';
// import 'package:neom_commons/core/domain/model/item_list.dart';
// import 'package:neom_commons/core/utils/app_utilities.dart';
// import '../../domain/repository/app_item_repository.dart';
//
// class AppItemFirestore implements AppItemRepository {
//
//   var logger = AppUtilities.logger;
//   final appItemReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.appItems);
//   final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);
//
//   @override
//   Future<AppItem> retrieve(String itemId) async {
//     logger.d("Getting item $itemId");
//     AppItem appItem = AppItem();
//     try {
//       await appItemReference.doc(itemId).get().then((doc) {
//         if (doc.exists) {
//           appItem = AppItem.fromJSON(doc.data());
//           logger.d("AppItem ${appItem.name} was retrieved with details");
//         } else {
//           logger.d("AppItem not found");
//         }
//       });
//     } catch (e) {
//       logger.d(e);
//       rethrow;
//     }
//     return appItem;
//   }
//
//   @override
//   Future<Map<String, AppItem>> retrieveFromList(List<String> appItemIds) async {
//     logger.d("Getting appItems from list");
//
//     Map<String, AppItem> appItems = {};
//
//     try {
//       QuerySnapshot querySnapshot = await appItemReference.get();
//
//       if (querySnapshot.docs.isNotEmpty) {
//         logger.d("QuerySnapshot is not empty");
//         for (var documentSnapshot in querySnapshot.docs) {
//           if(appItemIds.contains(documentSnapshot.id)){
//             AppItem appItemm = AppItem.fromJSON(documentSnapshot.data());
//             logger.d("AppItem ${appItemm.name} was retrieved with details");
//             appItems[documentSnapshot.id] = appItemm;
//           }
//         }
//       }
//
//     } catch (e) {
//       logger.d(e);
//     }
//     return appItems;
//   }
//
//   @override
//   Future<bool> exists(String appItemId) async {
//     logger.d("Getting appItem $appItemId");
//
//     try {
//       await appItemReference.doc(appItemId).get().then((doc) {
//         if (doc.exists) {
//           logger.d("AppItem found");
//           return true;
//         }
//       });
//     } catch (e) {
//       logger.e(e);
//     }
//     logger.d("AppItem not found");
//     return false;
//   }
//
//   @override
//   Future<void> insert(AppItem appItem) async {
//     logger.d("Adding appItem to database collection");
//     try {
//       await appItemReference.doc(appItem.id).set(AppItem.forItemsCollection(appItem).toJSON());
//       logger.d("AppItem inserted into Firestore");
//     } catch (e) {
//       logger.e(e.toString());
//       logger.i("AppItem not inserted into Firestore");
//     }
//   }
//
//   @override
//   Future<bool> remove(AppItem appItem) async {
//     logger.d("Removing appItem from database collection");
//     try {
//       await appItemReference.doc(appItem.id).delete();
//       return true;
//     } catch (e) {
//       logger.d(e.toString());
//       return false;
//     }
//   }
//
//   @override
//   Future<bool> removeItemFromList(String profileId, String itemlistId, AppItem appItem) async {
//     logger.d("Removing ItemlistItem for user $profileId");
//
//     try {
//
//       await profileReference.get()
//           .then((querySnapshot) async {
//         for (var document in querySnapshot.docs) {
//           if(document.id == profileId) {
//             DocumentSnapshot snapshot  = await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
//                 .doc(itemlistId).get();
//
//             Itemlist itemlist = Itemlist.fromJSON(snapshot.data());
//             itemlist.appItems?.removeWhere((element) => element.id == appItem.id);
//             await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
//                 .doc(itemlistId).update(itemlist.toJSON());
//
//           }
//         }
//       });
//
//       logger.i("ItemlistItem ${appItem.name} was updated to ${appItem.state}");
//       return true;
//     } catch (e) {
//       logger.e(e.toString());
//     }
//
//     logger.d("ItemlistItem ${appItem.name} was not updated");
//     return false;
//   }
//
//   @override
//   Future<void> existsOrInsert(AppItem appItem) async {
//     logger.d("Getting appItem ${appItem.id}");
//
//     try {
//       appItemReference.doc(appItem.id).get().then((doc) {
//         if (doc.exists) {
//           logger.d("AppItem found");
//           return true;
//         } else {
//           logger.d("AppItem not found. Inserting");
//           insert(appItem);
//         }
//       });
//     } catch (e) {
//       logger.e(e);
//     }
//
//   }
//
// }
