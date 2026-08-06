import { api } from './api'
import type { RecipeCard, RecipeFilters } from '../types/browse'

interface ListResponse {
  data: RecipeCard[]
  meta: { count: number; after_id?: string }
}

export function buildFilterParams(filters: Partial<RecipeFilters>): Record<string, string | number> {
  const params: Record<string, string | number> = {}

  if (filters.category) params.category = filters.category
  if (filters.course) params.course = filters.course
  if (filters.cooking_method) params.cooking_method = filters.cooking_method
  if (filters.difficulty) params.difficulty = filters.difficulty
  if (filters.dietary?.length) params.dietary = filters.dietary.join(',')
  if (filters.taste?.length) params.taste = filters.taste.join(',')
  if (filters.cuisine?.length) params.cuisine = filters.cuisine.join(',')
  if (filters.min_time) params.min_time = filters.min_time
  if (filters.max_time) params.max_time = filters.max_time
  if (filters.max_calories) params.max_calories = filters.max_calories
  if (filters.context) params.context = filters.context

  return params
}

export async function listRecipes(
  filters: Partial<RecipeFilters>,
  extra?: { limit?: number; after_id?: string },
): Promise<ListResponse> {
  const { data } = await api.get<ListResponse>('/recipes', {
    params: { ...buildFilterParams(filters), ...extra },
  })
  return data
}

export async function searchRecipes(
  q: string,
  filters: Partial<RecipeFilters>,
  extra?: { limit?: number; offset?: number },
): Promise<ListResponse> {
  const { data } = await api.get<ListResponse>('/recipes/search', {
    params: { q, ...buildFilterParams(filters), ...extra },
  })
  return data
}

export async function getCategoryCounts(): Promise<Record<string, number>> {
  const { data } = await api.get<{ data: Record<string, number> }>('/categories')
  return data.data
}

export async function getDishTypeCounts(): Promise<Record<string, number>> {
  const { data } = await api.get<{ data: Record<string, number> }>('/dish-types')
  return data.data
}
