import './ui.css'
import { humanize } from '../../lib/recipeTaxonomy'

interface SingleChipGroupProps {
  label: string
  hint?: string
  options: readonly string[]
  value: string
  onChange: (next: string) => void
  allowClear?: boolean
  error?: string
  counts?: Record<string, number>
}

export default function SingleChipGroup({
  label,
  hint,
  options,
  value,
  onChange,
  allowClear = false,
  error,
  counts,
}: SingleChipGroupProps) {
  function select(option: string) {
    if (allowClear && value === option) {
      onChange('')
      return
    }
    onChange(option)
  }

  return (
    <div className="field">
      <label className="field-label">
        {label}
        {hint && <span className="chip-hint"> — {hint}</span>}
      </label>
      <div className="chip-group" role="radiogroup" aria-label={label}>
        {options.map((option) => {
          const active = value === option
          return (
            <button
              type="button"
              key={option}
              className={['chip', active ? 'is-active' : ''].join(' ')}
              role="radio"
              aria-checked={active}
              onClick={() => select(option)}
            >
              {humanize(option)}
              {counts?.[option] !== undefined && <span className="chip-count"> ({counts[option]})</span>}
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
