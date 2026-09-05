# Caramel Kitchen API Documentation (v2.0)

This document provides a static reference for the core backend API endpoints and data schemas. 

> **Note**: A live, interactive version of this documentation is always available by running the local server (`mix phx.server`) and navigating to `http://localhost:4000/api/swagger`.

## Base URL & Hosting Environments

* **Production (Render Live URL):** `https://caramel-kitchen.onrender.com`
* **Local Development:** `http://localhost:4000`

All API requests should be prefixed with `/api/v1` (e.g., `https://caramel-kitchen.onrender.com/api/v1/recipes`).


## Rate Limiting & Security
To ensure system stability, the API enforces rate limits on a per-user (or per-IP for unauthenticated) basis using a sliding window.
- **Auth Endpoints:** 10 requests per minute
- **Core API Endpoints:** 100 requests per minute
- **AI Endpoints:** 20 requests per minute

When limits are exceeded, the API returns an HTTP `429 Too Many Requests` response with a standard error object and the following headers:
- `x-ratelimit-limit`: The maximum requests allowed in the current window.
- `retry-after`: Seconds to wait before retrying (usually `60`).

*Note: The rate limiter features a fail-open fallback. In the event of a caching infrastructure failure, requests will bypass the rate limit to ensure core services remain online.*

### Security Headers & Payload Limits
All API responses are strictly hardened with native Phoenix security headers, including:
- **Strict-Transport-Security (HSTS)**
- **X-Frame-Options: SAMEORIGIN** (prevents clickjacking)
- **X-Content-Type-Options: nosniff** (prevents MIME-sniffing)

To protect against Denial of Service (DoS) and Out-Of-Memory (OOM) attacks, JSON and URL-Encoded request payloads are strictly limited to **2MB**. Larger payloads (up to 50MB) are only permitted on specific `multipart/form-data` endpoints designed for file/video uploads.

---

## 1. Core Schemas

### `RecipeCard`
Represents a simplified recipe object returned in list views (search, feed, trending).
```typescript
interface RecipeCard {
  id: string;               // UUID
  slug: string;
  title: string;
  thumbnail_url: string | null;
  dish_category: string;
  course: string;
  primary_method: string;
  difficulty: "beginner" | "intermediate" | "advanced";
  total_time_mins: number;
  taste_tags: string[];
  dietary_flags: string[];
  calories: number | null;
  avg_rating: number;
  rating_count: number;
  cuisine_origin: string[];
  taste_score?: number;
  search_rank?: number;
  is_special: boolean;
  is_premium: boolean;
  is_locked: boolean;
}
```

### `RecipeDetail`
Represents the full recipe object returned in detail views.
```typescript
interface RecipeDetail {
  id: string;               // UUID
  slug: string;
  title: string;
  description: string | null;
  thumbnail_url: string | null;
  video_url: string | null;
  video_duration_secs: number | null;
  dish_category: string;
  course: string;
  primary_method: string;
  secondary_method: string | null;
  difficulty: "beginner" | "intermediate" | "advanced";
  prep_time_mins: number;
  cook_time_mins: number;
  total_time_mins: number;
  serving_size: number;
  taste_tags: string[];
  dietary_flags: string[];
  allergens: string[];
  allergy_alerts?: string[];
  calories: number | null;
  macros: Record<string, any>;
  avg_rating: number;
  rating_count: number;
  cuisine_origin: string[];
  creator_id: string;
  published_at: string | null;
  featured_until: string | null;
  view_count: number;
  save_count: number;
  cook_count: number;
  ingredients: {
    name: string;
    quantity: string;
    unit: string | null;
    notes: string | null;
  }[];
  steps: {
    order: number;
    instruction: string;
    duration_minutes: number | null;
    tip: string | null;
  }[];
  is_special: boolean;
  is_premium: boolean;
  is_locked: boolean;
}
```

### `Video`
Represents a cooking or tutorial video with category metadata, YouTube embedding, and tier-based access status.
```typescript
interface Video {
  id: string;                      // UUID
  title: string;
  description: string | null;
  category: 
    | "Recipe_Videos"
    | "Cooking_Tips"
    | "Cooking_Techniques"
    | "Quick Cooking"
    | "Tutorials"
    | "Premium_Videos"
    | "Masterclasses"
    | "Caramel_Academy";
  is_premium: boolean;
  is_special: boolean;
  is_locked: boolean;              // true if content is gated for current user tier
  yt_embed_code: string | null;    // null if is_locked is true
  youtube_video_id: string | null;
  video_url: string | null;        // null if is_locked is true
  video_embed_url: string | null;  // null if is_locked is true
  thumbnail_url: string | null;
  duration_secs: number | null;
  view_count: number;
  creator_id: string | null;
  created_at: string;              // ISO8601 UTC
  updated_at: string;              // ISO8601 UTC
}
```

### `ErrorResponse`
Returned when a request fails or is unauthorized.
```typescript
interface ErrorResponse {
  error: string;  // Error code or message
}
```

---

## 2. Recipe Discovery & Filtering

### `GET /api/v1/recipes`
List recipes. If the request is authenticated via Bearer token, it returns a personalised feed based on the user's calculated taste vectors and engagement scores.

**Query Parameters (Multi-Dimension Filters):**
- `limit` (integer, default: 20, max: 50): Maximum number of items to return.
- `after_id` (string): Pagination cursor.
- `category` (string): Filter by dish category (e.g., `rice_dishes`, `baked_goods`).
- `course` (string): Filter by dish type/course (e.g., `main`, `starter`, `dessert`).
- `cooking_method` (string): Filter by primary or secondary cooking method (e.g., `baking`, `frying`).
- `dietary` (string): Comma-separated list of dietary flags (e.g., `vegan,gluten_free`). Returns recipes matching ALL provided flags.
- `taste` (string): Comma-separated list of taste tags (e.g., `savory,spicy`). Returns recipes matching ALL provided tags.
- `max_time` (integer): Maximum total time in minutes.
- `min_time` (integer): Minimum total time in minutes.
- `difficulty` (string): Filter by difficulty level (`beginner`, `intermediate`, `advanced`).
- `cuisine` (string): Comma-separated list of cuisine origins.
- `max_calories` (integer): Filter for recipes with calories <= X.
- `is_special` (boolean, optional): Filter for special premium recipes (`true`) or free standard recipes (`false`). Also accepts `is_premium`.

> **Access Gating (Issue #58 - Premium Recipes)**: Recipes marked with `is_special: true` are restricted to premium subscribers. While special recipes appear in list and search feeds with `is_special: true` and `is_locked: true`, accessing their full details via `GET /api/v1/recipes/:id` or `GET /api/v1/recipes/slug/:slug` by unauthenticated guests or free-tier users will return `402 Payment Required` with `error: "premium_required"`. Users with `premium`, `creator_pro`, or `admin` roles receive full access.
- `context` (string): Special UI context filters. Maps to multiple parameters under the hood:
  - `quick`: Total time <= 30 mins
  - `family`: Serving size >= 4
  - `meal_prep`: Serving size >= 4 AND total time <= 60 mins
  - `healthy`: Calories <= 500

**Response (200 OK):**
```json
{
  "data": [
    { /* RecipeCard Object */ }
  ],
  "meta": {
    "count": 20,
    "after_id": "uuid-string"
  }
}
```

---

### `GET /api/v1/recipes/search`
Search for recipes across titles, descriptions, ingredients, and various tags (taste, dietary flags, dish category, course, and cuisine origin).

**Query Parameters:**
- `q` (string, required): The search term.
- `limit` (integer, default: 20): Maximum number of items.
- `offset` (integer, default: 0): Pagination offset.
- *(Supports all the multi-dimensional filters listed in `GET /recipes` above)*

**Response (200 OK):**
```json
{
  "data": [
    { /* RecipeCard Object */ }
  ],
  "meta": {
    "query": "search term",
    "limit": 20,
    "offset": 0
  }
}
```

---

### `GET /api/v1/recipes/trending`
Get trending recipes based on engagement scores.

**Query Parameters:**
- `limit` (integer, default: 10): Maximum number of items to return.

**Response (200 OK):**
```json
{
  "data": [
    { /* RecipeCard Object */ }
  ]
}
```

---

### `GET /api/v1/recipes/:id`
Get full details for a single recipe by its UUID.

**Path Parameters:**
- `id` (string, required): Recipe UUID.

**Response (200 OK):**
```json
{
  "data": { /* Full RecipeDetail Object */ }
}
```

---

### `GET /api/v1/recipes/slug/:slug`
Get full details for a single recipe using its URL slug.

**Path Parameters:**
- `slug` (string, required): Recipe URL slug (e.g., `spicy-caramel-chicken`).

**Response (200 OK):**
```json
{
  "data": { /* Full RecipeDetail Object */ }
}
```

---

## 3. Categories & Dish Types

### `GET /api/v1/categories`
Returns an aggregation of all active recipe categories and their respective live counts.

**Response (200 OK):**
```json
{
  "data": {
    "dinner": 15,
    "dessert": 8,
    "breakfast": 5
  }
}
```

### `GET /api/v1/dish-types`
Returns an aggregation of recipe dish types (`course`) and their live counts.

**Response (200 OK):**
```json
{
  "data": {
    "main": 34,
    "starter": 10,
    "dessert": 8
  }
}
```

### `GET /api/v1/cuisines`
Returns a list of all active cuisines for client discovery and filtering.

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "7bf3fa43-0c46-4c40-9689-d4cbf239f8aa",
      "type": "cuisine",
      "name": "West African",
      "slug": "west_african",
      "description": null,
      "icon_url": null,
      "display_order": 1,
      "is_active": true,
      "created_at": "2026-09-06T00:00:00Z",
      "updated_at": "2026-09-06T00:00:00Z"
    }
  ]
}
```

### `GET /api/v1/dietary-tags`
Returns a list of all active dietary tags (e.g. `vegetarian`, `vegan`, `gluten_free`, `halal`).

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "e2298710-85fb-4187-8bc8-b4bc8f0fe923",
      "type": "dietary_tag",
      "name": "Vegetarian",
      "slug": "vegetarian",
      "description": null,
      "icon_url": null,
      "display_order": 1,
      "is_active": true,
      "created_at": "2026-09-06T00:00:00Z",
      "updated_at": "2026-09-06T00:00:00Z"
    }
  ]
}
```

### `GET /api/v1/difficulties`
Returns a list of active recipe difficulty levels (`beginner`, `intermediate`, `advanced`).

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "1f8f74a0-53ae-4322-9218-a6d5954620f4",
      "type": "difficulty",
      "name": "Beginner",
      "slug": "beginner",
      "description": null,
      "icon_url": null,
      "display_order": 1,
      "is_active": true,
      "created_at": "2026-09-06T00:00:00Z",
      "updated_at": "2026-09-06T00:00:00Z"
    }
  ]
}
```

---

## 4. Authentication & Headers

Protected routes (like personalized feeds, saving recipes, or submitting taste surveys) require a standard JWT Bearer token:

**Headers:**
```http
Authorization: Bearer <your-jwt-token>
```

---

## 5. Subscriptions & Monetisation

### `GET /api/v1/subscription`
Gets the authenticated user's current subscription status.

**Response (200 OK):**
```json
{
  "data": {
    "plan": "free",
    "status": "active",
    "current_period_end": null,
    "stripe_customer_id": null
  }
}
```

### `POST /api/v1/subscription/checkout`
Creates a Stripe Checkout Session for a given plan (default: `premium`) and returns the session URL.

**Request Body:**
```json
{
  "plan": "premium"
}
```

**Response (200 OK):**
```json
{
  "data": {
    "checkout_url": "https://checkout.stripe.com/c/pay/cs_test_...",
    "session_id": "cs_test_..."
  }
}
```

### `POST /api/v1/subscription/mpesa-checkout`
Initiates a Safaricom M-Pesa Express (STK Push) prompt on the user's phone for the requested plan.

**Request Body:**
```json
{
  "phone_number": "254712345678",
  "plan": "premium"
}
```

**Response (200 OK):**
```json
{
  "message": "STK Push initiated",
  "merchant_request_id": "12345-67890-1"
}
```

### `GET /api/v1/subscription/portal`
Creates a Stripe Billing Portal Session for managing an existing active Stripe subscription.

**Response (200 OK):**
```json
{
  "data": {
    "portal_url": "https://billing.stripe.com/p/session/..."
  }
}
```

---

## 6. Notifications

### Server-Sent Events (SSE) Stream
Establish a persistent connection to receive real-time push notifications.
The backend will send JSON payloads prefixed with `data: ` and periodic heartbeat `: ping` events to keep the connection alive.

**GET** `/api/v1/notifications/stream`
Requires `Authorization: Bearer <token>`

#### Client Example (JavaScript)
```javascript
const eventSource = new EventSource('/api/v1/notifications/stream', {
  headers: {
    Authorization: 'Bearer <your_token>' // Note: EventSource browser API doesn't support headers easily, 
                                         // you may need to use a library like @microsoft/fetch-event-source 
                                         // or pass the token via a query param if adapted.
  }
});

eventSource.onmessage = function(event) {
  const notification = JSON.parse(event.data);
  console.log("New Notification:", notification.title, notification.body);
};
```

#### Event Payload Schema
```typescript
{
  title: string;
  body: string;
  data: {
    type: string;
    [key: string]: any;
  }
}
```
---

## 7. Admin & SuperAdmin Portal

All administrative endpoints require a Bearer token belonging to a user with `role: "admin"` (SuperAdmin). Requests from standard users (`role: "user"`) will return an HTTP `403 Forbidden` error.

### 7.1 Recipe Management & CMS (`/api/v1/admin/recipes`)

#### List Creator / Admin Recipes
**GET** `/api/v1/admin/recipes`  
Query Parameters:
- `status` *(optional)*: `"draft"` | `"scheduled"` | `"live"` | `"archived"`

#### Create Recipe
**POST** `/api/v1/admin/recipes`  
Request Body: Full recipe payload including title, description, `dish_categories`, course, meal, primary_method, difficulty, prep_time_mins, cook_time_mins, serving_size, taste_tags, dietary_flags, allergens, ingredients, and steps.

#### Get Admin Recipe Detail
**GET** `/api/v1/admin/recipes/:id`

#### Update Recipe
**PUT** `/api/v1/admin/recipes/:id`  
Request Body: JSON map of recipe fields to update.

#### Publish Recipe
**POST** `/api/v1/admin/recipes/:id/publish`  
Enforces pre-flight checks: recipe must have a `video_url` attached and at least one entry in `taste_tags`.

#### Archive Recipe
**POST** `/api/v1/admin/recipes/:id/archive`  
Changes recipe status to `"archived"` and triggers media storage cleanup for `video_key`.

#### Delete Recipe
**DELETE** `/api/v1/admin/recipes/:id`

---

### 7.2 Video Integration & Processing Pipeline (`/api/v1/admin/videos`)

#### YouTube Video & Embed Support
Recipes support both direct YouTube URLs (watch links, `youtu.be` links, `embed` URLs) and full HTML `<iframe>` snippets.
When creating or updating a recipe (`video_url`), you can pass a YouTube `<iframe>` embed string:
```html
<iframe width="1337" height="752" src="https://www.youtube.com/embed/t4NSPbreDgE" title="Recipe Video" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
```
The backend automatically normalizes the input and provides the following structured fields in recipe responses:
- `video_url`: `"https://www.youtube.com/watch?v=t4NSPbreDgE"` (Direct watch link to open YouTube app/browser)
- `video_embed_url`: `"https://www.youtube.com/embed/t4NSPbreDgE"` (URL for in-app webview player)
- `video_iframe_html`: HTML `<iframe>` snippet ready for in-app webview embedding
- `youtube_video_id`: `"t4NSPbreDgE"`

#### Presigned Upload URL (Direct S3 Storage)
**POST** `/api/v1/admin/videos/presigned-url`  
Request Body:
```json
{
  "filename": "recipe_video.mp4",
  "content_type": "video/mp4",
  "size_bytes": 104857600
}
```
*Note: Maximum allowed file size is 500MB. Allowed content types: `video/mp4`, `video/quicktime`, `video/webm`, `video/mpeg`.*

#### Video Processed Webhook
**POST** `/api/v1/admin/videos/processed`  
Called by media transcoding worker upon completion.  
Request Body:
```json
{
  "recipe_id": "uuid",
  "video_key": "s3-key",
  "duration_secs": 120,
  "thumbnail_key": "s3-thumb-key"
}
```

---

### 7.3 Creator & Platform Analytics (`/api/v1/admin/analytics`)

#### Overview Analytics Dashboard
**GET** `/api/v1/admin/analytics`  
Query Parameters:
- `period` *(optional)*: `"last_7_days"` | `"last_30_days"` (default: `"last_30_days"`)

#### Recipe Performance
**GET** `/api/v1/admin/analytics/recipes`  
Query Parameters:
- `limit` *(optional)*: integer (default: `10`)
- `period` *(optional)*: `"last_7_days"` | `"last_30_days"` (default: `"last_30_days"`)

#### Taste Distribution Graph Data
**GET** `/api/v1/admin/analytics/taste`

#### AI Query Statistics
**GET** `/api/v1/admin/analytics/ai`  
Query Parameters:
- `period` *(optional)*: `"last_7_days"` | `"last_30_days"` (default: `"last_7_days"`)

---

### 7.4 SuperAdmin User Administration (`/api/v1/superadmin/users`)

#### List Users
**GET** `/api/v1/superadmin/users`  
Query Parameters:
- `role` *(optional)*: `"user"` | `"admin"`
- `tier` *(optional)*: `"free"` | `"premium"` | `"creator_pro"`
- `active` *(optional)*: `"true"` | `"false"`

#### Update User Role
**PUT** `/api/v1/superadmin/users/:id/role`  
Request Body:
```json
{
  "role": "admin"
}
```

#### Deactivate User Account
**DELETE** `/api/v1/superadmin/users/:id`  
Request Body:
```json
{
  "reason": "Violation of terms"
}
```

---

### 7.5 System Health & Telemetry (`/api/v1/superadmin/system/stats`)

#### System Telemetry Stats
**GET** `/api/v1/superadmin/system/stats`  
Returns live server telemetry including:
- `users`: User growth statistics
- `taste_dist`: Global taste distribution vector
- `oban_queues`: Status of background queues (`default`, `content`, `email`, `analytics`, `maintenance`, `ai`)
- `cache_stats`: Redis hit/miss rates, connected clients, used memory
- `node_info`: Erlang node name, Elixir/Erlang runtime version, server uptime, process count, memory usage in MB

---

### 7.6 Taxonomy Management (`/api/v1/admin/{resource}`)
Admin CRUD operations for managing system taxonomies:
- Categories: `/api/v1/admin/categories`
- Cuisines: `/api/v1/admin/cuisines`
- Dietary Tags: `/api/v1/admin/dietary-tags`
- Difficulties: `/api/v1/admin/difficulties`

#### List Taxonomies
**GET** `/api/v1/admin/categories`  
**GET** `/api/v1/admin/cuisines`  
**GET** `/api/v1/admin/dietary-tags`  
**GET** `/api/v1/admin/difficulties`  
Query Parameters:
- `active_only` *(optional)*: `"true"` | `"false"` (default: `"false"` for admin)
- `search` *(optional)*: search query string (matches `name` or `slug`)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "b3e34b97-84a1-4323-93d3-ae5560b4c3e8",
      "type": "category",
      "name": "Egg Dishes",
      "slug": "egg_dishes",
      "description": "Scrambled, fried, poached, omelettes",
      "icon_url": "https://example.com/icons/egg.svg",
      "display_order": 1,
      "is_active": true,
      "created_at": "2026-09-06T00:00:00Z",
      "updated_at": "2026-09-06T00:00:00Z"
    }
  ]
}
```

#### Get Single Taxonomy
**GET** `/api/v1/admin/categories/:id`  
**GET** `/api/v1/admin/cuisines/:id`  
**GET** `/api/v1/admin/dietary-tags/:id`  
**GET** `/api/v1/admin/difficulties/:id`

#### Create Taxonomy Item
**POST** `/api/v1/admin/categories`  
**POST** `/api/v1/admin/cuisines`  
**POST** `/api/v1/admin/dietary-tags`  
**POST** `/api/v1/admin/difficulties`  
Request Body:
```json
{
  "name": "Brunch Specialties",
  "slug": "brunch_specialties",
  "description": "Weekend brunch recipes",
  "icon_url": "https://example.com/icons/brunch.svg",
  "display_order": 15,
  "is_active": true
}
```
*Note: `slug` is optional and will be automatically derived from `name` if omitted.*

#### Update Taxonomy Item
**PUT** `/api/v1/admin/categories/:id`  
**PUT** `/api/v1/admin/cuisines/:id`  
**PUT** `/api/v1/admin/dietary-tags/:id`  
**PUT** `/api/v1/admin/difficulties/:id`  
Request Body:
```json
{
  "name": "Updated Name",
  "display_order": 20,
  "is_active": false
}
```

#### Delete Taxonomy Item
**DELETE** `/api/v1/admin/categories/:id`  
**DELETE** `/api/v1/admin/cuisines/:id`  
**DELETE** `/api/v1/admin/dietary-tags/:id`  
**DELETE** `/api/v1/admin/difficulties/:id`  
Response: `204 No Content`

---

## 8. Video Management & Streaming

### 8.1 Video Categories
Caramel Kitchen supports 8 canonical video categories:
- `Recipe_Videos`
- `Cooking_Tips`
- `Cooking_Techniques`
- `Quick Cooking` *(also accepts `Quick_Cooking`)*
- `Tutorials`
- `Premium_Videos`
- `Masterclasses`
- `Caramel_Academy`

### 8.2 Video Access Levels (Sub-Issue #105)
- **Free Videos (`is_premium: false`)**: Available to all users, including unauthenticated guests. Returns full iframe `yt_embed_code` and `video_embed_url`.
- **Premium / Special Videos (`is_premium: true` or `is_special: true`)**:
  - Unauthenticated guests and users on the `free` tier receive a preview response with `is_locked: true`, while `yt_embed_code`, `video_url`, and `video_embed_url` are masked (`null`).
  - Authenticated users with `premium` or `creator_pro` tier, as well as administrators, receive the unlocked payload (`is_locked: false`) with full embed codes and streaming links.

### 8.3 Public Video Browsing (`/api/v1/videos`)

#### List Videos
**GET** `/api/v1/videos`

Supports multi-factor filtering, fuzzy text search, and pagination.

**Query Parameters:**
- `category` *(optional)*: Filter by exact category name (e.g. `Cooking_Tips`, `Quick Cooking`).
- `search` *(optional)*: Case-insensitive trigram search matching against `title` and `description`.
- `upload_date` *(optional)*: Filter by time period (`"today"`, `"this_week"`, `"this_month"`, `"this_year"`) or ISO date (`YYYY-MM-DD`).
- `is_premium` *(optional)*: `"true"` | `"false"`
- `is_special` *(optional)*: `"true"` | `"false"`
- `order` *(optional)*: `"newest"` (default) | `"oldest"` | `"popular"`
- `limit` *(optional, default: 20, max: 100)*: Number of items to return.
- `offset` *(optional, default: 0)*: Number of items to skip.
- `page` *(optional, default: 1)*: Page number (alternative to offset).

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "e4b1bf10-a294-4d8b-b8aa-852fc74b971a",
      "title": "Mastering French Sauces",
      "description": "Comprehensive guide to classic mother sauces",
      "category": "Masterclasses",
      "is_premium": true,
      "is_special": true,
      "is_locked": false,
      "yt_embed_code": "<iframe width=\"100%\" height=\"100%\" src=\"https://www.youtube.com/embed/dQw4w9WgXcQ\" ...></iframe>",
      "youtube_video_id": "dQw4w9WgXcQ",
      "video_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "video_embed_url": "https://www.youtube.com/embed/dQw4w9WgXcQ",
      "thumbnail_url": "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
      "duration_secs": 920,
      "view_count": 142,
      "creator_id": "c18712db-f2ca-4fb3-98ff-888f45f6e859",
      "created_at": "2026-09-06T00:00:00Z",
      "updated_at": "2026-09-06T00:00:00Z"
    }
  ],
  "meta": {
    "count": 1,
    "total_count": 45,
    "limit": 20,
    "offset": 0
  }
}
```

#### List Video Categories
**GET** `/api/v1/videos/categories`

Returns all 8 categories with the count of videos published in each.

**Response (200 OK):**
```json
{
  "data": [
    {"name": "Recipe_Videos", "count": 24},
    {"name": "Cooking_Tips", "count": 18},
    {"name": "Cooking_Techniques", "count": 12},
    {"name": "Quick Cooking", "count": 15},
    {"name": "Tutorials", "count": 9},
    {"name": "Premium_Videos", "count": 8},
    {"name": "Masterclasses", "count": 6},
    {"name": "Caramel_Academy", "count": 4}
  ]
}
```

#### Get Video Details
**GET** `/api/v1/videos/:id`

Returns full details for a single video. Automatically increments view count. Respects access tier rules.

---

### 8.4 Admin Video Management (`/api/v1/admin/videos`)
*Requires `Authorization: Bearer <jwt_token>` with role `admin`.*

#### Create Video
**POST** `/api/v1/admin/videos`

**Request Body:**
```json
{
  "title": "Knife Skills 101",
  "description": "Essential cuts every home cook should know",
  "category": "Cooking_Techniques",
  "yt_embed_code": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "is_premium": false,
  "duration_secs": 360
}
```

*Note: `yt_embed_code` accepts full YouTube watch URLs, short links (`youtu.be/...`), embed URLs, raw 11-char video IDs, or full `<iframe>` HTML snippets. YouTube IDs and thumbnails are automatically extracted and populated.*

**Response (201 Created):** Returns the created `Video` object.

#### Update Video
**PUT** `/api/v1/admin/videos/:id`

**Request Body:**
```json
{
  "title": "Advanced Knife Skills & Maintenance",
  "category": "Masterclasses",
  "is_premium": true
}
```

**Response (200 OK):** Returns the updated `Video` object.

#### Delete Video
**DELETE** `/api/v1/admin/videos/:id`

**Response (200 OK):**
```json
{
  "data": {
    "id": "e4b1bf10-a294-4d8b-b8aa-852fc74b971a",
    "message": "Video deleted successfully"
  }
}
```

