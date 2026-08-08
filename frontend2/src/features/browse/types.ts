export type Difficulty = 'beginner' | 'intermediate' | 'advanced'

export interface RecipeCard {
  id: string
  slug: string
  title: string
  thumbnail_url: string | null
  dish_category: string
  course: string
  primary_method: string
  difficulty: Difficulty
  total_time_mins: number
  taste_tags: string[]
  dietary_flags: string[]
  calories: number | null
  avg_rating: number
  rating_count: number
  cuisine_origin: string[]
}

export interface RecipeFilters {
  q: string
  category: string
  cuisine: string[]
  difficulty: Difficulty | ''
  dietary: string[]
  minTime: number | undefined
  maxTime: number | undefined
}

export const EMPTY_FILTERS: RecipeFilters = {
  q: '',
  category: '',
  cuisine: [],
  difficulty: '',
  dietary: [],
  minTime: undefined,
  maxTime: undefined,
}

export function hasActiveFilters(filters: RecipeFilters): boolean {
  return (
    filters.category !== '' ||
    filters.cuisine.length > 0 ||
    filters.difficulty !== '' ||
    filters.dietary.length > 0 ||
    filters.minTime !== undefined ||
    filters.maxTime !== undefined
  )
}
