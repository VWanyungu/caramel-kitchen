import { forwardRef, useId, type SelectHTMLAttributes } from 'react'
import './ui.css'

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label: string
  error?: string
}

const Select = forwardRef<HTMLSelectElement, SelectProps>(function Select(
  { label, error, id, children, ...rest },
  ref,
) {
  const generatedId = useId()
  const selectId = id ?? generatedId

  return (
    <div className="field">
      <label className="field-label" htmlFor={selectId}>
        {label}
      </label>
      <select
        id={selectId}
        ref={ref}
        className="field-input"
        aria-invalid={Boolean(error)}
        aria-describedby={error ? `${selectId}-error` : undefined}
        {...rest}
      >
        {children}
      </select>
      {error && (
        <p className="field-error" id={`${selectId}-error`} role="alert">
          {error}
        </p>
      )}
    </div>
  )
})

export default Select
