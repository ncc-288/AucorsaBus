# Aucorsa API Technical Documentation

This document describes the unofficial REST API used by `aucorsa.es` to provide real-time bus information in Córdoba, Spain.

## Base URL
`https://aucorsa.es/wp-json/aucorsa/v1`

## Authentication (Nonce-based)
The API is protected by a WordPress nonce. To make successful requests, you must first obtain a valid nonce from the main website.

1. **Obtain Nonce**: Perform a GET request to `https://aucorsa.es/`.
2. **Extract**: Look for the string `"ajax_nonce":"[NONCE_VALUE]"` in the HTML source.
3. **Usage**: Append `_wpnonce=[NONCE_VALUE]` to all subsequent API calls.
4. **Expiry**: Nonces typically expire after 12-24 hours.

---

## Endpoints

### 1. Line Directory
Returns a list of all available bus lines.

**Example Request:**
`GET /autocompletion/line?term=&_wpnonce=f2e3d4c5`

**Sample Output:**
```json
[
  { "id": "706", "label": "1ㅤFÁTIMA - TENDILLAS" },
  { "id": "707", "label": "2ㅤFÁTIMA - C. SANITARIA" }
]
```

### 2. Global Stop Search
Search for any bus stop.

**Example Request:**
`GET /autocompletion/stop?term=Tendillas&_wpnonce=f2e3d4c5`

**Sample Output:**
```json
[
  { "id": "105", "label": "105ㅤTENDILLAS (C.S.)" },
  { "id": "210", "label": "210ㅤTENDILLAS (V.S.)" }
]
```

### 3. Line Route & Direction Mapping (The "Two Ways")
This is the most complex endpoint. It returns geographic data and stop sequences. 

**Example Request:**
`GET /map/nodes?line_id=706&mode=complete&_wpnonce=f2e3d4c5`

**The "Direction Logic":**
The response is an array of clusters (usually 2). Each cluster represents one "way" or direction of the line.
- **`routeLabel`**: An HTML string like `<div class="route-label">... → FÁTIMA </div>`.
- **Extraction**: We use regex `→\s*(.+?)<` to extract the destination name (e.g., "FÁTIMA") to label our tabs as "Hacia FÁTIMA".
- **`features`**: A GeoJSON-like list. Features with `geometry.type == "Point"` are the bus stops in their correct operational sequence for that direction.

**Sample Mapping Logic:**
```dart
// direction 0 = 'Ida' (Outbound)
// direction 1 = 'Vuelta' (Inbound)
```

### 4. Real-time Estimations
Returns arrival estimations. This endpoint returns **escaped HTML string** inside the JSON response.

**Example Request (All lines at a stop):**
`GET /estimations/stop?stop_id=105&_wpnonce=f2e3d4c5`

**Example Request (Specific line at a stop):**
`GET /estimations/stop?line=706&current_line=706&stop_id=105&_wpnonce=f2e3d4c5`

**Sample HTML Output (Parsed):**
```html
<div class="ppp-container">
  <div class="ppp-line-number">1</div>
  <div class="ppp-line-route">FÁTIMA - TENDILLAS</div>
  <div class="ppp-estimation">Próximo autobús: <strong>9 minutos</strong></div>
  <div class="ppp-estimation">Siguiente autobús: <strong>22 minutos</strong></div>
</div>
```

---

## Technical Considerations
- **Wait Time Format**: The wait time can be "ahora" (for immediate arrivals) or "X minutos".
- **Empty States**: Look for strings containing "Sin servicio" or the CSS class `ppp-no-estimations` to detect stops without current service.
- **CORS Proxy**: When accessing from a web browser, a proxy like `corsproxy.io` is required as Aucorsa does not provide a liberal CORS policy.
