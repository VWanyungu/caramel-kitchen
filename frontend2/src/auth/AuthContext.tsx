import { createContext, useCallback, useEffect, useState, type ReactNode } from 'react'
import { apiGet, apiPost, type AuthTokens } from '../lib/api'
import { tokenStorage } from '../lib/tokenStorage'
import type { AuthUser, LoginPayload, SignupPayload } from './types'

type AuthStatus = 'loading' | 'authenticated' | 'unauthenticated'

interface AuthContextValue {
  user: AuthUser | null
  status: AuthStatus
  isCreator: boolean
  login: (payload: LoginPayload) => Promise<void>
  signup: (payload: SignupPayload) => Promise<void>
  logout: () => void
}

export const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null)
  const [status, setStatus] = useState<AuthStatus>('loading')

  useEffect(() => {
    const accessToken = tokenStorage.getAccessToken()
    if (!accessToken) {
      setStatus('unauthenticated')
      return
    }

    apiGet<{ data: AuthUser }>('/me')
      .then(({ data }) => {
        setUser(data)
        setStatus('authenticated')
      })
      .catch(() => {
        tokenStorage.clear()
        setStatus('unauthenticated')
      })
  }, [])

  const login = useCallback(async (payload: LoginPayload) => {
    const { data } = await apiPost<{ data: { user: AuthUser; tokens: AuthTokens } }>(
      '/auth/login',
      payload,
      { auth: false },
    )
    tokenStorage.setTokens(data.tokens.access_token, data.tokens.refresh_token)
    setUser(data.user)
    setStatus('authenticated')
  }, [])

  const signup = useCallback(async (payload: SignupPayload) => {
    const { data } = await apiPost<{ data: { user: AuthUser; tokens: AuthTokens } }>(
      '/auth/register',
      payload,
      { auth: false },
    )
    tokenStorage.setTokens(data.tokens.access_token, data.tokens.refresh_token)
    setUser(data.user)
    setStatus('authenticated')
  }, [])

  const logout = useCallback(() => {
    tokenStorage.clear()
    setUser(null)
    setStatus('unauthenticated')
  }, [])

  const isCreator = user?.role === 'creator' || user?.role === 'admin'

  return (
    <AuthContext.Provider value={{ user, status, isCreator, login, signup, logout }}>
      {children}
    </AuthContext.Provider>
  )
}
