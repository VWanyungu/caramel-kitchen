import type { Difficulty } from './recipe'

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
  taste_score?: number
  search_rank?: number
}

export type FilterContext = 'quick' | 'family' | 'meal_prep' | 'healthy'

export interface RecipeFilters {
  category: string
  course: string
  cooking_method: string
  dietary: string[]
  taste: string[]
  cuisine: string[]
  difficulty: string
  min_time: number | null
  max_time: number | null
  max_calories: number | null
  context: FilterContext | ''
}

export const emptyFilters: RecipeFilters = {
  category: '',
  course: '',
  cooking_method: '',
  dietary: [],
  taste: [],
  cuisine: [],
  difficulty: '',
  min_time: null,
  max_time: null,
  max_calories: null,
  context: '',
}

export interface FilterPreset {
  id: string
  name: string
  filters: RecipeFilters
  createdAt: string
}
