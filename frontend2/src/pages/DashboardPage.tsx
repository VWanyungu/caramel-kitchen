import { useAuth } from '../auth/useAuth'

export function DashboardPage() {
  const { user } = useAuth()

  return (
    <div className="mx-auto max-w-2xl px-6 py-16">
      <h1 className="text-2xl font-semibold text-gray-900">Welcome, {user?.name}</h1>
      <dl className="mt-6 space-y-2 text-sm text-gray-600">
        <div className="flex gap-2">
          <dt className="font-medium text-gray-900">Email</dt>
          <dd>{user?.email}</dd>
        </div>
        <div className="flex gap-2">
          <dt className="font-medium text-gray-900">Role</dt>
          <dd>{user?.role}</dd>
        </div>
        <div className="flex gap-2">
          <dt className="font-medium text-gray-900">Subscription</dt>
          <dd>{user?.subscription_tier}</dd>
        </div>
      </dl>
    </div>
  )
}
