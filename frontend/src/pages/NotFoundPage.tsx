import { Link } from 'react-router-dom'

export default function NotFoundPage() {
  return (
    <div
      style={{
        minHeight: '100svh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 12,
        background: 'var(--bg-cream)',
        textAlign: 'center',
        padding: 24,
      }}
    >
      <p className="eyebrow">404</p>
      <h1 style={{ fontFamily: 'var(--display)', margin: 0 }}>This page isn't on the menu</h1>
      <p style={{ color: 'var(--ink-soft)', margin: 0 }}>
        <Link to="/">Back to Caramel Kitchen</Link>
      </p>
    </div>
  )
}
