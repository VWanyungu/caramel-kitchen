import './ui.css'
import { humanize } from '../../lib/recipeTaxonomy'

interface ChipToggleGroupProps {
  label: string
  hint?: string
  options: readonly string[]
  value: string[]
  onChange: (next: string[]) => void
  max?: number
  error?: string
}

export default function ChipToggleGroup({
  label,
  hint,
  options,
  value,
  onChange,
  max,
  error,
}: ChipToggleGroupProps) {
  function toggle(option: string) {
    if (value.includes(option)) {
      onChange(value.filter((item) => item !== option))
      return
    }
    if (max && value.length >= max) return
    onChange([...value, option])
  }

  return (
    <div className="field">
      <label className="field-label">
        {label}
        {hint && <span className="chip-hint"> — {hint}</span>}
      </label>
      <div className="chip-group" role="group" aria-label={label}>
        {options.map((option) => {
          const active = value.includes(option)
          const disabled = !active && Boolean(max) && value.length >= (max as number)
          return (
            <button
              type="button"
              key={option}
              className={['chip', active ? 'is-active' : ''].join(' ')}
              aria-pressed={active}
              disabled={disabled}
              onClick={() => toggle(option)}
            >
              {humanize(option)}
            </button>
          )
        })}
      </div>
      {error && (
        <p className="field-error" role="alert">
          {error}
        </p>
      )}
    </div>
  )
}
