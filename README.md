# ToolEase - Features

ToolEase is a **Flutter-based inventory management kiosk app** designed for **Android tablets**.  
It manages item borrowing and returning for students, with a **single-admin authentication system** using device PIN/password.

---

## 🚀 Public Features (Students)

Accessible without authentication.

- **Home Screen**

  - Quick access tiles: **Borrow**, **Return**
  - Register link for new students
  - Activity log preview (last 10 transactions)

- **Student Registration**

  - Register student profile before borrowing
  - Fields: Student ID (auto), First Name, Last Name, Year Level, Section

- **Borrow Items**

  - Enter Student ID
  - Filter items by storage
  - View available stock per item
  - Select multiple items and quantities
  - Borrow record generated with unique ID

- **Return Items**
  - Enter Student ID
  - Review borrowed items and quantities
  - Mark condition: **Good / Damaged / Lost**
  - Update borrow record automatically

---

## 🔒 Protected Features (Admin Only)

Requires device PIN/password authentication.

- **Dashboard**

  - Overview cards: Storages, Items, Active Borrows, Damaged & Lost Items
  - Recent activity logs

- **Settings**

  - Enable/disable Register, Borrow, Return screens
  - Enable/disable Kiosk Mode (restrict app navigation)

- **Storages**

  - CRUD storages (e.g., Drawer 1, Drawer 2)
  - Show item count per storage

- **Items**

  - CRUD items
  - Assign items to storages
  - Track stock and available quantity

- **Students**

  - Read, Update, Delete student records
  - (Create only via student registration)

- **Records**

  - Manage Active Borrow records
  - Manage Returned records
  - Archive old records
  - Track Lost & Damaged items

- **Reports**
  - Generate reports by date range
  - Export formats: **PDF, Excel, CSV**
  - Save and preview after export

---

## 🛡️ Other Core Features

- **Kiosk Mode**: 5-tap gesture unlocks PIN dialog, restricts system navigation
- **Authentication**: Uses `local_auth` (device PIN/biometric)
- **Borrow ID**: Auto-generated (Format: `2500001, 2500002`) 2025 -> 25 (prefix) + 00001 (is incremental value)
- **File Storage**: Auto-daily DB backups, export/import support
- **Accessibility**: High contrast mode, screen reader support, font scaling
- **Localization Ready**: Supports multiple locales, RTL, date/number formatting

---

## 📊 App Flows

- Students: **Register → Borrow → Return**
- Admin: **Dashboard → Manage → Reports**

---

**ToolEase** simplifies school inventory tracking by making **borrowing and returning items transparent, accountable, and easy to manage.**
