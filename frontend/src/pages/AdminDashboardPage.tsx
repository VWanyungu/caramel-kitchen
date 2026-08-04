import AppShell from '../components/app/AppShell'
import { useAppSelector } from '../store/hooks'

export default function AdminDashboardPage() {
  const user = useAppSelector((state) => state.auth.user)

  return (
    <AppShell>
      <div className="shell-card">
        <p className="shell-eyebrow">Admin dashboard</p>
        <h1 className="shell-title">Welcome, {user?.name.split(' ')[0]}</h1>
        <p className="shell-subtitle">
          Recipe uploads, content scheduling, and analytics will live here. Only accounts with
          the admin role can reach this page.
        </p>
      </div>
    </AppShell>
  )
}
