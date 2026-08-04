import { useState } from 'react'
import { NavLink, Outlet } from 'react-router-dom'
import { loggedOut } from '../../store/authSlice'
import { useAppDispatch, useAppSelector } from '../../store/hooks'
import './admin-layout.css'

const NAV_LINKS = [
  { to: '/admin/recipes', label: 'Recipes' },
  { to: '/admin/recipes/new', label: 'New Recipe' },
]

export default function AdminLayout() {
  const [drawerOpen, setDrawerOpen] = useState(false)
  const user = useAppSelector((state) => state.auth.user)
  const dispatch = useAppDispatch()

  return (
    <div className="admin-shell">
      <header className="admin-navbar">
        <div className="admin-navbar-row">
          <NavLink to="/admin/recipes" className="wordmark wordmark-on-dark">
            Caramel <em>Kitchen</em>
          </NavLink>

          <nav className="admin-nav-links admin-nav-links-desktop" aria-label="Admin">
            {NAV_LINKS.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                end
                className={({ isActive }) => ['admin-nav-link', isActive ? 'is-active' : ''].join(' ')}
              >
                {link.label}
              </NavLink>
            ))}
          </nav>

          <div className="admin-navbar-right admin-navbar-right-desktop">
            {user && <span className="admin-user">{user.name}</span>}
            <button type="button" className="admin-logout" onClick={() => dispatch(loggedOut())}>
              Log out
            </button>
          </div>

          <button
            type="button"
            className="admin-menu-toggle"
            aria-expanded={drawerOpen}
            aria-controls="admin-drawer"
            aria-label={drawerOpen ? 'Close menu' : 'Open menu'}
            onClick={() => setDrawerOpen((open) => !open)}
          >
            <span className="admin-menu-bar" />
            <span className="admin-menu-bar" />
            <span className="admin-menu-bar" />
          </button>
        </div>

        {drawerOpen && (
          <div className="admin-drawer" id="admin-drawer">
            <nav className="admin-nav-links" aria-label="Admin (mobile)">
              {NAV_LINKS.map((link) => (
                <NavLink
                  key={link.to}
                  to={link.to}
                  end
                  onClick={() => setDrawerOpen(false)}
                  className={({ isActive }) => ['admin-nav-link', isActive ? 'is-active' : ''].join(' ')}
                >
                  {link.label}
                </NavLink>
              ))}
            </nav>
            <div className="admin-drawer-footer">
              {user && <span className="admin-user">{user.name}</span>}
              <button
                type="button"
                className="admin-logout"
                onClick={() => {
                  setDrawerOpen(false)
                  dispatch(loggedOut())
                }}
              >
                Log out
              </button>
            </div>
          </div>
        )}
      </header>

      <main className="admin-main">
        <Outlet />
      </main>
    </div>
  )
}
