import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { loggedOut } from '../../store/authSlice'
import { useAppDispatch, useAppSelector } from '../../store/hooks'
import './app-shell.css'

export default function AppShell({ children }: { children: ReactNode }) {
  const user = useAppSelector((state) => state.auth.user)
  const dispatch = useAppDispatch()

  return (
    <div className="shell">
      <header className="shell-header">
        <Link to="/" className="wordmark">
          Caramel <em>Kitchen</em>
        </Link>
        <div className="shell-header-right">
          {user && <span className="shell-greeting">Hi, {user.name.split(' ')[0]}</span>}
          <button type="button" className="shell-logout" onClick={() => dispatch(loggedOut())}>
            Log out
          </button>
        </div>
      </header>
      <main className="shell-main">{children}</main>
    </div>
  )
}
