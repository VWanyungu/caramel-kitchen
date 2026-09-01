import { TASTE_TAG_DESCRIPTIONS, humanize } from '../../lib/recipeTaxonomy'
import './taste-tag-picker.css'

interface TasteTagPickerProps {
  label: string
  hint?: string
  options: readonly string[]
  value: string[]
  onChange: (next: string[]) => void
  max?: number
  error?: string
}

export default function TasteTagPicker({
  label,
  hint,
  options,
  value,
  onChange,
  max,
  error,
}: TasteTagPickerProps) {
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
      <div className="taste-card-grid" role="group" aria-label={label}>
        {options.map((option) => {
          const active = value.includes(option)
          const disabled = !active && Boolean(max) && value.length >= (max as number)
          return (
            <button
              type="button"
              key={option}
              className={['taste-card', `taste-card-${option}`, active ? 'is-active' : ''].join(' ')}
              aria-pressed={active}
              disabled={disabled}
              onClick={() => toggle(option)}
            >
              <span className="taste-card-label">{humanize(option)}</span>
              <span className="taste-card-description">
                {TASTE_TAG_DESCRIPTIONS[option as keyof typeof TASTE_TAG_DESCRIPTIONS]}
              </span>
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
