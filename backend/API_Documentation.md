# Caramel Kitchen API Documentation (v2.0)

This document provides a static reference for the core backend API endpoints and data schemas. 

> **Note**: A live, interactive version of this documentation is always available by running the local server (`mix phx.server`) and navigating to `http://localhost:4000/api/swagger`.

## Base URL
All API requests should be prefixed with `/api/v1`

---

## 1. Core Schemas

### `Recipe`
Represents a recipe in the Caramel Kitchen platform.
```typescript
interface Recipe {
  id: string;               // UUID
  title: string;
  description: string;
  status: "draft" | "live" | "archived";
  dish_category: string;
  difficulty: "beginner" | "intermediate" | "advanced";
  prep_time_mins: number;
  cook_time_mins: number;
  calories: number;
  taste_tags: string[];     // Array of taste profile strings
  dietary_flags: string[];  // Array of dietary flags (e.g., "vegan", "gluten-free")
  thumbnail_url: string;
  video_url: string | null;
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

## 2. Recipe Endpoints

### `GET /api/v1/recipes`
List recipes. If the request is authenticated via Bearer token, it returns a personalised feed based on the user's calculated taste vectors.

**Query Parameters:**
- `limit` (integer, default: 20): Maximum number of items to return.
- `after_id` (string): Pagination cursor.
- `category` (string): Filter by dish category.

**Response (200 OK):**
```json
{
  "data": [
    { /* Recipe Object */ }
  ],
  "meta": {
    "count": 20,
    "after_id": "uuid-string"
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
    { /* Recipe Object */ }
  ]
}
```

---

### `GET /api/v1/recipes/search`
Search for recipes by query string and specific filters.

**Query Parameters:**
- `q` (string, required): The search term.
- `limit` (integer, default: 20): Maximum number of items.
- `offset` (integer, default: 0): Pagination offset.
- `dietary` (string): Comma-separated list of dietary flags.
- `taste` (string): Comma-separated list of taste tags.
- `difficulty` (string): e.g., "beginner".
- `max_time` (integer): Maximum total time in minutes.

**Response (200 OK):**
```json
{
  "data": [
    { /* Recipe Object */ }
  ],
  "meta": {
    "query": "search term",
    "limit": 20,
    "offset": 0
  }
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
  "data": { /* Full Recipe Object with ingredients, steps, macros, etc. */ }
}
```
**Response (404 Not Found):**
```json
{
  "error": "Not Found"
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
  "data": { /* Full Recipe Object */ }
}
```

---

### `GET /api/v1/categories`
Returns an aggregation of all active recipe categories and their respective counts.

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

---

## 3. Authentication & Headers

Protected routes (like personalized feeds, saving recipes, or submitting taste surveys) require a standard JWT Bearer token:

**Headers:**
```http
Authorization: Bearer <your-jwt-token>
```
