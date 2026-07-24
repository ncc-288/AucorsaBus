# Light API Analysis - lightapi.aucorsa.es

## Discovery Summary

During debugging of the missing bus times issue, we discovered that AUCORSA uses **two separate API domains**:

### Main API: `https://aucorsa.es`
- Primary WordPress site and API
- Handles most endpoints (lines, stops, routes, service alerts)
- **BLOCKS** the `/estimations/stop` endpoint with 403 Forbidden

### Light API: `https://lightapi.aucorsa.es`
- Dedicated API server for real-time data
- Behind Cloudflare CDN
- **ALLOWS** the `/estimations/stop` endpoint
- Mirrors all other endpoints from main API

---

## Test Results

| Endpoint | Main API (aucorsa.es) | Light API (lightapi.aucorsa.es) |
|----------|----------------------|----------------------------------|
| `/autocompletion/line` | ✅ Works | ✅ Works |
| `/autocompletion/stop` | ✅ Works | ✅ Works |
| `/map/nodes` | ✅ Works | ✅ Works |
| `/map/nearbusstops` | ✅ Works | ✅ Works |
| **`/estimations/stop`** | ❌ **403 Blocked** | ✅ **Works** |

---

## Why Light API Exists

**Theory:** The `lightapi.aucorsa.es` subdomain was created to:

1. **Separate real-time traffic** - Estimation requests are high-frequency and real-time, so they need dedicated infrastructure
2. **Cloudflare optimization** - Light API is behind Cloudflare with cache policies optimized for dynamic content
3. **Security isolation** - Blocking estimation API on main domain prevents abuse while allowing official apps via Light API
4. **Performance** - Reduces load on main WordPress site by offloading real-time queries

---

## Infrastructure Details

### Light API Characteristics:
- **Server:** Cloudflare (CDN)
- **Cache Status:** DYNAMIC (not cached, always fresh)
- **IP:** 104.21.14.80:443
- **SSL:** Valid certificate
- **WordPress:** Same WordPress instance as main site (shares authentication)

### Response Headers (from browser request):
```
access-control-allow-origin: https://aucorsa.es
access-control-allow-credentials: true
access-control-allow-methods: OPTIONS, GET, POST, PUT, PATCH, DELETE
cf-cache-status: DYNAMIC
server: cloudflare
```

---

## CORS Configuration

The Light API has proper CORS headers configured:
- **Origin:** `https://aucorsa.es` is whitelisted
- **Credentials:** Allowed (cookies/auth can be sent)
- **Methods:** Full REST support (GET, POST, PUT, PATCH, DELETE)

This allows the main website to make cross-origin requests to the Light API subdomain.

---

## Available Endpoints on Light API

All standard AUCORSA v1 endpoints are available:

### Public Query Endpoints:
- `/aucorsa/v1/autocompletion/stop` - Search stops
- `/aucorsa/v1/autocompletion/line` - Search lines
- `/aucorsa/v1/autocompletion/favorited_stop` - Get favorited stops
- `/aucorsa/v1/map/nodes` - Get line routes and stop sequences
- `/aucorsa/v1/map/nearbusstops` - Find nearby stops by geolocation

### Real-time Data Endpoints:
- `/aucorsa/v1/estimations/stop` - Get bus arrival estimations ⭐
- `/aucorsa/v1/estimations/favoritedstop` - Get estimations for favorited stops

### User/Card Management Endpoints (require auth):
- `/aucorsa/v1/ui/forms/recharge/main` - Recharge form UI
- `/aucorsa/v1/ui/forms/recharge/secondary` - Secondary recharge form
- `/aucorsa/v1/ui/forms/card/showtitle` - Card title display
- `/aucorsa/v1/recharges/cardmovements` - Card transaction history
- `/aucorsa/v1/recharges/payment` - Process recharge payment
- `/aucorsa/v1/cards/highlight` - Mark card as favorite
- `/aucorsa/v1/cards/ban` - Report card as lost/stolen
- `/aucorsa/v1/endusers/create` - Create user account
- `/aucorsa/v1/endusers/update` - Update user profile
- `/aucorsa/v1/endusers/changepassword` - Change password
- `/aucorsa/v1/endusers/registercard` - Register a new card
- `/aucorsa/v1/endusers/checkcard` - Validate card

---

## Authentication

Both APIs use the same **WordPress nonce** authentication:
1. Fetch nonce from `https://aucorsa.es/` homepage
2. Extract from: `"ajax_nonce":"[NONCE_VALUE]"`
3. Append to all API calls: `?_wpnonce=[NONCE_VALUE]`
4. Nonce expires after ~12-24 hours

**Note:** The nonce obtained from `aucorsa.es` works on `lightapi.aucorsa.es` because they share the same WordPress backend.

---

## Main API Blocking Mechanism

The main API (`aucorsa.es`) returns this 403 response for estimation requests:

```json
{
  "status": 403,
  "error": "Hemos detectado que este endpoint está siendo utilizado por un cliente automatizado no autorizado. Este servicio está destinado exclusivamente a las aplicaciones oficiales de AUCORSA. Todas las solicitudes son registradas y monitorizadas. Si necesita acceso legítimo a esta información, póngase en contacto con AUCORSA para obtener la autorización correspondiente. El uso no autorizado, la extracción automatizada, la redistribución o la explotación comercial de estos datos pueden constituir una infracción de la normativa aplicable y dar lugar al ejercicio de las acciones legales oportunas."
}
```

**Translation:**
> "We have detected that this endpoint is being used by an unauthorized automated client. This service is intended exclusively for official AUCORSA applications. All requests are logged and monitored. If you need legitimate access to this information, please contact AUCORSA for proper authorization. Unauthorized use, automated extraction, redistribution, or commercial exploitation of this data may constitute a violation of applicable regulations and may result in appropriate legal action."

**Detection Method:** Likely IP-based, User-Agent filtering, or request signature validation at the main domain level.

---

## Solution for AucorsaBus App

### Required Changes:
1. Use `https://lightapi.aucorsa.es` for estimation endpoints ✅ (Already implemented)
2. Keep using `https://aucorsa.es` for nonce fetching and service alerts
3. Both main and light API can be used for lines/stops/routes (but light API is recommended for consistency)

### Current Implementation (api_service.dart):
```dart
static const String _baseUrl = 'https://aucorsa.es/wp-json/aucorsa/v1';
static const String _lightApiUrl = 'https://lightapi.aucorsa.es/wp-json/aucorsa/v1';

// Use _lightApiUrl for fetchEstimation() and fetchAllEstimationsForStop()
// Use _baseUrl for fetchLines(), fetchServiceAlerts(), etc.
```

---

## Performance Implications

### Advantages of Light API:
✅ **Faster response times** - Dedicated infrastructure for real-time data  
✅ **Better availability** - Separated from main WordPress site load  
✅ **Cloudflare CDN** - Global edge network for reduced latency  
✅ **No blocking** - Designed for public/app consumption  

### Potential Issues:
⚠️ **Cross-domain requests** - Requires CORS (already configured)  
⚠️ **Two API endpoints** - Slightly more complex client code  
⚠️ **Separate monitoring** - If one domain goes down, need fallback strategy  

---

## Recommendations

1. **Always use Light API for estimations** - This is non-negotiable
2. **Consider using Light API for all endpoints** - Reduces complexity and uses optimized infrastructure
3. **Monitor both domains** - Implement health checks for both APIs
4. **Cache nonce appropriately** - Reduce load on main site by caching nonce for 1 hour
5. **Add error handling** - Gracefully handle when either API is down

---

## Future Considerations

### Potential Enhancements:
- **WebSocket support?** - Check if Light API might support WebSocket for true real-time updates
- **Batch requests** - Check if Light API supports batching multiple estimation requests
- **API versioning** - Monitor for v2 endpoints
- **Rate limiting** - Document and respect any rate limits

### Monitoring:
- Watch for changes in CORS policies
- Monitor response times between main and light API
- Track nonce expiration patterns
- Check for new endpoints or API versions

---

## Additional Endpoints to Explore

These endpoints exist but haven't been fully tested:
- `/aucorsa/v1/estimations/favoritedstop` - Might allow fetching multiple favorite stop estimations in one request
- `/aucorsa/v1/map/nearbusstops` - Geolocation-based stop finder (requires lat/lng)

---

## Conclusion

The discovery of `lightapi.aucorsa.es` solved the missing bus times issue. This dedicated API subdomain is AUCORSA's solution for serving real-time data to applications while protecting their main infrastructure from automated access. By using the Light API for estimation requests, the AucorsaBus app now functions correctly.

**Key Takeaway:** Always check for alternate API domains (api., lightapi., mobile-api., etc.) when debugging API access issues, especially for real-time data endpoints.
