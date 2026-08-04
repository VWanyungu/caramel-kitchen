import { useEffect } from 'react'
import { Navigate, Route, Routes } from 'react-router-dom'
import LoginPage from './pages/LoginPage'
import SignupPage from './pages/SignupPage'
import UserHomePage from './pages/UserHomePage'
import RecipeTablePage from './pages/admin/RecipeTablePage'
import RecipeFormPage from './pages/admin/RecipeFormPage'
import AdminLayout from './components/admin/AdminLayout'
import NotFoundPage from './pages/NotFoundPage'
import RequireAuth from './routes/RequireAuth'
import RequireAdmin from './routes/RequireAdmin'
import RedirectIfAuthed from './routes/RedirectIfAuthed'
import RoleRedirect from './routes/RoleRedirect'
import { loggedOut } from './store/authSlice'
import { useAppDispatch } from './store/hooks'

function App() {
  const dispatch = useAppDispatch()

  useEffect(() => {
    const onSessionExpired = () => dispatch(loggedOut())
    window.addEventListener('caramel:session-expired', onSessionExpired)
    return () => window.removeEventListener('caramel:session-expired', onSessionExpired)
  }, [dispatch])

  return (
    <Routes>
      <Route path="/" element={<RoleRedirect />} />

      <Route element={<RedirectIfAuthed />}>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/signup" element={<SignupPage />} />
      </Route>

      <Route element={<RequireAuth />}>
        <Route path="/home" element={<UserHomePage />} />
        <Route element={<RequireAdmin />}>
          <Route path="/admin" element={<AdminLayout />}>
            <Route index element={<Navigate to="recipes" replace />} />
            <Route path="recipes" element={<RecipeTablePage />} />
            <Route path="recipes/new" element={<RecipeFormPage mode="create" />} />
            <Route path="recipes/:id/edit" element={<RecipeFormPage mode="edit" />} />
          </Route>
        </Route>
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  )
}

export default App
