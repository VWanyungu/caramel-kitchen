import { createAsyncThunk, createSlice, type PayloadAction } from '@reduxjs/toolkit'
import { api, extractErrorMessage } from '../lib/api'
import { clearSession, loadSession, saveSession } from '../lib/authStorage'
import type { AuthResponse, LoginPayload, RegisterPayload, User } from '../types/auth'

const existingSession = loadSession()

interface AuthState {
  user: User | null
  accessToken: string | null
  refreshToken: string | null
  status: 'idle' | 'loading' | 'succeeded' | 'failed'
  error: string | null
}

const initialState: AuthState = {
  user: existingSession?.user ?? null,
  accessToken: existingSession?.accessToken ?? null,
  refreshToken: existingSession?.refreshToken ?? null,
  status: 'idle',
  error: null,
}

export const loginUser = createAsyncThunk('auth/login', async (payload: LoginPayload, { rejectWithValue }) => {
  try {
    const { data } = await api.post<AuthResponse>('/auth/login', payload)
    return data.data
  } catch (error) {
    return rejectWithValue(extractErrorMessage(error, 'Invalid email or password.'))
  }
})

export const registerUser = createAsyncThunk(
  'auth/register',
  async (payload: RegisterPayload, { rejectWithValue }) => {
    try {
      const { data } = await api.post<AuthResponse>('/auth/register', payload)
      return data.data
    } catch (error) {
      return rejectWithValue(extractErrorMessage(error, 'Could not create your account.'))
    }
  },
)

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    loggedOut(state) {
      clearSession()
      state.user = null
      state.accessToken = null
      state.refreshToken = null
      state.status = 'idle'
      state.error = null
    },
    clearAuthError(state) {
      state.error = null
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(loginUser.pending, (state) => {
        state.status = 'loading'
        state.error = null
      })
      .addCase(loginUser.rejected, (state, action: PayloadAction<unknown>) => {
        state.status = 'failed'
        state.error = (action.payload as string) ?? 'Invalid email or password.'
      })
      .addCase(registerUser.pending, (state) => {
        state.status = 'loading'
        state.error = null
      })
      .addCase(registerUser.rejected, (state, action: PayloadAction<unknown>) => {
        state.status = 'failed'
        state.error = (action.payload as string) ?? 'Could not create your account.'
      })
      .addMatcher(
        (action): action is ReturnType<typeof loginUser.fulfilled> | ReturnType<typeof registerUser.fulfilled> =>
          action.type === loginUser.fulfilled.type || action.type === registerUser.fulfilled.type,
        (state, action) => {
          const { user, tokens } = action.payload
          state.status = 'succeeded'
          state.error = null
          state.user = user
          state.accessToken = tokens.access_token
          state.refreshToken = tokens.refresh_token
          saveSession({ user, accessToken: tokens.access_token, refreshToken: tokens.refresh_token })
        },
      )
  },
})

export const { loggedOut, clearAuthError } = authSlice.actions
export default authSlice.reducer
