export type UserRole = 'user' | 'creator' | 'admin'

export interface AuthUser {
  id: string
  email: string
  name: string
  avatar_url: string | null
  role: UserRole
  subscription_tier: string
  taste_survey_done: boolean
  goal_type: string | null
  dietary_flags: string[]
  email_verified: boolean
}

export interface SignupPayload {
  email: string
  password: string
  password_confirmation: string
  name: string
}

export interface LoginPayload {
  email: string
  password: string
}
