import { Link } from 'react-router-dom'

export function NotFoundPage() {
  return (
    <div className="mx-auto max-w-md px-6 py-24 text-center">
      <h1 className="text-2xl font-semibold text-gray-900">Page not found</h1>
      <Link to="/" className="mt-4 inline-block text-gray-600 underline">
        Back home
      </Link>
    </div>
  )
}
