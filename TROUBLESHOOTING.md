# AucorsaBus Troubleshooting Guide

## Issue: Bus Times Not Showing

### Symptom
- App loads successfully
- Lines and stops display correctly
- Bus arrival times show "Sin servicio" or don't appear
- No error messages visible to user

### Root Cause
The app was using the wrong API domain for estimation requests.

### Solution ✅
**Use `lightapi.aucorsa.es` for estimation endpoints**

The AUCORSA API is split across two domains:
- **Main API** (`aucorsa.es`) - Lines, stops, routes, service alerts
- **Light API** (`lightapi.aucorsa.es`) - Real-time bus estimations ⭐

### Verification Steps

1. **Check API endpoint in code:**
   ```dart
   // File: lib/services/api_service.dart
   static const String _lightApiUrl = 'https://lightapi.aucorsa.es/wp-json/aucorsa/v1';
   
   // Estimation methods should use _lightApiUrl:
   Future<Estimation?> fetchEstimation(...) async {
     final targetUrl = '$_lightApiUrl/estimations/stop?...';
   }
   ```

2. **Test API manually:**
   ```bash
   # Get nonce from main site
   curl https://aucorsa.es/ | grep "ajax_nonce"
   
   # Test estimation endpoint (use your nonce)
   curl "https://lightapi.aucorsa.es/wp-json/aucorsa/v1/estimations/stop?stop_id=105&_wpnonce=YOUR_NONCE"
   ```

3. **Expected response:**
   - HTML string containing bus estimation data
   - OR "Sin estimaciones" if no buses currently running
   - NOT a 403 error

---

## Issue: "403 Forbidden" Error

### Symptom
- API returns status 403
- Error message: "unauthorized automated client"

### Root Cause
Using `aucorsa.es` domain instead of `lightapi.aucorsa.es` for estimations.

### Solution
Switch to Light API domain as shown above.

---

## Issue: Nonce Expired

### Symptom
- API returns authentication errors
- Previously working requests start failing
- "Invalid nonce" errors

### Solution
**Refresh the nonce:**
1. Nonces expire after ~1 hour
2. App automatically refreshes nonce when expired
3. Check `_initializeSession()` method in `api_service.dart`

```dart
// Nonce is refreshed if older than 1 hour
static const Duration _nonceMaxAge = Duration(hours: 1);
```

---

## Issue: No Service / Empty Estimations

### Symptom
- API returns successfully
- Response contains "Sin estimaciones" or "No service"

### Diagnosis
**This is normal!** It means:
1. Buses are not currently running (late night/early morning)
2. No buses scheduled at this stop/line at this time
3. Service disruption (check service alerts)

### How to Verify
1. Check the time - buses typically run 6 AM - 11 PM
2. Check service alerts: `fetchServiceAlerts()`
3. Try a different stop or line
4. Check AUCORSA official website for service hours

---

## Issue: CORS Errors (Web Version)

### Symptom
- Browser console shows CORS errors
- "Access-Control-Allow-Origin" errors
- Works on mobile but not web

### Root Cause
Cross-origin requests blocked by browser.

### Solution
App uses CORS proxy for web:
```dart
String get _proxyUrl => kIsWeb ? 'https://corsproxy.io/?' : '';
```

**If CORS proxy is down:**
1. Try alternate proxy: `https://api.allorigins.win/raw?url=`
2. Or deploy your own CORS proxy
3. Or use browser extension to disable CORS (development only)

---

## Issue: Slow Response Times

### Symptom
- App takes long to load times
- Estimations appear after delay

### Diagnosis
Check these factors:
1. **Network speed** - Real-time data requires good connection
2. **CORS proxy** (web only) - Adds latency, try alternate proxy
3. **Cloudflare cache** - Light API uses Cloudflare, check CF-Cache-Status header

### Optimization
App already implements 30-second caching:
```dart
static const Duration _cacheMaxAge = Duration(seconds: 30);
```

Increase cache duration if needed (trade-off: less real-time).

---

## Issue: Service Alerts Not Showing

### Symptom
- Known service disruptions not displayed
- Alerts section empty

### Solution
Service alerts use standard WordPress API on main domain:
```dart
const targetUrl = 'https://aucorsa.es/wp-json/wp/v2/estado-del-servicio';
```

**Troubleshooting:**
1. Verify endpoint is accessible
2. Check if alerts exist on official website
3. Verify `fetchServiceAlerts()` method
4. Check cache - alerts cached for 5 minutes

---

## Development Tools

### Test API Endpoints (PowerShell)
```powershell
# Run from repo root
.\Get-AucorsaEstimation.ps1 -StopId '105'
.\Get-AucorsaEstimation.ps1 -LineId '706'
.\Get-AucorsaEstimation.ps1 -ListLines
```

### Enable Debug Logging
Already enabled in debug mode:
```dart
if (kDebugMode) print("[ApiService] $message");
```

Check console/logcat for API request details.

### Flutter DevTools
```bash
cd App
flutter run -d chrome  # Web
flutter run -d windows # Desktop
flutter run            # Mobile (with device connected)

# Then press 'v' to open DevTools
```

---

## API Documentation

See detailed API documentation in:
- `AUCORSA_API.md` - Original API reverse engineering
- `LIGHTAPI_ANALYSIS.md` - Light API discovery and analysis

### Quick API Reference

**Get Nonce:**
```
GET https://aucorsa.es/
Extract: "ajax_nonce":"[VALUE]"
```

**Get Lines:**
```
GET https://aucorsa.es/wp-json/aucorsa/v1/autocompletion/line?term=&_wpnonce=[NONCE]
```

**Get Stops:**
```
GET https://aucorsa.es/wp-json/aucorsa/v1/autocompletion/stop?term=tendillas&_wpnonce=[NONCE]
```

**Get Estimations (CRITICAL - Use lightapi!):**
```
GET https://lightapi.aucorsa.es/wp-json/aucorsa/v1/estimations/stop?stop_id=105&_wpnonce=[NONCE]
```

**Get Service Alerts:**
```
GET https://aucorsa.es/wp-json/wp/v2/estado-del-servicio
```

---

## Common Mistakes

❌ **Using wrong domain for estimations**
```dart
// WRONG - Will get 403
'$_baseUrl/estimations/stop'

// RIGHT - Use Light API
'$_lightApiUrl/estimations/stop'
```

❌ **Not handling "Sin servicio"**
```dart
// App should gracefully show "No service" to users
// Don't treat it as an error
```

❌ **Hardcoding nonce**
```dart
// WRONG - Nonce expires
const nonce = 'abc123';

// RIGHT - Fetch dynamically
await _initializeSession();
```

❌ **Not using CORS proxy on web**
```dart
// Web version needs CORS proxy
String get _proxyUrl => kIsWeb ? 'https://corsproxy.io/?' : '';
```

---

## When to Contact AUCORSA

Contact AUCORSA if:
1. API changes format or structure
2. New authentication required
3. Legal questions about API usage
4. Want official API access/partnership

**Contact methods:**
- Website: https://aucorsa.es/contacto/
- Address: Aucorsa S.A., Córdoba, Spain

---

## Version History

### v1.0 - Initial Release
- Used `aucorsa.es` for all endpoints
- Worked initially

### v1.1 - Light API Fix (Current)
- Discovered `lightapi.aucorsa.es` domain
- Fixed missing bus times issue
- Updated `api_service.dart` to use Light API for estimations

---

## Future Considerations

- Monitor for API v2 endpoints
- Watch for WebSocket support
- Consider batch estimation requests
- Implement fallback between main and light API
- Add health monitoring for both domains

---

## Useful Links

- [AUCORSA Official Site](https://aucorsa.es/)
- [GitHub Repository](https://github.com/ncc-288/AucorsaBus)
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart HTTP Package](https://pub.dev/packages/http)

---

**Last Updated:** January 2025
**Maintainer:** Check GitHub for current maintainer
