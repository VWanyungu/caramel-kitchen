export type Role = 'user' | 'creator' | 'admin'
export type SubscriptionTier = 'free' | 'premium' | 'creator_pro'

export interface User {
  id: string
  email: string
  name: string
  avatar_url: string | null
  role: Role
  subscription_tier: SubscriptionTier
  taste_survey_done: boolean
  goal_type: string | null
  dietary_flags: string[]
  email_verified: boolean
}

export interface AuthTokens {
  access_token: string
  refresh_token: string
  expires_in: number
  token_type: string
  user_id: string
  role: Role
  tier: SubscriptionTier
}

export interface AuthResponse {
  data: {
    user: User
    tokens: AuthTokens
  }
}

export interface ApiErrorBody {
  error?: string
  message?: string
  errors?: Record<string, string[]>
}

export interface LoginPayload {
  email: string
  password: string
}

export interface RegisterPayload {
  name: string
  email: string
  password: string
  password_confirmation: string
}
