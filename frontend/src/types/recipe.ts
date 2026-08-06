export type RecipeStatus = 'draft' | 'scheduled' | 'live' | 'archived'
export type Difficulty = 'beginner' | 'intermediate' | 'advanced'

export interface Ingredient {
  name: string
  quantity: string
  unit?: string
  notes?: string
}

export interface Step {
  order: number
  instruction: string
  duration_minutes?: number | null
  tip?: string | null
}

export interface AdminRecipe {
  id: string
  slug: string
  title: string
  description: string | null
  status: RecipeStatus
  dish_category: string | null
  course: string | null
  primary_method: string
  secondary_method: string | null
  difficulty: Difficulty
  cuisine_origin: string[]
  taste_tags: string[]
  dietary_flags: string[]
  allergens: string[]
  calories: number | null
  macros: Record<string, unknown>
  prep_time_mins: number | null
  cook_time_mins: number | null
  total_time_mins: number | null
  thumbnail_url: string | null
  video_url: string | null
  video_key: string | null
  video_duration_secs: number | null
  view_count: number
  save_count: number
  cook_count: number
  avg_rating: number
  published_at: string | null
  scheduled_at: string | null
  inserted_at: string
  updated_at: string
}
