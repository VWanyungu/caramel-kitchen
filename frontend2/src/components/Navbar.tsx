import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/useAuth'

export function Navbar() {
  const { status, user, isCreator, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/')
  }

  return (
    <header className="border-b border-gray-200 bg-white">
      <nav className="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
        <Link to="/" className="text-lg font-semibold text-gray-900">
          Caramel Kitchen
        </Link>

        <div className="flex items-center gap-4 text-sm">
          {status === 'authenticated' ? (
            <>
              <Link to="/dashboard" className="text-gray-600 hover:text-gray-900">
                Dashboard
              </Link>
              {isCreator && (
                <Link to="/creator" className="text-gray-600 hover:text-gray-900">
                  Creator Tools
                </Link>
              )}
              <span className="text-gray-400">{user?.name}</span>
              <button
                onClick={handleLogout}
                className="rounded-md bg-gray-900 px-3 py-1.5 text-white hover:bg-gray-700"
              >
                Log out
              </button>
            </>
          ) : (
            <>
              <Link to="/login" className="text-gray-600 hover:text-gray-900">
                Log in
              </Link>
              <Link
                to="/signup"
                className="rounded-md bg-gray-900 px-3 py-1.5 text-white hover:bg-gray-700"
              >
                Sign up
              </Link>
            </>
          )}
        </div>
      </nav>
    </header>
  )
}
