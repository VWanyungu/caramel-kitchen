import type { ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import { ProtectedRoute } from './ProtectedRoute'
import { useAuth } from './useAuth'

export function RoleRoute({ children }: { children: ReactNode }) {
  const { isCreator } = useAuth()

  return (
    <ProtectedRoute>
      {isCreator ? children : <Navigate to="/dashboard" replace />}
    </ProtectedRoute>
  )
}
