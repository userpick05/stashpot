# Credentials & Config Needed Before Later Phases

This file lists everything that must be provided before Phase 2 (wiring up Firebase, ML Kit, and the Gemini API).

---

## 1. Firebase — `google-services.json`

**What:** The per-app Firebase config file that ties the APK to your Firestore, Auth, and Storage project.

**How to get it:**
1. Go to [Firebase Console](https://console.firebase.google.com/) and create a project (e.g. "Stashpot").
2. Inside the project, add an **Android app** with package name **`com.stashpot.app`**.
3. Download `google-services.json`.
4. Drop it at: `android/app/google-services.json`

**Firebase services to enable in the console:**
- Authentication → Email/Password sign-in (and/or Google sign-in)
- Cloud Firestore → Create database (start in test mode, lock down rules later)
- Storage → Create bucket

---

## 2. Gemini API Key

**What:** An API key for `generativelanguage.googleapis.com` used by the photo food-ID feature.

**How to get it:**
1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Create an API key.
3. Place it in a `.env` file at the project root (never commit this):
   ```
   GEMINI_API_KEY=AIza...
   ```
   Or store it in Firebase Remote Config so neither device has the key hard-coded.

---

## 3. Open Food Facts API

**No key required.** The Open Food Facts API (`https://world.openfoodfacts.org/api/v2/product/{barcode}`) is free and open — no registration or key needed. Just keep a descriptive `User-Agent` header per their guidelines, e.g.:
```
User-Agent: Stashpot/1.0 (userpick05@gmail.com)
```

---

## 4. Firebase Security Rules (before going live)

The default Firestore rules allow any authenticated user to read/write everything. Before daily use, tighten the rules so each user can only see their own household's data. A starter rule set will be added in Phase 2, but you'll need to deploy it from the Firebase console.

---

## Summary Checklist

| Item | Status |
|------|--------|
| `android/app/google-services.json` | **Needed from you** |
| Gemini API key (`.env` or Remote Config) | **Needed from you** |
| Open Food Facts API key | Not required |
| Firebase Auth enabled | **Set up in Firebase Console** |
| Firestore database created | **Set up in Firebase Console** |
| Firebase Storage bucket created | **Set up in Firebase Console** |
