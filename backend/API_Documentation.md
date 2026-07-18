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
    { /* Recipe Object */ }
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
