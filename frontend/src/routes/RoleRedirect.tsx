import { Navigate } from 'react-router-dom'
import { useAppSelector } from '../store/hooks'
import { roleHomePath } from './roleHome'

export default function RoleRedirect() {
  const user = useAppSelector((state) => state.auth.user)

  if (!user) return <Navigate to="/login" replace />
  return <Navigate to={roleHomePath(user.role)} replace />
}
