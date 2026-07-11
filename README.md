# Faka Card

Flutter app with:

- Login only, no register.
- Mobile data gate before app use.
- Vodafone seamless login and token refresh.
- Product dashboard for Fakka and Mared.
- Local operation history for success and failure.
- Android network permissions.

## Run

Install Flutter, then run:

```powershell
flutter pub get
flutter run
```

The first Vodafone endpoint uses `http://`, so Android cleartext traffic is enabled in the manifest.

## Backend login

The login screen calls:

```txt
POST {BACKEND_BASE_URL}/auth/login
```

Default backend URL:

```txt
https://mansourayman.pythonanywhere.com
```

Expected response:

```json
{
  "success": true,
  "accessToken": "jwt_token",
  "user": {
    "id": 1,
    "username": "admin",
    "role": "admin"
  }
}
```
"# fakaCard" 
"# fakaCard" 
