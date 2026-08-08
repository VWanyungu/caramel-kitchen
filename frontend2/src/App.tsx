import { Outlet, Route, Routes } from 'react-router-dom'
// import { Navbar } from './components/Navbar'
import { ProtectedRoute } from './auth/ProtectedRoute'
import { RoleRoute } from './auth/RoleRoute'
import { BrowsePage } from './features/browse/BrowsePage'
import { LoginPage } from './pages/LoginPage'
import { SignupPage } from './pages/SignupPage'
import { DashboardPage } from './pages/DashboardPage'
import { CreatorDashboardPage } from './pages/CreatorDashboardPage'
import { NotFoundPage } from './pages/NotFoundPage'
import { Navbar } from './features/browse/Navbar'

function AppShell() {
  return (
    <div className="min-h-screen bg-white">
      <Navbar />
      <Outlet />
    </div>
  )
}

function App() {
  return (
    <Routes>
      <Route path="/" element={<BrowsePage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/signup" element={<SignupPage />} />

      <Route element={<AppShell />}>
        {/* <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <DashboardPage />
            </ProtectedRoute>
          }
        /> */}
        <Route
          path="/creator"
          element={
            <RoleRoute>
              <CreatorDashboardPage />
            </RoleRoute>
          }
        />
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  )
}

export default App
