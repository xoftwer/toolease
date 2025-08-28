# Flutter Inventory Kiosk App Development Guide

## Project Overview

ToolEase is a **Flutter-based inventory management kiosk application** designed for **tablet devices (Android-only)**.  
It manages the **borrowing and returning of items by students**, with a **single-user admin system** secured via **device PIN/password authentication**.

---

## App Name

**ToolEase**

---

## Technology Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Database**: SQLite3
- **ORM**: Drift
- **Architecture**: Clean Architecture with Repository Pattern
- **Target Platform**: Android Tablets

---

## Core Design Principles

### 1. Clean Architecture Layers

lib/
├── core/
│ ├── constants/
│ ├── themes/
│ ├── utils/
│ └── widgets/
├── features/
│ ├── auth/
│ │ ├── data/
│ │ ├── domain/
│ │ └── presentation/
│ ├── inventory/
│ │ ├── data/
│ │ ├── domain/
│ │ └── presentation/
│ ├── borrowing/
│ │ ├── data/
│ │ ├── domain/
│ │ └── presentation/
│ └── reports/
│ ├── data/
│ ├── domain/
│ └── presentation/
└── main.dart

markdown
Copy code

### 2. Code Organization Rules

✅ **ALWAYS**

- Separate **data / domain / presentation** in each feature
- Use **Riverpod DI providers**
- Define **immutable models** with `freezed`
- Keep **DB entities separate** from domain models
- Split widgets > 50 lines into their own files

❌ **NEVER**

- Mix business logic with UI
- Access DB from the presentation layer
- Use mutable models
- Create God widgets

---

## Database Schema (Drift)

Includes **storages, items, students, borrow records, and borrow items**.

_(See Drift table definitions in schema section — unchanged from design)_

---

## State Management (Riverpod)

- Organize providers per feature (`auth_providers.dart`, `inventory_providers.dart`, etc.)
- Use **`AsyncValue`** for async operations
- Prefer `StreamProvider` for real-time updates
- Use `FutureProvider` for one-time fetches
- Complex state handled via `StateNotifierProvider`

---

## UI/UX Design

### 1. Responsive Layout

- Optimized for tablets
- Uses breakpoints (`mobile`, `tablet`, `desktop`)
- `ResponsiveLayout` pattern for adaptive UIs

### 2. Theming

- Material 3 with consistent color scheme
- Defined spacing system (xs → xl)

---

## Feature Implementation

### Public Screens (No authentication)

- **Home Screen**

  - Register link → Register screen
  - Borrow tile → Borrow screen
  - Return tile → Return screen
  - Activity log preview (last 10 transactions)

- **Register Screen**

  - Students must register **before borrowing**
  - Stores Student ID, Name, Year Level, Section

- **Borrow Screen**

  - Enter Student ID
  - Filter items by storage
  - Select items + set quantities
  - Show stock per item

- **Return Screen**
  - Enter Student ID
  - Review borrowed items + quantities
  - Mark conditions per item quantity: **Good / Damaged / Lost**

---

### Protected Screens (Authentication Required)

🔒 Access via **device PIN/password** only.

- **Dashboard**

  - Cards showing counts: Storages, Items, Active Borrows, Damaged/Lost
  - Recent activity logs

- **Settings**

  - Enable/disable: Register, Borrow, Return screens
  - Enable/disable kiosk mode

- **Storages**

  - CRUD storages
  - Show total items per storage

- **Items**

  - CRUD items
  - Fields: Item name, Storage ID, Quantity tracking

- **Students**

  - RUD only (Create via registration)
  - Fields: Student ID, Name, Year Level, Section

- **Records**

  - Manage active borrowings
  - Returned records
  - Archived records
  - Lost/Damaged items

- **Reports**
  - Generate reports by date range
  - Export: PDF, Excel, CSV
  - Save & preview exports

---

## Key Technical Implementations

- **Authentication**: `local_auth` (PIN/Password), auto-lock after inactivity
- **Borrow ID**: Auto-generated (Format: `2500001, 2500002`) 2025 -> 25 (prefix) + 00001 (is incremental value)
- **File Storage Service**: Reports, export/import support
- **Error Handling**: Unified `Result<T>` wrapper
- **Testing**: Unit, widget, and integration tests mandatory

---

## Security & Optimization

- Input validation, SQL injection prevention (via Drift), secure storage
- Automatic daily DB backups
- Data export encryption
- Indexing, pagination, caching for performance
- Lazy loading, const constructors, list virtualization in UI

---

## Deployment Checklist

- [ ] Debug prints removed
- [ ] Release optimizations enabled
- [ ] ProGuard/R8 configured (Android)
- [ ] Crash reporting set up
- [ ] Code minified & obfuscated
- [ ] Migration tests passed
- [ ] Backup/restore verified
- [ ] Tested on real tablets

---

## Maintenance

- **Weekly**: Dependency updates
- **Monthly**: Security patches
- **Quarterly**: Feature releases
- **Monitoring**: Crashes, DB performance, logs

---

## Common Pitfalls to Avoid

- Don’t mix `.then()` and `async/await`
- Don’t use `BuildContext` across async gaps
- Don’t skip disposal of controllers
- Don’t skip input validation or error boundaries
- Don’t hardcode magic strings/numbers

---

## App Flow (Summary with Diagrams)

1. Student Flows (Public)

```mermaid
flowchart TD
    A[Home Screen] --> B[Register]
    A --> C[Borrow Items]
    A --> D[Return Items]

    B --> E[Student Profile Created]
    C --> F[Enter Student ID]
    F --> G[Select Storage & Items]
    G --> H[Confirm Borrow]
    H --> I[Borrow Record Created]

    D --> J[Enter Student ID]
    J --> K[Review Borrowed Items]
    K --> L[Mark Return Condition: Good/Damaged/Lost]
    L --> M[Update Borrow Record]

2. Admin Flows (Protected by Device PIN)
mermaid

flowchart TD
    A[Login with Device PIN] --> B[Dashboard]

    B --> C[Storages Management]
    B --> D[Items Management]
    B --> E[Students Management]
    B --> F[Records Management]
    B --> G[Reports]

    C --> C1[Add/Edit/Delete Storages]
    D --> D1[CRUD Items + Stock Tracking]
    E --> E1[Update Student Info]
    F --> F1[Manage Active Borrows]
    F --> F2[Handle Returned Records]
    F --> F3[Archive Old Records]
    F --> F4[View Lost/Damaged Items]

    G --> G1[Select Date Range]
    G --> G2[Generate Report]
    G2 --> G3[Export: PDF, Excel, CSV]
    G3 --> G4[Save/Preview Export]

3. High-Level System Flow
mermaid

flowchart LR
    Student -->|Register| App
    Student -->|Borrow/Return| Inventory

    App -->|Records| Database
    App -->|Reports| FileSystem

    Admin -->|Manage| App
    Admin -->|Export Reports| FileSystem
```
