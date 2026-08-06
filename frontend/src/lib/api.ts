import axios, { AxiosError, type InternalAxiosRequestConfig } from 'axios'
import { clearSession, getAccessToken, getRefreshToken, updateTokens } from './authStorage'
import type { AuthTokens } from '../types/auth'

const baseURL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:4000/api/v1'

export const api = axios.create({
  baseURL,
  withCredentials: true,
})

api.interceptors.request.use((config) => {
  const token = getAccessToken()
  if (token) {
    config.headers.set('Authorization', `Bearer ${token}`)
  }
  return config
})

type RetryableConfig = InternalAxiosRequestConfig & { _retried?: boolean }

let refreshPromise: Promise<string> | null = null

async function refreshAccessToken(): Promise<string> {
  const refreshToken = getRefreshToken()
  if (!refreshToken) throw new Error('no_refresh_token')

  const { data } = await axios.post<{ data: AuthTokens }>(`${baseURL}/auth/refresh`, {
    refresh_token: refreshToken,
  })
  updateTokens(data.data.access_token, data.data.refresh_token)
  return data.data.access_token
}

api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as RetryableConfig | undefined

    const isAuthRoute = originalRequest?.url?.includes('/auth/')
    if (error.response?.status !== 401 || !originalRequest || originalRequest._retried || isAuthRoute) {
      return Promise.reject(error)
    }

    originalRequest._retried = true

    try {
      refreshPromise ??= refreshAccessToken().finally(() => {
        refreshPromise = null
      })
      const newAccessToken = await refreshPromise
      originalRequest.headers.set('Authorization', `Bearer ${newAccessToken}`)
      return api(originalRequest)
    } catch {
      clearSession()
      window.dispatchEvent(new Event('caramel:session-expired'))
      return Promise.reject(error)
    }
  },
)

export function extractErrorMessage(error: unknown, fallback = 'Something went wrong. Please try again.') {
  if (axios.isAxiosError(error)) {
    const body = error.response?.data as { message?: string; error?: string } | undefined
    return body?.message ?? body?.error ?? fallback
  }
  return fallback
}
