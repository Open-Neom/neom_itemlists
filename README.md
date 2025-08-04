# neom_itemlists
**Item Management for Open Neom**

`neom_itemlists` is a core module within the Open Neom ecosystem that provides comprehensive functionality
for creating, organizing, and managing collections of media items (playlists, readlists, etc.).
It implements the itemlist management features used across the Open Neom platform.

## 🌟 Features

### Core Capabilities
- **Multi-type Itemlists**: Supports playlists, readlists, and custom collection types
- **CRUD Operations**: Full lifecycle management for itemlists and their contents
- **Cross-module Integration**: Seamless interaction with `neom_core` models and `neom_commons` UI components
- **State Management**: Built with GetX for reactive state handling
- **Cloud Sync**: Automatic synchronization with Firestore backend

### Key Functionalities
- Create and manage itemlists with customizable metadata (name, description, privacy)
- Add/remove media items (songs, books, etc.) to/from itemlists
- Item state tracking (ratings, play counts)
- Bulk operations and intelligent item deduplication
- Responsive UI with adaptive layouts for all device sizes

## 📦 Installation

Add to your `pubspec.yaml`:

dependencies:
  neom_itemlists:
    git:
      url: https://github.com/Cyberneom/neom_itemlists.git

Then, run flutter pub get in your project's root directory.

🚀 Usage
Basic Integration
dart
// 1. Add to your app's routes
GetPage(
  name: AppRouteConstants.lists,
  page: () => const ItemlistPage(),
  binding: ItemlistBinding(),
)

// 2. Navigate to itemlist features
Get.toNamed(AppRouteConstants.lists);
Core Components
Controllers
•	ItemlistController: Main business logic for itemlist management
•	AppMediaItemController: Handles media item operations within lists
•	AppMediaItemDetailsController: Manages detailed item views
Pages
•	ItemlistPage: Main itemlist dashboard
•	ItemlistItemsPage: Displays contents of a specific itemlist
•	AppMediaItemDetailsPage: Detailed media item view
Widgets
•	Reusable components for itemlist display and interaction
•	Custom list tiles with rich media previews
•	State-aware action buttons
🛠️ Dependencies
Core Modules
•	neom_core: For base models and services
•	neom_commons: For shared UI components and utilities
External Packages
•	get: State management and dependency injection
•	cached_network_image: Efficient image loading
•	rflutter_alert: Custom alert dialogs
•	enum_to_string: Enum serialization

🏗️ Architecture
Clean Architecture Layers
Layer|	Components
Domain|	Models, Interfaces, Use Cases
Data|	Repositories, Data Sources
UI|	Pages, Controllers, Widgets

Key Design Patterns
•	Repository pattern for data access
•	Dependency Injection via GetX
•	Reactive programming with GetX Observables
•	SOLID principles throughout

🤝 Contributing
We welcome contributions! Please see:
•	Open Neom Contribution Guidelines
•	Module-Specific Development Guide

📄 License
Apache License 2.0 - See LICENSE for details.
text
