import { Navigate, Outlet } from 'react-router-dom'
import { useAppSelector } from '../store/hooks'
import { roleHomePath } from './roleHome'

export default function RedirectIfAuthed() {
  const user = useAppSelector((state) => state.auth.user)

  if (user) return <Navigate to={roleHomePath(user.role)} replace />
  return <Outlet />
}
