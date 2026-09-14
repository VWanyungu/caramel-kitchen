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
  category: string;
  categories: string[];
  dish_category: string;
  dish_categories: string[];
  course: string;
  meal: string | null;
  primary_method: string;
  difficulty: "beginner" | "intermediate" | "advanced";
  cuisine: string | null;
  cuisines: string[];
  cuisine_origin: string[];
  cost: number | null;      // Estimated cost
  estimated_cost: number | null;
  servings: number;
  serving_size: number;
  cooking_time: number;     // minutes
  cooking_time_mins: number;
  cook_time_mins: number;
  prep_time_mins: number;
  total_time_mins: number;
  taste_tags: string[];
  dietary: string[];
  dietary_requirements: string[];
  dietary_flags: string[];
  calories: number | null;
  avg_rating: number;
  rating_count: number;
  taste_score?: number;
  search_rank?: number;
  access_level: "free" | "premium";
  is_special: boolean;
  is_premium: boolean;
  is_locked: boolean;
  created_at: string;       // ISO8601 UTC
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
  category: string;
  categories: string[];
  dish_category: string;
  dish_categories: string[];
  course: string;
  meal: string | null;
  primary_method: string;
  secondary_method: string | null;
  difficulty: "beginner" | "intermediate" | "advanced";
  cuisine: string | null;
  cuisines: string[];
  cuisine_origin: string[];
  cost: number | null;      // Estimated cost
  estimated_cost: number | null;
  servings: number;
  serving_size: number;
  cooking_time: number;     // minutes
  cooking_time_mins: number;
  prep_time_mins: number;
  cook_time_mins: number;
  total_time_mins: number;
  taste_tags: string[];
  dietary: string[];
  dietary_requirements: string[];
  dietary_flags: string[];
  allergens: string[];
  allergy_alerts?: string[];
  calories: number | null;
  macros: Record<string, any>;
  avg_rating: number;
  rating_count: number;
  creator_id: string;
  access_level: "free" | "premium";
  is_special: boolean;
  is_premium: boolean;
  is_locked: boolean;
  published_at: string | null;
  featured_until: string | null;
  created_at: string;       // ISO8601 UTC
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
  favorite_count: number;
  save_count: number;
  is_favorited: boolean;           // true if authenticated caller favorited this video
  is_saved: boolean;               // true if authenticated caller saved this video to watch later
  creator_id: string | null;
  created_at: string;              // ISO8601 UTC
  updated_at: string;              // ISO8601 UTC
}
### `CollectionCard`
Represents a collection summary in list and discovery feeds.
```typescript
interface CollectionCard {
  id: string;                      // UUID
  name: string;
  slug: string;
  description: string | null;
  cover_image_url: string | null;  // Explicit cover or auto-derived from first item
  is_public: boolean;
  is_curated: boolean;
  is_premium: boolean;
  is_locked: boolean;
  is_seasonal: boolean;
  season_name: string | null;
  start_date: string | null;       // YYYY-MM-DD
  end_date: string | null;         // YYYY-MM-DD
  is_in_season: boolean;
  save_count: number;
  is_saved: boolean;
  item_count: number;
  recipe_count: number;
  video_count: number;
  author: {
    id: string;
    display_name: string;
    avatar_url: string | null;
  };
  inserted_at: string;             // ISO8601 UTC
  updated_at: string;              // ISO8601 UTC
}
```

### `CollectionDetail`
Represents the full collection details including all nested recipe and video items.
```typescript
interface CollectionDetail extends CollectionCard {
  items: CollectionItem[];
}

interface CollectionItem {
  id: string;                      // UUID
  collection_id: string;
  item_type: "recipe" | "video";
  position: number;
  notes: string | null;
  inserted_at: string;             // ISO8601 UTC
  recipe?: {
    id: string;
    title: string;
    slug: string;
    thumbnail_url: string | null;
    difficulty: string;
    total_time_mins: number;
    calories: number | null;
    avg_rating: number;
    is_special: boolean;
  };
  video?: {
    id: string;
    title: string;
    description: string | null;
    category: string;
    thumbnail_url: string | null;
    duration_secs: number | null;
    is_premium: boolean;
    is_special: boolean;
    youtube_video_id: string | null;
  };
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
- `meal` (string): Filter by meal type (`breakfast`, `lunch`, `dinner`, `snack`, `brunch`, `dessert`, `beverage`).
- `cooking_method` (string): Filter by primary or secondary cooking method (e.g., `baking`, `frying`).
- `dietary` (string): Comma-separated list of dietary flags (e.g., `vegan,gluten_free`). (Also accepts `dietary_requirements`).
- `taste` (string): Comma-separated list of taste tags (e.g., `savory,spicy`).
- `max_time` (integer): Maximum total time in minutes.
- `min_time` (integer): Minimum total time in minutes.
- `cooking_time` (integer): Maximum cooking time in minutes. (Also accepts `max_cooking_time`, `cook_time`).
- `min_cooking_time` (integer): Minimum cooking time in minutes.
- `cost` (number): Maximum estimated cost / budget limit. (Also accepts `budget`, `max_cost`).
- `min_cost` (number): Minimum cost.
- `servings` (integer): Filter by serving size. (Also accepts `serving_size`).
- `min_servings` (integer): Minimum servings.
- `max_servings` (integer): Maximum servings.
- `ingredient` (string): Search recipes containing ingredient matching name.
- `ingredients` (string): Comma-separated ingredient names that recipe must contain.
- `exclude_ingredients` (string): Comma-separated ingredient names to exclude.
- `difficulty` (string): Filter by difficulty level (`beginner`, `intermediate`, `advanced`).
- `cuisine` (string): Comma-separated list of cuisine origins (e.g., `west_african`, `italian`).
- `max_calories` (integer): Filter for recipes with calories <= X.
- `access_level` (string): Filter by access level: `"free"` or `"premium"`.
- `is_special` (boolean, optional): Filter for special premium recipes (`true`) or free standard recipes (`false`). Also accepts `is_premium`.
- `created_after` (ISO8601 / YYYY-MM-DD): Filter recipes created on or after this date. (Also accepts `created_from`, `from_date`, `start_date`).
- `created_before` (ISO8601 / YYYY-MM-DD): Filter recipes created on or before this date. (Also accepts `created_to`, `to_date`, `end_date`).
- `creation_date` (YYYY-MM-DD): Filter recipes created on an exact calendar date. (Also accepts `created_at`, `created_date`, `date`).
- `created_within` (string): Preset time window filter: `today`, `yesterday`, `this_week`, `last_7_days`, `this_month`, `last_30_days`, `this_year`. (Also accepts `date_range`).
- `sort` (string, optional): Order recipes by creation timestamp: `newest` (`created_at_desc`) or `oldest` (`created_at_asc`).

> **Access Gating (Issue #58 - Premium Recipes)**: Recipes marked with `is_special: true` (or `access_level: "premium"`) are restricted to premium subscribers. While premium recipes appear in list and search feeds with `access_level: "premium"`, `is_special: true`, `is_premium: true` and `is_locked: true`, accessing their full details via `GET /api/v1/recipes/:id` or `GET /api/v1/recipes/slug/:slug` by unauthenticated guests or free-tier users will return `402 Payment Required` with `error: "premium_required"`. Users with `premium`, `creator_pro`, or `admin` roles receive full access.
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

---

### 8.5 Video Interactions: Favourite & Saved Videos (Issue #112)

Fulfills GitHub Issue **#112** under parent issue **MAIN NAVIGATION BAR #62**. 
Enforces strict architectural and functional separation between:
- **Favourite Videos** (`action: "favorite"`): Videos the user explicitly enjoys and likes.
- **Saved Videos** (`action: "saved"`): Videos the user intends to bookmark and watch later.

A user can favorite a video, save it to watch later, or both simultaneously without collision. Both British (`/favourite`, `/favourites`) and American (`/favorite`, `/favorites`) spelling aliases are supported across all routes.

#### 1. Favorite a Video
**POST** `/api/v1/videos/:id/favorite`  
*Alias:* `POST /api/v1/videos/:id/favourite`  
*Requires `Authorization: Bearer <jwt_token>`.*

Idempotently marks a video as favorited and increments the video's `favorite_count`.

**Response (200 OK):**
```json
{
  "data": {
    "video_id": "c71a3375-39d7-463d-8eb9-db64a4bfba92",
    "action": "favorite",
    "status": "favorited",
    "is_favorited": true,
    "is_saved": false,
    "favorite_count": 42,
    "save_count": 18,
    "interacted_at": "2026-09-07T22:30:00Z"
  }
}
```

#### 2. Unfavorite a Video
**DELETE** `/api/v1/videos/:id/favorite`  
*Aliases:* `DELETE /api/v1/videos/:id/favourite`, `POST /api/v1/videos/:id/unfavorite`, `POST /api/v1/videos/:id/unfavourite`  
*Requires `Authorization: Bearer <jwt_token>`.*

Removes a video from the user's favorites and decrements `favorite_count`.

**Response (200 OK):**
```json
{
  "data": {
    "video_id": "c71a3375-39d7-463d-8eb9-db64a4bfba92",
    "action": "favorite",
    "status": "unfavorited",
    "is_favorited": false,
    "is_saved": false,
    "favorite_count": 41,
    "save_count": 18,
    "interacted_at": null
  }
}
```

#### 3. Save Video to Watch Later
**POST** `/api/v1/videos/:id/save`  
*Requires `Authorization: Bearer <jwt_token>`.*

Idempotently bookmarks a video for watch later and increments the video's `save_count`.

**Response (200 OK):**
```json
{
  "data": {
    "video_id": "c71a3375-39d7-463d-8eb9-db64a4bfba92",
    "action": "saved",
    "status": "saved",
    "is_favorited": true,
    "is_saved": true,
    "favorite_count": 41,
    "save_count": 19,
    "interacted_at": "2026-09-07T22:32:00Z"
  }
}
```

#### 4. Unsave Video
**DELETE** `/api/v1/videos/:id/save`  
*Alias:* `POST /api/v1/videos/:id/unsave`  
*Requires `Authorization: Bearer <jwt_token>`.*

Removes a video from watch later and decrements `save_count`.

**Response (200 OK):**
```json
{
  "data": {
    "video_id": "c71a3375-39d7-463d-8eb9-db64a4bfba92",
    "action": "saved",
    "status": "unsaved",
    "is_favorited": true,
    "is_saved": false,
    "favorite_count": 41,
    "save_count": 18,
    "interacted_at": null
  }
}
```

#### 5. Get Video Interaction Status
**GET** `/api/v1/videos/:id/status`  
*Alias:* `GET /api/v1/videos/:id/interaction`  
*Optional `Authorization: Bearer <jwt_token>`.*

Returns whether the calling user has favorited or saved the specified video, alongside aggregated counts. Unauthenticated guests receive `is_favorited: false` and `is_saved: false`.

**Response (200 OK):**
```json
{
  "data": {
    "video_id": "c71a3375-39d7-463d-8eb9-db64a4bfba92",
    "is_favorited": true,
    "is_saved": false,
    "favorite_count": 41,
    "save_count": 18
  }
}
```

#### 6. List User's Favorited Videos
**GET** `/api/v1/me/videos/favorites`  
*Aliases:* `GET /api/v1/me/videos/favourites`, `GET /api/v1/me/favorites/videos`  
*Requires `Authorization: Bearer <jwt_token>`.*

Retrieves a paginated list of videos favorited by the authenticated user, ordered from most recently favorited.

**Query Parameters:**
- `limit` (integer, default: 20, max: 100)
- `offset` (integer, default: 0)
- `category` (string, optional): Filter by canonical video category
- `search` (string, optional): Text match on title or description
- `order` (string, default: "newest", options: "newest", "oldest")

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "c71a3375-39d7-463d-8eb9-db64a4bfba92",
      "title": "Knife Skills 101",
      "category": "Cooking_Techniques",
      "is_premium": false,
      "is_locked": false,
      "is_favorited": true,
      "is_saved": false,
      "favorite_count": 41,
      "save_count": 18,
      "favorited_at": "2026-09-07T22:30:00Z",
      "video": { ... }
    }
  ],
  "meta": {
    "count": 1,
    "total_count": 1,
    "limit": 20,
    "offset": 0
  }
}
```

#### 7. List User's Saved Videos (Watch Later)
**GET** `/api/v1/me/videos/saved`  
*Alias:* `GET /api/v1/me/saved/videos`  
*Requires `Authorization: Bearer <jwt_token>`.*

Retrieves a paginated list of videos saved for later by the authenticated user, ordered from most recently saved.

**Query Parameters:**
- `limit` (integer, default: 20, max: 100)
- `offset` (integer, default: 0)
- `category` (string, optional)
- `search` (string, optional)
- `order` (string, default: "newest", options: "newest", "oldest")

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "893c52e1-4567-48bb-a63e-63f538562d91",
      "title": "Slow Braised Beef Short Ribs",
      "category": "Recipe_Videos",
      "is_premium": false,
      "is_locked": false,
      "is_favorited": false,
      "is_saved": true,
      "favorite_count": 12,
      "save_count": 35,
      "saved_at": "2026-09-07T22:32:00Z",
      "video": { ... }
    }
  ],
  "meta": {
    "count": 1,
    "total_count": 1,
    "limit": 20,
    "offset": 0
  }
}
```

---

## 9. Collections API (`/api/v1/collections`)

Collections allow users and curators to organize recipes and videos into thematic groups (e.g. "Weekend Italian Dinners", "Knife Skills & Sauces").

### 9.1 Public & Discovery Endpoints

#### List & Filter Collections
**GET** `/api/v1/collections`

Retrieves a paginated list of public collections matching query filters. If authenticated, private collections owned by the caller are also accessible.

**Query Parameters (Multi-Dimension Filters):**
- `limit` (integer, default: 20, max: 50): Number of results to return.
- `offset` (integer, default: 0): Offset for pagination.
- `search` or `q` (string): Text search matching collection name and description (case-insensitive).
- `recipe_id` (UUID): Filter collections containing a specific recipe.
- `video_id` (UUID): Filter collections containing a specific video.
- `user_id` or `creator_id` (UUID): Filter collections created by a specific user.
- `mine` (`true`): Returns only the authenticated user's collections (requires Bearer token).
- `is_curated` (boolean): Filter for staff-curated collections (`true`) or community collections (`false`).
- `is_premium` (boolean): Filter for premium collections (`true`) or free collections (`false`).
- `is_seasonal` (boolean): Filter for seasonal collections (`true`) or standard non-seasonal collections (`false`).
- `season_name` (string): Filter by specific season (e.g. `Christmas`, `Valentine's`, `Back to School`, `Ramadan`).
- `active_seasonal_only` (boolean, default `true`): Excludes out-of-season collections for regular viewers.
- `sort` (string): Sort order:
  - `newest` (default) - Most recently created
  - `oldest` - Earliest created
  - `name_asc` - Alphabetical by name
  - `name_desc` - Reverse alphabetical
  - `item_count` - Collections with the most items first

#### Seasonal Collections (Premium → Collections → Seasonal)
**GET** `/api/v1/collections/seasonal`  
*Alias:* `GET /api/v1/premium/collections/seasonal`

Fetches curated seasonal collections located under **Premium → Collections → Seasonal**.
Automatically validates whether the current calendar date falls within each collection's `start_date` and `end_date` before returning it to the user. Out-of-season collections are automatically hidden from general users.

Supported and seeded seasonal groups:
- **Christmas**: Christmas Dinner, Christmas Baking, Christmas Desserts, Christmas Drinks
- **Valentine's**: Date Night Dinner, Romantic Dinner, Valentine's Desserts, Valentine's Drinks
- **Back to School**: Student Breakfasts, Student Lunches, Budget Dinners, Back-to-School Meal Plan
- **Ramadan**: Iftar Collection, Suhoor Collection, Ramadan Drinks, Ramadan Desserts
*(Additional seasonal collections can be added over time).*

**Query Parameters:**
- `season_name` (string, optional): Filter to a specific season (e.g., `Back to School`, `Christmas`).
- `limit` (integer, default: 20, max: 50): Max items per page.
- `offset` (integer, default: 0): Pagination offset.

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "c1a23456-7890-4abc-def0-123456789abc",
      "name": "Student Breakfasts",
      "slug": "student_breakfasts",
      "description": "Quick, energizing, grab-and-go morning meals for busy student schedules.",
      "cover_image_url": "https://example.com/breakfast.jpg",
      "is_public": true,
      "is_curated": true,
      "is_premium": true,
      "is_locked": false,
      "is_seasonal": true,
      "season_name": "Back to School",
      "start_date": "2026-08-15",
      "end_date": "2026-10-15",
      "is_in_season": true,
      "save_count": 12,
      "is_saved": false,
      "recipe_count": 4,
      "video_count": 1,
      "total_items": 5,
      "author": {
        "id": "3b290df6-bce7-494f-a9cb-b66fe859d57a",
        "name": "Caramel Kitchen",
        "avatar_url": null,
        "role": "admin"
      },
      "created_at": "2026-08-15T00:00:00Z",
      "updated_at": "2026-08-15T00:00:00Z"
    }
  ],
  "seasons": [
    {
      "season_name": "Back to School",
      "collections": [
        {
          "id": "c1a23456-7890-4abc-def0-123456789abc",
          "name": "Student Breakfasts",
          "slug": "student_breakfasts",
          "is_seasonal": true,
          "season_name": "Back to School",
          "is_in_season": true
        }
      ]
    }
  ],
  "meta": {
    "current_date": "2026-09-08",
    "limit": 20,
    "offset": 0,
    "total_count": 4
  }
}
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "e7bf5412-f47a-4cba-a1c2-19e34e5695cf",
      "name": "Quick Weeknight Dinners",
      "slug": "quick-weeknight-dinners",
      "description": "30-minute meals and quick technique videos",
      "cover_image_url": "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
      "is_public": true,
      "is_curated": false,
      "is_premium": false,
      "is_locked": false,
      "item_count": 5,
      "recipe_count": 3,
      "video_count": 2,
      "author": {
        "id": "3b290df6-bce7-494f-a9cb-b66fe859d57a",
        "display_name": "Chef Maria",
        "avatar_url": "https://example.com/maria.jpg"
      },
      "inserted_at": "2026-09-06T00:00:00Z",
      "updated_at": "2026-09-06T00:00:00Z"
    }
  ],
  "meta": {
    "limit": 20,
    "offset": 0,
    "total_count": 1
  }
}
```

#### Get Collection Details
**GET** `/api/v1/collections/:id`

Retrieves a single collection by its UUID or unique slug.
- **Seasonal availability check**: If the collection is marked `is_seasonal: true`, the API validates that the current calendar date falls between `start_date` and `end_date`. Out-of-season collections return `404 Not Found` to regular users (only accessible to the owner or admins).
- **Premium access gate**: If marked `is_premium: true`, full access is granted to the creator, admins, and subscribers (`premium`, `creator_pro`); unauthenticated visitors and free users receive `402 Payment Required`.

**Response (200 OK):**
```json
{
  "data": {
    "id": "e7bf5412-f47a-4cba-a1c2-19e34e5695cf",
    "name": "Quick Weeknight Dinners",
    "slug": "quick-weeknight-dinners",
    "description": "30-minute meals and quick technique videos",
    "cover_image_url": "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
    "is_public": true,
    "is_curated": false,
    "is_premium": false,
    "is_locked": false,
    "item_count": 2,
    "recipe_count": 1,
    "video_count": 1,
    "author": {
      "id": "3b290df6-bce7-494f-a9cb-b66fe859d57a",
      "display_name": "Chef Maria",
      "avatar_url": "https://example.com/maria.jpg"
    },
    "inserted_at": "2026-09-06T00:00:00Z",
    "updated_at": "2026-09-06T00:00:00Z",
    "items": [
      {
        "id": "8d63c5aa-82fe-43dc-aa91-44755f11cefa",
        "collection_id": "e7bf5412-f47a-4cba-a1c2-19e34e5695cf",
        "item_type": "recipe",
        "position": 1,
        "notes": "Best served with fresh parmesan",
        "inserted_at": "2026-09-06T00:00:00Z",
        "recipe": {
          "id": "22ff7799-d4bc-4182-8eb1-fceb20531c08",
          "title": "Creamy Garlic Parmesan Pasta",
          "slug": "creamy-garlic-parmesan-pasta",
          "thumbnail_url": "https://example.com/pasta.jpg",
          "difficulty": "beginner",
          "total_time_mins": 25,
          "calories": 480,
          "avg_rating": 4.9,
          "is_special": false
        }
      },
      {
        "id": "c16fa0e9-b505-4c07-8822-259fc6c3c545",
        "collection_id": "e7bf5412-f47a-4cba-a1c2-19e34e5695cf",
        "item_type": "video",
        "position": 2,
        "notes": null,
        "inserted_at": "2026-09-06T00:00:00Z",
        "video": {
          "id": "0d635ea7-fa74-4b57-a9a3-5c8e31245ba9",
          "title": "How to Emulsify Pasta Sauces",
          "description": "Never break your pasta sauce again",
          "category": "Cooking_Techniques",
          "thumbnail_url": "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
          "duration_secs": 210,
          "is_premium": false,
          "is_special": false,
          "youtube_video_id": "dQw4w9WgXcQ"
        }
      }
    ]
  }
}
```

---

### 9.2 Authenticated Collection Endpoints
*All requests require `Authorization: Bearer <jwt_token>`.*

#### Get Current User's Collections
**GET** `/api/v1/me/collections`

Returns all collections created by the currently authenticated user (including private ones).

**Query Parameters:**
- `sort` (`newest`, `oldest`, `name_asc`, `name_desc`, `item_count`)
- `limit` (integer, default 20)
- `offset` (integer, default 0)

#### Create Collection
**POST** `/api/v1/collections`

Creates a new collection. Can optionally accept an initial batch of recipe and video IDs to populate the collection immediately.

**Request Body:**
```json
{
  "name": "Sunday Roasts & Braises",
  "description": "Comfort food recipes and roasting techniques",
  "is_public": true,
  "cover_image_url": "https://example.com/cover.jpg",
  "recipe_ids": ["22ff7799-d4bc-4182-8eb1-fceb20531c08"],
  "video_ids": ["0d635ea7-fa74-4b57-a9a3-5c8e31245ba9"]
}
```

*Note: `is_curated` cannot be set by standard users; only administrators can flag a collection as curated.*

**Response (201 Created):** Returns full `CollectionDetail` object.

#### Update Collection
**PUT** `/api/v1/collections/:id`

Updates collection metadata. Only the owner or an admin can update.

**Request Body:**
```json
{
  "name": "Ultimate Sunday Roasts",
  "is_public": false
}
```

**Response (200 OK):** Returns updated `CollectionDetail` object.

#### Delete Collection
**DELETE** `/api/v1/collections/:id`

Deletes a collection and its item associations. Only the owner or an admin can delete.

**Response (204 No Content)**

---

### 9.3 Collection Items Management
*All requests require `Authorization: Bearer <jwt_token>` and collection ownership (or admin).*

#### Add Item to Collection
**POST** `/api/v1/collections/:id/items`

Appends a recipe or video to the collection. Position is automatically calculated to place the item at the end of the collection if omitted.

**Request Body:**
```json
{
  "recipe_id": "22ff7799-d4bc-4182-8eb1-fceb20531c08",
  "notes": "Double the garlic in this recipe"
}
```
*Or for a video:*
```json
{
  "video_id": "0d635ea7-fa74-4b57-a9a3-5c8e31245ba9"
}
```

**Response (201 Created):**
```json
{
  "data": {
    "id": "8d63c5aa-82fe-43dc-aa91-44755f11cefa",
    "collection_id": "e7bf5412-f47a-4cba-a1c2-19e34e5695cf",
    "item_type": "recipe",
    "position": 3,
    "notes": "Double the garlic in this recipe",
    "recipe_id": "22ff7799-d4bc-4182-8eb1-fceb20531c08",
    "video_id": null,
    "inserted_at": "2026-09-06T00:00:00Z"
  }
}
```

#### Remove Item from Collection
**DELETE** `/api/v1/collections/:id/items/:item_id`

Removes a specific item from the collection by its item ID.

**Response (204 No Content)**

---

### 9.4 Collection Save & Interaction Endpoints
*All interaction requests require `Authorization: Bearer <jwt_token>` except status checking.*

#### Save a Collection
**POST** `/api/v1/collections/:id/save`

Saves a collection to the user's library. Idempotent. Increments `save_count`.

**Response (200 OK):**
```json
{
  "data": {
    "collection_id": "e7bf5412-f47a-4cba-a1c2-19e34e5695cf",
    "action": "saved",
    "status": "saved",
    "is_saved": true,
    "save_count": 1,
    "saved_at": "2026-09-07T23:45:00Z"
  }
}
```

#### Unsave a Collection
**DELETE** `/api/v1/collections/:id/save`  
*Alias:* `POST /api/v1/collections/:id/unsave`

Removes a collection from the user's library. Decrements `save_count`.

**Response (200 OK):**
```json
{
  "data": {
    "collection_id": "e7bf5412-f47a-4cba-a1c2-19e34e5695cf",
    "action": "saved",
    "status": "unsaved",
    "is_saved": false,
    "save_count": 0
  }
}
```

#### Get Collection Interaction Status
**GET** `/api/v1/collections/:id/status`

Returns whether the authenticated caller has saved this collection.

**Response (200 OK):**
```json
{
  "data": {
    "collection_id": "e7bf5412-f47a-4cba-a1c2-19e34e5695cf",
    "is_saved": true,
    "save_count": 1
  }
}
```

#### List User's Saved Collections
**GET** `/api/v1/me/collections/saved`  
*Alias:* `GET /api/v1/me/saved/collections`

Retrieves a paginated list of collections saved by the authenticated user.

---

## 10. Meal Plans Save & Interaction API (`/api/v1/meal-plans`)

### 10.1 Save & Status Endpoints
*All requests require `Authorization: Bearer <jwt_token>`.*

#### Save a Meal Plan
**POST** `/api/v1/meal-plans/:id/save`

Saves a meal plan to user's saved library. Idempotent. Increments `save_count`.

**Response (200 OK):**
```json
{
  "data": {
    "meal_plan_id": "4e1a6132-7204-4fa0-82a8-f7b587fcf39a",
    "action": "saved",
    "status": "saved",
    "is_saved": true,
    "save_count": 1,
    "saved_at": "2026-09-07T23:45:00Z"
  }
}
```

#### Unsave a Meal Plan
**DELETE** `/api/v1/meal-plans/:id/save`  
*Alias:* `POST /api/v1/meal-plans/:id/unsave`

Removes a meal plan from user's saved library. Decrements `save_count`.

**Response (200 OK):**
```json
{
  "data": {
    "meal_plan_id": "4e1a6132-7204-4fa0-82a8-f7b587fcf39a",
    "action": "saved",
    "status": "unsaved",
    "is_saved": false,
    "save_count": 0
  }
}
```

#### Get Meal Plan Status
**GET** `/api/v1/meal-plans/:id/status`

Returns interaction status (`is_saved` and `save_count`) for the given meal plan.

#### List User's Saved Meal Plans
### 10.2 Generation & Management Endpoints
*All requests require `Authorization: Bearer <jwt_token>`.*

#### Generate a 7-Day Meal Plan
**POST** `/api/v1/meal-plans/generate`

AI-generates a personalized 7-day meal plan strictly restricted to real recipe database entries, factoring in user taste preferences, dietary requirements, allergen exclusions, budget, and subscription tier.

**Request Body:**
```json
{
  "goal_type": "balanced",
  "budget": 50.00,
  "servings": 2,
  "cuisine": "west_african",
  "dietary": ["halal"],
  "max_cooking_time": 45,
  "difficulty": "intermediate",
  "exclude_ingredients": ["shellfish"]
}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `goal_type` | string | Yes | One of `gym_muscle`, `weight_loss`, `weight_gain`, `balanced`, `keto` |
| `budget` / `max_cost` | number | No | Target weekly budget or maximum cost for recipes |
| `servings` | integer | No | Target serving size per meal (defaults to recipe serving size) |
| `cuisine` / `cuisines` | string \| string[] | No | Preferred cuisine filter |
| `dietary` / `dietary_requirements` | string[] | No | Dietary flags override (e.g. `["vegan", "halal"]`) |
| `max_cooking_time` | integer | No | Maximum cooking time in minutes |
| `difficulty` | string | No | `beginner`, `intermediate`, or `advanced` |
| `exclude_ingredients` | string[] | No | Specific ingredients to exclude from candidate recipes |

**AI Database Restriction & Safety Guarantees:**
1. **Strict Candidate Set**: The AI prompt is populated strictly with matching candidate recipes from the database. Free users only receive recipes with `access_level: "free"`, `is_premium: false`.
2. **Auto-Repair & Hallucination Guard**: Every single `recipe_id` in the returned plan is validated against the database candidate pool. If an LLM hallucinates an invalid ID or violates tier gating, the backend auto-repairs the meal slot using the best compatible recipe from the slot pool.
3. **Structured Recipe Enrichment**: Each meal slot in the response is automatically enriched with structured recipe metadata (`recipe_title`, `cost`, `thumbnail_url`, `cooking_time`, `calories`, `meal`, `cuisine`, `difficulty`, `access_level`).

**Response (201 Created):**
```json
{
  "data": {
    "id": "7b2a9d81-8e31-4190-8cb2-e3a19fc29b71",
    "name": "Balanced Plan — 2026-09-10",
    "goal_type": "balanced",
    "calorie_target": 2000,
    "total_cost": "42.50",
    "estimated_total_cost": "42.50",
    "budget": "50.00",
    "is_active": true,
    "is_premium": false,
    "is_ai_generated": true,
    "save_count": 0,
    "week_start": "2026-09-10",
    "week_end": "2026-09-16",
    "macro_split": {
      "protein_pct": 30,
      "carbs_pct": 40,
      "fat_pct": 30,
      "estimated_total_cost": "42.50",
      "average_daily_cost": "6.07",
      "budget": "50.00"
    },
    "days": [
      {
        "date_offset": 0,
        "estimated_calories": 1980,
        "estimated_cost": "6.10",
        "meals": [
          {
            "slot": "breakfast",
            "recipe_id": "a1b2c3d4-0000-0000-0000-000000000001",
            "recipe_title": "Spiced Millet Porridge",
            "servings": 2,
            "cost": "1.50",
            "estimated_cost": "1.50",
            "calories": 420,
            "meal": "breakfast",
            "course": "breakfast",
            "cuisine": "west_african",
            "cooking_time": 20,
            "difficulty": "beginner",
            "access_level": "free",
            "thumbnail_url": "https://images.caramelkitchen.com/porridge.jpg"
          },
          {
            "slot": "lunch",
            "recipe_id": "a1b2c3d4-0000-0000-0000-000000000002",
            "recipe_title": "Grilled Chicken & Jollof",
            "servings": 2,
            "cost": "2.80",
            "estimated_cost": "2.80",
            "calories": 650,
            "meal": "lunch",
            "course": "main",
            "cuisine": "west_african",
            "cooking_time": 35,
            "difficulty": "intermediate",
            "access_level": "free",
            "thumbnail_url": "https://images.caramelkitchen.com/jollof.jpg"
          },
          {
            "slot": "dinner",
            "recipe_id": "a1b2c3d4-0000-0000-0000-000000000003",
            "recipe_title": "Egusi Soup with Fish",
            "servings": 2,
            "cost": "1.80",
            "estimated_cost": "1.80",
            "calories": 710,
            "meal": "dinner",
            "course": "main",
            "cuisine": "west_african",
            "cooking_time": 40,
            "difficulty": "intermediate",
            "access_level": "free",
            "thumbnail_url": "https://images.caramelkitchen.com/egusi.jpg"
          },
          {
            "slot": "snack",
            "recipe_id": "a1b2c3d4-0000-0000-0000-000000000004",
            "recipe_title": "Roasted Spiced Plantain Chips",
            "servings": 1,
            "cost": "0.50",
            "estimated_cost": "0.50",
            "calories": 200,
            "meal": "snack",
            "course": "snack",
            "cuisine": "west_african",
            "cooking_time": 15,
            "difficulty": "beginner",
            "access_level": "free",
            "thumbnail_url": "https://images.caramelkitchen.com/chips.jpg"
          }
        ]
      }
    ]
  }
}
```

#### Swap a Meal Slot
**PATCH** `/api/v1/meal-plans/:id/swap`

Swaps a single meal slot with an alternative recipe strictly restricted to available recipes matching the meal slot, user tier, and user preferences.

**Request Body:**
```json
{
  "day_offset": 0,
  "slot": "lunch"
}
```

**Response (200 OK):**
Returns the full meal plan with the slot swapped and updated daily/weekly costs and calories.


