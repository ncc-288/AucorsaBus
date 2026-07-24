# Hotfix v1.4.4 - Fix Slow Auto-Refresh

## 🐛 Issue
Users reported that bus time updates were taking longer than expected after installing v1.4.3.

## 🔍 Root Cause
**Cache-Timer Mismatch:**
- API cache duration: 30 seconds
- Auto-refresh timer: 30 seconds
- **Problem**: When timer fires at exactly 30s, cache might still be valid (29.9s), causing the app to skip fetching new data
- **Result**: Effective refresh interval became ~60 seconds instead of 30 seconds

## ✅ Fix
Reduced cache duration from 30s to **25 seconds** in `api_service.dart`:

```dart
static const Duration _cacheMaxAge = Duration(seconds: 25);
```

**Why this works:**
- Auto-refresh fires every 30s
- Cache expires after 25s
- Timer always finds expired cache → fetches fresh data
- Guarantees maximum 30-second refresh interval

## 📝 Changes
- `App/lib/services/api_service.dart`: Changed `_cacheMaxAge` from 30s to 25s
- `App/pubspec.yaml`: Version bump 1.4.3+4 → 1.4.4+5

## 🧪 Testing
Users should notice:
- ✅ Bus times update every 30 seconds reliably
- ✅ No more "stuck" times requiring manual refresh
- ✅ Immediate updates when pulling to refresh

## 📦 Deployment
- Local APKs built: `App/AucorsaBus-1.4.4.apk` (ARM64, 17.6MB)
- Ready to install and test on device
