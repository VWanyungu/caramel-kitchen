import './ui.css'

interface TastePillProps {
  label: string
  active?: boolean
  tone?: 'sweet' | 'spicy' | 'savory'
}

export default function TastePill({ label, active = false, tone = 'savory' }: TastePillProps) {
  return (
    <span className={['taste-pill', `taste-${tone}`, active ? 'is-active' : ''].join(' ')}>
      {label}
    </span>
  )
}
