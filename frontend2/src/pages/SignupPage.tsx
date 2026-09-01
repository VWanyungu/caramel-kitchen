import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/useAuth'
import { ApiError } from '../lib/api'
import { Check, ChevronDown, ChevronUp, ArrowRight } from 'lucide-react'
import { Button } from '../components/ui'

export function SignupPage() {
  const { signup } = useAuth()
  const navigate = useNavigate()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [optInUpdates, setOptInUpdates] = useState(false)

  const [showFeatures, setShowFeatures] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  // Real-time validation states
  const [passwordTouched, setPasswordTouched] = useState(false)

  const isPasswordValid = password.length >= 8 && password.length <= 72 && /[0-9]/.test(password)

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)

    if (!isPasswordValid) {
      setError('Password must be 8-72 characters long and contain at least one number.')
      return
    }

    setSubmitting(true)
    try {
      // Derive name from email prefix (e.g. john.doe from john.doe@example.com)
      const derivedName = email.split('@')[0] || 'User'

      await signup({
        name: derivedName,
        email,
        password,
        password_confirmation: password,
      })
      navigate('/', { replace: true })
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  // Generate background star particles
  const stars = Array.from({ length: 25 }, (_, i) => ({
    id: i,
    top: `${Math.random() * 100}%`,
    left: `${Math.random() * 100}%`,
    size: Math.random() * 2 + 1,
    opacity: Math.random() * 0.7 + 0.3,
  }))

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 min-h-screen font-sans bg-white dark:bg-[#120905] transition-colors duration-300">

      {/* LEFT PANEL - Starry sky & branding & checklist */}
      <div className="lg:col-span-5 xl:col-span-5 bg-gradient-to-br from-[#190c07] via-[#0c0503] to-black text-white p-8 lg:p-12 flex flex-col justify-between relative overflow-hidden hidden lg:flex">
        {/* Ambient star background */}
        <div className="absolute inset-0 pointer-events-none">
          {stars.map((star) => (
            <div
              key={star.id}
              className="absolute bg-white rounded-full"
              style={{
                top: star.top,
                left: star.left,
                width: `${star.size}px`,
                height: `${star.size}px`,
                opacity: star.opacity,
              }}
            />
          ))}
          {/* Subtle warm nebula glow */}
          <div className="absolute -top-40 -left-40 w-96 h-96 rounded-full bg-caramel/10 blur-3xl" />
          <div className="absolute -bottom-40 -right-40 w-96 h-96 rounded-full bg-mahogany/10 blur-3xl" />
        </div>

        {/* Content wrapper */}
        <div className="mt-48">
          {/* Logo */}
          <div className="">
            <Link to="/" className="mb-16 font-display text-2xl italic text-caramel tracking-wide hover:opacity-90 transition-opacity">
              Caramel Kitchen
            </Link>
            <h1 className="text-3xl lg:text-4xl font-semibold tracking-tight leading-tight">
              Create your free account
            </h1>
            <p className="mt-3 text-gray-400 text-sm">
              Explore Caramel's core features for home cooks and recipe creators.
            </p>

            {/* See what's included accordion toggle */}
            <button
              onClick={() => setShowFeatures(!showFeatures)}
              className="mt-8 flex items-center gap-1.5 text-xs text-caramel hover:text-caramel/80 font-semibold uppercase tracking-wider transition-colors focus:outline-none"
            >
              <span>See what's included</span>
              {showFeatures ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
            </button>

            {/* Features Checklist */}
            <div
              className={`mt-6 space-y-5 transition-all duration-300 overflow-hidden ${showFeatures ? 'max-h-[600px] opacity-100' : 'max-h-0 opacity-0 pointer-events-none'
                }`}
            >
              <div className="flex gap-3 items-start">
                <div className="mt-0.5 text-caramel">
                  <Check size={16} className="stroke-[3]" />
                </div>
                <div>
                  <h3 className="text-sm font-semibold text-gray-200">Limited access to Caramel AI Chef</h3>
                  <p className="text-xs text-gray-400 mt-1 leading-relaxed">
                    Get instant culinary guidance, recipe conversions, and ingredient substitutions in real-time.
                  </p>
                </div>
              </div>

              <div className="flex gap-3 items-start">
                <div className="mt-0.5 text-caramel">
                  <Check size={16} className="stroke-[3]" />
                </div>
                <div>
                  <h3 className="text-sm font-semibold text-gray-200">Cooking step-by-step guides</h3>
                  <p className="text-xs text-gray-400 mt-1 leading-relaxed">
                    Follow recipes with voice control, dynamic timers, and high-quality cooking guides.
                  </p>
                </div>
              </div>

              <div className="flex gap-3 items-start">
                <div className="mt-0.5 text-caramel">
                  <Check size={16} className="stroke-[3]" />
                </div>
                <div>
                  <h3 className="text-sm font-semibold text-gray-200">Automated grocery lists</h3>
                  <p className="text-xs text-gray-400 mt-1 leading-relaxed">
                    Save time with dynamic ingredient scaling and automatic shopping lists grouped by aisle.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* 3D Render Image Container at Bottom */}
        {/* <div className="relative z-10 mt-12 flex justify-center">
          <div className="relative rounded-2xl overflow-hidden border border-white/10 shadow-2xl bg-black/40 backdrop-blur-md p-2 max-w-[280px]">
            <img
              src="/signup-characters.jpg"
              alt="Chef Ollie and Ducky cooking"
              className="w-full h-auto rounded-xl object-cover hover:scale-[1.03] transition-transform duration-500 ease-out"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent pointer-events-none" />
          </div>
        </div> */}
      </div>

      {/* RIGHT PANEL - Sign Up Form */}
      <div className="lg:col-span-7 xl:col-span-7 flex flex-col justify-between min-h-screen relative p-6 sm:p-12 lg:p-16">

        {/* Header navigation */}
        <div className="flex justify-between items-center w-full">
          <Link to="/" className="lg:hidden font-display text-xl italic text-caramel">
            Caramel Kitchen
          </Link>
          <div className="ml-auto text-xs sm:text-sm text-gray-500 dark:text-gray-400">
            Already have an account?{' '}
            <Link
              to="/login"
              className="font-semibold text-caramel dark:text-caramel/90 hover:underline inline-flex items-center gap-1 group"
            >
              Sign in
              <ArrowRight size={14} className="group-hover:translate-x-0.5 transition-transform" />
            </Link>
          </div>
        </div>

        {/* Center content container */}
        <div className="mx-auto my-auto w-full max-w-[460px] py-12">
          <h2 className="text-2xl font-bold tracking-tight text-caramel text-center sm:text-center">
            Sign up for Caramel Kitchen
          </h2>

          {/* Social Signups */}
          <div className="mt-8 grid grid-cols-1 sm:grid-cols-1 gap-3">
            {/* Google */}
            <button
              type="button"
              className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-full border border-gray-300 dark:border-stone-800 bg-white dark:bg-stone-900 hover:bg-gray-50 dark:hover:bg-stone-800 text-sm font-semibold text-gray-700 dark:text-gray-300 transition-colors shadow-xs cursor-pointer focus:outline-none focus:ring-2 focus:ring-caramel/20"
            >
              <svg className="h-4 w-4 shrink-0" viewBox="0 0 24 24" fill="currentColor">
                <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
                <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
                <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" fill="#FBBC05" />
                <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" fill="#EA4335" />
              </svg>
              <span>Continue with Google</span>
            </button>

            {/* Apple */}
            {/* <button
              type="button"
              className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg border border-gray-300 dark:border-stone-800 bg-white dark:bg-stone-900 hover:bg-gray-50 dark:hover:bg-stone-800 text-sm font-semibold text-gray-700 dark:text-gray-300 transition-colors shadow-xs cursor-pointer focus:outline-none focus:ring-2 focus:ring-caramel/20"
            >
              <svg className="h-4 w-4 shrink-0" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 4.17c.66-.81 1.11-1.93.99-3.06-1 .04-2.2.67-2.92 1.5-.62.71-1.16 1.85-1.01 2.96 1.1.09 2.22-.59 2.94-1.4" />
              </svg>
              <span>Continue with Apple</span>
            </button> */}
          </div>

          {/* Separator */}
          <div className="relative my-6 flex items-center justify-center">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-200 dark:border-stone-800" />
            </div>
            <span className="relative px-3 bg-white dark:bg-[#120905] text-xs text-gray-400">or</span>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">

            {/* Email Field */}
            <div>
              <label htmlFor="email" className="block text-xs font-semibold text-gray-700 dark:text-gray-300">
                Email<span className="text-red-500 ml-0.5">*</span>
              </label>
              <input
                id="email"
                type="email"
                required
                placeholder="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="mt-1.5 w-full rounded-lg border border-gray-300 dark:border-stone-800 bg-white dark:bg-stone-900 px-3.5 py-2.5 text-sm text-ink dark:text-white placeholder-gray-400 focus:border-caramel focus:outline-none focus:ring-2 focus:ring-caramel/20 transition-all shadow-xs"
              />
            </div>

            {/* Password Field */}
            <div>
              <label htmlFor="password" className="block text-xs font-semibold text-gray-700 dark:text-gray-300">
                Password<span className="text-red-500 ml-0.5">*</span>
              </label>
              <input
                id="password"
                type="password"
                required
                placeholder="Password"
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value)
                  setPasswordTouched(true)
                }}
                className={`mt-1.5 w-full rounded-lg border bg-white dark:bg-stone-900 px-3.5 py-2.5 text-sm text-ink dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 transition-all shadow-xs ${passwordTouched && !isPasswordValid
                  ? 'border-red-400 focus:border-red-400 focus:ring-red-100 dark:focus:ring-red-950/30'
                  : 'border-gray-300 dark:border-stone-800 focus:border-caramel focus:ring-caramel/20'
                  }`}
              />
              <p className="mt-1.5 text-[10px] sm:text-xs text-gray-400 dark:text-gray-500 leading-normal">
                Password must be 8-72 characters long and contain at least one number.
              </p>
            </div>

            {/* Checkbox: Updates */}
            <div className="flex gap-3">
              <div className="flex items-center h-5">
                <input
                  id="optInUpdates"
                  type="checkbox"
                  checked={optInUpdates}
                  onChange={(e) => setOptInUpdates(e.target.checked)}
                  className="h-4 w-4 rounded border-gray-300 text-caramel focus:ring-caramel cursor-pointer accent-caramel"
                />
              </div>
              <div className="text-xs">
                <label htmlFor="optInUpdates" className="font-semibold text-gray-700 dark:text-gray-300 cursor-pointer">
                  Email preferences
                </label>
                <p className="text-gray-400 dark:text-gray-500 mt-0.5 leading-normal">
                  Receive occasional recipe updates, product feature announcements, and culinary roundups.
                </p>
              </div>
            </div>

            {/* Submit Error */}
            {error && (
              <div className="text-xs font-semibold text-red-600 bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-900/50 p-3 rounded-lg mt-2">
                {error}
              </div>
            )}

            {/* Submit Button */}
            <Button
              type="submit"
              variant="dark"
              disabled={submitting}
              className="text-sm font-semibold w-full"
            >
              <span>{submitting ? 'Creating account…' : 'Create account'}</span>
            </Button>
          </form>
        </div>

        {/* Footer info */}
        <div className="text-center text-[10px] sm:text-xs text-gray-400 dark:text-gray-500 max-w-[460px] mx-auto mt-8 leading-relaxed">
          By creating an account, you agree to the{' '}
          <a href="#" className="text-caramel hover:underline">
            Terms of Service
          </a>{' '}
          and{' '}
          <a href="#" className="text-caramel hover:underline">
            Privacy Policy
          </a>
          . We process your personal data in accordance with our Global Privacy Statement.
        </div>
      </div>
    </div>
  )
}
