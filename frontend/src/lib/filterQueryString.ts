import { emptyFilters, type RecipeFilters } from '../types/browse'

export function filtersToSearchParams(filters: RecipeFilters): URLSearchParams {
  const params = new URLSearchParams()

  if (filters.category) params.set('category', filters.category)
  if (filters.course) params.set('course', filters.course)
  if (filters.cooking_method) params.set('cooking_method', filters.cooking_method)
  if (filters.difficulty) params.set('difficulty', filters.difficulty)
  if (filters.dietary.length) params.set('dietary', filters.dietary.join(','))
  if (filters.taste.length) params.set('taste', filters.taste.join(','))
  if (filters.cuisine.length) params.set('cuisine', filters.cuisine.join(','))
  if (filters.min_time) params.set('min_time', String(filters.min_time))
  if (filters.max_time) params.set('max_time', String(filters.max_time))
  if (filters.max_calories) params.set('max_calories', String(filters.max_calories))
  if (filters.context) params.set('context', filters.context)

  return params
}

export function searchParamsToFilters(params: URLSearchParams): RecipeFilters {
  const list = (key: string) => {
    const raw = params.get(key)
    return raw ? raw.split(',').filter(Boolean) : []
  }
  const num = (key: string) => {
    const raw = params.get(key)
    return raw ? Number(raw) : null
  }

  return {
    ...emptyFilters,
    category: params.get('category') ?? '',
    course: params.get('course') ?? '',
    cooking_method: params.get('cooking_method') ?? '',
    difficulty: params.get('difficulty') ?? '',
    dietary: list('dietary'),
    taste: list('taste'),
    cuisine: list('cuisine'),
    min_time: num('min_time'),
    max_time: num('max_time'),
    max_calories: num('max_calories'),
    context: (params.get('context') as RecipeFilters['context']) ?? '',
  }
}

export function countActiveFilters(filters: RecipeFilters): number {
  return (
    (filters.category ? 1 : 0) +
    (filters.course ? 1 : 0) +
    (filters.cooking_method ? 1 : 0) +
    (filters.difficulty ? 1 : 0) +
    (filters.min_time ? 1 : 0) +
    (filters.max_time ? 1 : 0) +
    (filters.max_calories ? 1 : 0) +
    (filters.context ? 1 : 0) +
    filters.dietary.length +
    filters.taste.length +
    filters.cuisine.length
  )
}
