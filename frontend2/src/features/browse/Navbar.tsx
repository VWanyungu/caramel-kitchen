import { Plus, User } from 'lucide-react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../auth/useAuth'
import { Button } from '../../components/ui'

export function Navbar() {
  const { status, user, isCreator, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/')
  }

  const isAuthenticated = status === 'authenticated'

  return (
    <header className="border-b border-taupe/20 bg-white">
      <nav className="mx-auto flex items-center justify-between px-8 lg:px-16 py-4">
        <div className="flex items-end gap-8">
          <Link to="/" className="font-display text-2xl italic text-ink">
            Caramel Kitchen
          </Link>

          {isAuthenticated && (
            <div className="flex items-center gap-6 font-sans text-sm font-semibold">
              <Link to="/dashboard" className="text-gray-600 hover:text-ink transition-colors">
                Dashboard
              </Link>
              {isCreator && (
                <Link to="/creator" className="text-gray-600 hover:text-ink transition-colors">
                  Creator Tools
                </Link>
              )}
            </div>
          )}
        </div>

        <div className="flex items-center gap-3 font-sans text-sm">
          {isAuthenticated ? (
            <>
              {isCreator && (
                <Link to="/creator">
                  <Button variant="dark" size="sm" icon={<Plus size={16} />}>
                    Create New
                  </Button>
                </Link>
              )}

              <Button variant="outline" size="sm" onClick={handleLogout}>
                Log out
              </Button>

              <div className="relative flex items-center justify-center mx-1" title={`${user?.name} (Online)`}>
                <div className="rounded-full ring-2 ring-emerald-500 ring-offset-2 ring-offset-white p-[1px] flex items-center justify-center">
                  {user?.avatar_url ? (
                    <img
                      src={user.avatar_url}
                      alt={user.name}
                      className="h-8 w-8 rounded-full object-cover"
                    />
                  ) : (
                    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-caramel/15 font-sans text-xs font-bold text-caramel uppercase">
                      {user?.name ? user.name.charAt(0) : <User size={16} />}
                    </div>
                  )}
                </div>
                <span className="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full bg-emerald-500 ring-2 ring-white" />
              </div>
            </>
          ) : (
            <>
              <Link to="/login">
                <Button variant="outline" size="sm">
                  Log in
                </Button>
              </Link>

              <Link to="/signup">
                <Button variant="dark" size="sm">
                  Sign up
                </Button>
              </Link>
            </>
          )}
        </div>
      </nav>
    </header>
  )
}
