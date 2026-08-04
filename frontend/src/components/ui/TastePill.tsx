import './ui.css'

export type TasteTone = 'sour' | 'sweet' | 'tangy' | 'spicy' | 'savory' | 'bitter' | 'umami' | 'mild'

interface TastePillProps {
  label: string
  active?: boolean
  tone?: TasteTone
}

export default function TastePill({ label, active = false, tone = 'savory' }: TastePillProps) {
  return (
    <span className={['taste-pill', `taste-${tone}`, active ? 'is-active' : ''].join(' ')}>
      {label}
    </span>
  )
}
