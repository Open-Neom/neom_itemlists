# Changelog

All notable changes to neom_itemlists will be documented in this file.

## [2.0.0] - 2026-02-12

### Added
- **restart() method**: New method to reinitialize the controller when needed
- **ItemlistItemService interface**: Added service abstraction for better dependency injection

### Changed
- **Null-coalescing assignment**: Refactored null checks to use `??=` operator for cleaner code
  - `userServiceImpl.profile.itemlists ??= {}` instead of verbose if-null blocks
- **Import ordering**: Reorganized imports to follow Dart conventions (package imports before relative)
- **Code cleanup**: Removed unnecessary blank lines and improved formatting

### Technical
- Better separation of concerns with service interfaces
- Improved testability through dependency inversion
- SINT framework integration refinements

### Migration Guide
- No breaking changes from 1.7.0
- Service interfaces are optional but recommended for new implementations

---

## [1.7.0] - 2026-02-08

### Fixed
- **Owner Type Bug in createItemlist()**: Now correctly updates `band.itemlists` when `ownerType == OwnerType.band` instead of always updating `profile.itemlists`
- **Inconsistent itemlistId usage in addItemToItemlist()**: Now uses `targetItemlistId` parameter consistently instead of mixing with `itemlist.id`
- **updateItemlistItem() owner awareness**: Added helper methods `_removeItemFromOwnerState()` and `_addItemToOwnerState()` to handle both profile and band itemlists correctly
- **Null safety improvements**: Added null-safe access operators (`?.`) for list operations

### Added
- Comprehensive README with ROADMAP 2026
- Architecture documentation with directory structure
- Usage examples for navigation and controllers
- Owner Type Handling documentation
- Itemlist Types reference table

### Changed
- Improved logging to include owner type context
- Refactored state management for better maintainability

### Documentation
- Detailed Q1-Q4 2026 roadmap including:
  - Enhanced item management (drag-drop, bulk ops)
  - Collaboration features (shared lists, permissions)
  - Discovery and recommendations (AI-powered)
  - Advanced analytics (statistics, insights)

## [1.6.0] - 2025-12-15

### Added
- ExternalItem support for third-party linked items
- ItemlistType enum expansion (audiobook, podcast, radioStation)

### Improved
- Better error handling in Firestore operations
- Loading state management

## [1.5.0] - 2025-11-01

### Added
- Band itemlist support via OwnerType.band
- Push notifications on item additions
- Item state tracking (AppItemState)

### Changed
- UserService integration for owner context

## [1.4.0] - 2025-09-15

### Architectural Refactor

#### Core Architecture
- **Dependency Inversion Principle (DIP) Implementation**:
  - Introduced service interfaces (`UserService`, `ItemlistService`, etc.)

#### Key Refactors
- **Service Layer Separation**:
  - Controllers now interact through service interfaces
  - Improved testability via interface segregation

#### Performance Gains
- Reduced bundle size through dependency optimization
- Improved compilation speed via decoupling

#### Breaking Changes
- Consumers must now depend on interfaces rather than concrete implementations
- Service registration follows new `Sint.put()` + `Sint.lazyPut()` pattern

## [1.3.0] - 2025-07-01

### Added
- ItemlistItemsController for item-level operations
- AppReleaseItem support alongside AppMediaItem
- Multi-type itemlist filtering

### Fixed
- Item deduplication logic
- Itemlist image URL handling

## [1.2.0] - 2025-05-15

### Added
- Privacy settings for itemlists (public/private)
- Itemlist update functionality
- Delete itemlist with cascade item removal

### Changed
- Improved itemlist creation flow
- Better validation for name/description

## [1.1.0] - 2025-04-01

### Added
- ItemlistController for CRUD operations
- ItemlistPage and ItemlistItemsPage UI
- Basic Firestore integration

### Fixed
- Position handling for itemlists
- Profile itemlists initialization

## [1.0.0] - 2025-03-01

### Initial Release
- Basic itemlist model and structure
- Profile itemlist integration
- AppMediaItem support
- Itemlist type system (playlist, readlist)
