## 1.4.0 - Architectural Refactor Highlights

#### 🏗️ Core Architecture
- **Dependency Inversion Principle (DIP) Implementation**:
    - Introduced service interfaces (`UserService`, `AudioPlayerService`, etc.) for all core controllers

#### 🔧 Key Refactors
- **Service Layer Separation**:
    - `UserController` now implements `UserService` interface

#### 🚀 Performance Gains
- Reduced bundle size through dependency optimization
- Improved compilation speed via decoupling
- Enhanced testability through interface segregation

#### ♻️ Breaking Changes
- Consumers must now depend on interfaces rather than concrete implementations
- Upload functionality requires `neom_media_upload` module
- Service registration follows new `Bind.put()` + `Bind.lazyPut()` pattern
