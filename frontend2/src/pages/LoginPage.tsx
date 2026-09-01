import { useState, type FormEvent } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/useAuth'
import { ApiError } from '../lib/api'
import { Button } from '../components/ui'

export function LoginPage() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    setSubmitting(true)
    try {
      await login({ email, password })
      const redirectTo =
        (location.state as { from?: { pathname: string } })?.from?.pathname ?? '/'
      navigate(redirectTo, { replace: true })
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="min-h-screen bg-white dark:bg-[#120905] text-ink dark:text-[#f5ebe0] flex flex-col justify-between items-center py-12 px-4 transition-colors duration-300 font-sans">
      <div className="flex-1 flex flex-col justify-center items-center w-full max-w-lg">
        <h1 className="mb-8 text-3xl font-display font-bold tracking-tight text-center">
          <Link to="/">
            <span className="text-caramel">Caramel</span>
            <span className="text-ink dark:text-white"> Kitchen</span>
          </Link>
        </h1>

        {/* Credentials Form Box */}
        <div className="w-full bg-white dark:bg-[#1d120a] ">
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Email Address */}
            <div>
              <label htmlFor="email" className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                Email address
              </label>
              <input
                id="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full rounded-md border border-gray-300 dark:border-stone-800 bg-white dark:bg-stone-900 px-3 py-2 text-sm text-ink dark:text-white placeholder-gray-400 focus:border-caramel focus:outline-none focus:ring-2 focus:ring-caramel/20 transition-all shadow-xs"
              />
            </div>

            {/* Password */}
            <div>
              <div className="flex justify-between items-center mb-1.5">
                <label htmlFor="password" className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                  Password
                </label>
                <Link to="/forgot-password" className="text-xs text-caramel hover:underline">
                  Forgot password?
                </Link>
              </div>
              <input
                id="password"
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full rounded-md border border-gray-300 dark:border-stone-800 bg-white dark:bg-stone-900 px-3 py-2 text-sm text-ink dark:text-white placeholder-gray-400 focus:border-caramel focus:outline-none focus:ring-2 focus:ring-caramel/20 transition-all shadow-xs"
              />
            </div>

            {/* Submit Error */}
            {error && (
              <div className="text-xs font-semibold text-red-600 bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-900/50 p-2.5 rounded-md">
                {error}
              </div>
            )}

            {/* Submit Button */}
            <Button
              type="submit"
              variant="dark"
              disabled={submitting}
              className="text-sm font-semibold w-full mt-4"
            >
              <span>{submitting ? 'Signing in' : 'Sign in'}</span>
            </Button>
          </form>
        </div>

        {/* Separator */}
        <div className="relative my-4 flex items-center justify-center w-full">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-gray-200 dark:border-stone-850" />
          </div>
          <span className="relative px-3 text-xs text-gray-400 bg-white dark:bg-black">or</span>
        </div>

        {/* Social Signups */}
        <button
          type="button"
          className="text-xs w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-full border border-gray-300 dark:border-stone-800 bg-white dark:bg-stone-900 hover:bg-gray-50 dark:hover:bg-stone-800 text-sm font-semibold text-gray-700 dark:text-gray-300 transition-colors shadow-xs cursor-pointer focus:outline-none focus:ring-2 focus:ring-caramel/20"
        >
          <svg className="h-4 w-4 shrink-0" viewBox="0 0 24 24" fill="currentColor">
            <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
            <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
            <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" fill="#FBBC05" />
            <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" fill="#EA4335" />
          </svg>
          <span>Continue with Google</span>
        </button>

        {/* Create account redirect box */}
        <div className="w-full text-center p-4 mt-4 text-xs sm:text-sm text-gray-600 dark:text-gray-400">
          New to Caramel Kitchen?{' '}
          <Link to="/signup" className="font-semibold text-caramel hover:underline">
            Create an account
          </Link>
          .
        </div>
      </div>

      {/* Footer */}
      <div className="text-center text-[10px] sm:text-xs text-gray-400 dark:text-gray-500 flex flex-wrap justify-center gap-x-4 gap-y-2 mt-8 max-w-[460px]">
        <a href="#" className="hover:text-caramel hover:underline">Terms</a>
        <a href="#" className="hover:text-caramel hover:underline">Privacy</a>
        <a href="#" className="hover:text-caramel hover:underline">Contact Support</a>
        <a href="#" className="hover:text-caramel hover:underline">Manage cookies</a>
      </div>
    </div>
  )
}
