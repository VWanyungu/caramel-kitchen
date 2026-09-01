import { useEffect, useState, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import './auth.css'

const FLAVOR_PROMPTS = [
  'Something tangy tonight?',
  'Craving savory and slow-cooked?',
  'Sweet, spiced, or somewhere between?',
  'What is your palate in the mood for?',
]

interface AuthLayoutProps {
  eyebrow: string
  title: string
  subtitle: string
  children: ReactNode
  footer: ReactNode
}

export default function AuthLayout({ eyebrow, title, subtitle, children, footer }: AuthLayoutProps) {
  const [promptIndex, setPromptIndex] = useState(0)

  useEffect(() => {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
    const interval = setInterval(() => {
      setPromptIndex((index) => (index + 1) % FLAVOR_PROMPTS.length)
    }, 4000)
    return () => clearInterval(interval)
  }, [])

  return (
    <div className="auth-shell">
      <aside className="auth-hero" aria-hidden="true">
        <div className="auth-hero-glow" />
        <div className="auth-hero-content">
          <Link to="/" className="wordmark wordmark-on-dark">
            Caramel <em>Kitchen</em>
          </Link>
          <p className="auth-hero-prompt">{FLAVOR_PROMPTS[promptIndex]}</p>
        </div>
      </aside>

      <main className="auth-panel">
        <Link to="/" className="wordmark wordmark-compact">
          Caramel <em>Kitchen</em>
        </Link>

        <div className="auth-panel-inner">
          <p className="eyebrow">{eyebrow}</p>
          <h1 className="auth-title">{title}</h1>
          <p className="auth-subtitle">{subtitle}</p>

          {children}

          <div className="auth-footer">{footer}</div>
        </div>
      </main>
    </div>
  )
}
