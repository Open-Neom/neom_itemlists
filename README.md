# neom_itemlists

Item Collection Management Module for the Open Neom ecosystem.

neom_itemlists provides comprehensive functionality for creating, organizing, and managing collections of media items (playlists, readlists, giglist, etc.). It supports both personal profile collections and band/group collections with proper owner type distinction.

## Features & Components

### Multi-Type Collections
- **Playlist**: Music and audio collections
- **Readlist**: Book and reading collections
- **Giglist**: Event and performance collections
- **Publication**: Released content collections
- **Album/EP/Single**: Music release formats

### Owner Type Support
- **Profile**: Personal user collections
- **Band**: Group/band shared collections
- Proper state management per owner type
- Cross-owner item sharing capabilities

### Item Management
- **AppMediaItem**: Audio/video media items
- **AppReleaseItem**: Published release items
- **ExternalItem**: Third-party linked items
- State tracking (ratings, play counts)

### Core Functionalities
- Create and manage itemlists with customizable metadata
- Add/remove items to/from itemlists
- Bulk operations and intelligent item deduplication
- Cloud sync with Firestore backend
- Push notifications on item additions

## Architecture

```
lib/
├── domain/
│   └── use_cases/
│       ├── app_item_service.dart
│       └── app_media_item_details_service.dart
├── ui/
│   ├── itemlist_controller.dart
│   ├── itemlist_items_controller.dart
│   ├── itemlist_page.dart
│   ├── itemlist_items_page.dart
│   ├── app_media_item/
│   │   ├── app_media_item_controller.dart
│   │   ├── app_media_item_details_controller.dart
│   │   └── app_media_item_details_page.dart
│   └── widgets/
│       ├── itemlist_widgets.dart
│       ├── itemlist_action_button.dart
│       ├── itemlist_appbar.dart
│       └── readlist_page.dart
├── utils/
│   ├── constants/
│   │   └── itemlist_translation_constants.dart
│   └── itemlist_utilities.dart
└── itemlist_routes.dart
```

## Dependencies

```yaml
dependencies:
  neom_core: ^2.0.0      # Core services, models, Firebase
  neom_commons: ^1.0.0   # Shared UI components
```

## Usage

### Navigating to Itemlists

```dart
import 'package:neom_itemlists/itemlist_routes.dart';

// View profile itemlists
Sint.toNamed(AppRouteConstants.lists);

// View band itemlists
Sint.toNamed(AppRouteConstants.lists, arguments: [band]);

// View specific itemlist items
Sint.toNamed(AppRouteConstants.listItems, arguments: [itemlist]);
```

### Using Itemlist Controller

```dart
import 'package:sint/sint.dart';
import 'package:neom_itemlists/ui/itemlist_controller.dart';

class MyController extends SintController {
  final itemlistController = Sint.find<ItemlistController>();

  Future<void> createNewPlaylist() async {
    itemlistController.newItemlistNameController.text = "My Playlist";
    await itemlistController.createItemlist(type: ItemlistType.playlist);
  }
}
```

### Adding Items to Itemlist

```dart
final itemsController = Sint.find<ItemlistItemsController>();

// Add media item to itemlist
await itemsController.addItemToItemlist(appMediaItem, itemlistId);

// Update item state
itemsController.setItemState(AppItemState.favorite);
await itemsController.updateItemlistItem(item);
```

## Owner Type Handling

The module correctly handles items based on owner type:

```dart
// Profile-owned itemlists
if(ownerType == OwnerType.profile) {
  userServiceImpl.profile.itemlists![listId] = newItemlist;
}

// Band-owned itemlists
else if(ownerType == OwnerType.band) {
  userServiceImpl.band.itemlists![listId] = newItemlist;
}
```

## Itemlist Types

| Type | Description | Use Case |
|------|-------------|----------|
| `playlist` | Audio/music collection | Songs, podcasts |
| `readlist` | Reading collection | Books, articles |
| `giglist` | Performance list | Concert setlists |
| `publication` | Published content | Releases |
| `album` | Full album release | Music albums |
| `ep` | Extended play | Short releases |
| `single` | Single track | Individual songs |
| `audiobook` | Spoken word | Audiobooks |
| `podcast` | Podcast series | Episodes |

## ROADMAP 2026

### Q1 2026 - Enhanced Item Management
- [ ] Drag-and-drop reordering
- [ ] Batch item operations (bulk add/remove)
- [ ] Item duplicate detection
- [ ] Smart playlist auto-generation

### Q2 2026 - Collaboration Features
- [ ] Shared itemlists between profiles
- [ ] Collaborative editing permissions
- [ ] Real-time sync for shared lists
- [ ] Comment/annotation support

### Q3 2026 - Discovery & Recommendations
- [ ] AI-powered item recommendations
- [ ] Similar itemlist suggestions
- [ ] Trending items integration
- [ ] Cross-user discovery

### Q4 2026 - Advanced Analytics
- [ ] Play/read statistics
- [ ] Item engagement metrics
- [ ] Collection insights dashboard
- [ ] Export/import capabilities

## Technical Highlights

### Service Injection Pattern
```dart
class ItemlistController extends SintController implements ItemlistService {
  final userServiceImpl = Sint.find<UserService>();

  OwnerType ownerType = OwnerType.profile;
  ItemlistType itemlistType;
}
```

### Owner-Aware State Updates
```dart
void _addItemToOwnerState(dynamic item) {
  Map<String, Itemlist>? ownerItemlists;

  if(itemlistOwner == OwnerType.profile) {
    ownerItemlists = userServiceImpl.profile.itemlists;
  } else if(itemlistOwner == OwnerType.band) {
    ownerItemlists = userServiceImpl.band.itemlists;
  }

  ownerItemlists?[itemlist.id]?.appMediaItems?.add(item);
}
```

## Contributing

We welcome contributions to neom_itemlists! If you're interested in media management, playlist features, or collection UX, your contributions can significantly enhance the Open Neom ecosystem.

## License

This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
