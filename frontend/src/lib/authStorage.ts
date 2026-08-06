import type { User } from '../types/auth'

const ACCESS_TOKEN_KEY = 'caramel.access_token'
const REFRESH_TOKEN_KEY = 'caramel.refresh_token'
const USER_KEY = 'caramel.user'

export interface StoredSession {
  user: User
  accessToken: string
  refreshToken: string
}

export function saveSession(session: StoredSession) {
  localStorage.setItem(ACCESS_TOKEN_KEY, session.accessToken)
  localStorage.setItem(REFRESH_TOKEN_KEY, session.refreshToken)
  localStorage.setItem(USER_KEY, JSON.stringify(session.user))
}

export function updateTokens(accessToken: string, refreshToken: string) {
  localStorage.setItem(ACCESS_TOKEN_KEY, accessToken)
  localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken)
}

export function clearSession() {
  localStorage.removeItem(ACCESS_TOKEN_KEY)
  localStorage.removeItem(REFRESH_TOKEN_KEY)
  localStorage.removeItem(USER_KEY)
}

export function loadSession(): StoredSession | null {
  const accessToken = localStorage.getItem(ACCESS_TOKEN_KEY)
  const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY)
  const rawUser = localStorage.getItem(USER_KEY)
  if (!accessToken || !refreshToken || !rawUser) return null

  try {
    const user = JSON.parse(rawUser) as User
    return { user, accessToken, refreshToken }
  } catch {
    return null
  }
}

export function getAccessToken(): string | null {
  return localStorage.getItem(ACCESS_TOKEN_KEY)
}

export function getRefreshToken(): string | null {
  return localStorage.getItem(REFRESH_TOKEN_KEY)
}
