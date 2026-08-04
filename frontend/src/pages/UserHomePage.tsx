import AppShell from '../components/app/AppShell'
import { useAppSelector } from '../store/hooks'

export default function UserHomePage() {
  const user = useAppSelector((state) => state.auth.user)

  return (
    <AppShell>
      <div className="shell-card">
        <p className="shell-eyebrow">Your kitchen</p>
        <h1 className="shell-title">Welcome back, {user?.name.split(' ')[0]}</h1>
        <p className="shell-subtitle">
          Your home feed, taste profile, and meal plans will live here. This is the signed-in
          landing page for everyone with a standard account.
        </p>
      </div>
    </AppShell>
  )
}
