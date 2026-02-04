# 🎓 College Faculty Salary Management System (SMS)

A comprehensive **Flutter & Firebase** application designed to streamline the management of Visiting Faculty members. This system allows Admins to manage profiles and verify attendance, while automating salary calculations based on hourly rates and verified lectures.

**Live Demo:** [Insert your Firebase Hosting Link Here]

---

## 🚀 Features

### 🔐 Role-Based Access Control
* **Admin Panel:** Full control over the system.
* **Faculty Portal:** Restricted access for teachers to log their activities.

### 👨‍💼 Admin Module
* **Dashboard:** Real-time statistics on active faculty and attendance records.
* **Faculty Management:** Add, Edit, View, and Delete faculty profiles.
* **Attendance Verification:** Review daily logs submitted by faculty. Mark them as *Verified* or leave them as *Pending*.
* **Automated Salary Calculation:**
    * Automatically calculates: `Verified Lectures` × `Hourly Rate`.
    * Generates payment receipts.
    * Tracks payment status (Pending vs. Paid).

### 👩‍🏫 Faculty Module
* **Daily Logging:** Submit daily attendance (Date, Subject, Number of Lectures).
* **Performance Tracking:** View total lectures taken and estimated earnings.
* **Salary History:** View breakdown of monthly earnings and payment status.
* **Responsive Design:** Works seamlessly on Desktop (Sidebar) and Mobile (Drawer).

### 🎨 UI/UX Features
* **Responsive Layout:** Automatically adapts between Laptop and Mobile screens.
* **Dark Mode:** Built-in theme switcher for better accessibility.
* **Secure Authentication:** Powered by Firebase Auth.

---

## 🛠️ Tech Stack

* **Frontend:** [Flutter](https://flutter.dev/) (Dart)
* **Backend:** [Firebase](https://firebase.google.com/)
    * **Authentication:** Email/Password & Google Sign-In.
    * **Firestore Database:** NoSQL cloud database for real-time data syncing.
    * **Hosting:** Deployed via Firebase Hosting.
* **State Management:** Provider & StreamBuilders.

---

## 🏗️ Installation & Setup

Follow these steps to run the project locally.

### Prerequisites
* Flutter SDK installed ([Guide](https://docs.flutter.dev/get-started/install))
* Firebase Account

### 1. Clone the Repository
```bash
git clone [https://github.com/your-username/college-sms.git](https://github.com/your-username/college-sms.git)
cd college-sms
``` 

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/?authuser=1).
2. Create a new project.
3. Enable Authentication (Email/Password).
4. Enable Cloud Firestore (Create database in test mode).
5. Use `flutterfire configure` to generate `firebase_options.dart` OR manually add your `google-services.json` / `GoogleService-Info.plist`.


### 4. Create an Admin User

Since there is no public sign-up for Admins, you must create the first user manually in the Firebase Console:
1. Go to **Authentication** -> Add User (e.g., admin@college.edu).
2. Go to **Firestore Database** -> Create collection users.
3. Add a document with the **User UID** from Authentication.
4. Add fields:
* email: **admin@college.edu**
* name: **Admin**
* role: **"Super Admin"**

### 5. Run the App
```bash
flutter run
# For Web
flutter run -d chrome
```

---

## 📂 Project Structure
```bash
lib/
├── pages/
│   ├── admin/           # Admin screens (Dashboard, Salary, Add Faculty)
│   ├── faculty/         # Faculty screens (Dashboard, Attendance, History)
│   └── login_page.dart  # Auth screen
├── services/
│   ├── auth_gate.dart   # Redirects users based on 'admin' or 'faculty' role
│   └── theme_provider.dart # Handles Dark/Light mode logic
├── widgets/
│   ├── app_sidebars.dart # Reusable navigation sidebar
│   └── responsive_layout.dart # Handles Desktop vs Mobile layout
└── main.dart            # Entry point & Routes
```
