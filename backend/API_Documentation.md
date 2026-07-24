# Caramel Kitchen API Documentation (v2.0)

This document provides a static reference for the core backend API endpoints and data schemas. 

> **Note**: A live, interactive version of this documentation is always available by running the local server (`mix phx.server`) and navigating to `http://localhost:4000/api/swagger`.

## Base URL
All API requests should be prefixed with `/api/v1`

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
