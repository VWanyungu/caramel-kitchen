import { forwardRef, useId, useState, type InputHTMLAttributes } from 'react'
import './ui.css'

interface PasswordFieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string
  error?: string
}

const PasswordField = forwardRef<HTMLInputElement, PasswordFieldProps>(function PasswordField(
  { label, error, id, ...rest },
  ref,
) {
  const [revealed, setRevealed] = useState(false)
  const generatedId = useId()
  const inputId = id ?? generatedId

  return (
    <div className="field">
      <label className="field-label" htmlFor={inputId}>
        {label}
      </label>
      <div className="field-password">
        <input
          id={inputId}
          ref={ref}
          type={revealed ? 'text' : 'password'}
          className="field-input"
          aria-invalid={Boolean(error)}
          aria-describedby={error ? `${inputId}-error` : undefined}
          {...rest}
        />
        <button
          type="button"
          className="field-reveal"
          onClick={() => setRevealed((value) => !value)}
          aria-label={revealed ? `Hide ${label.toLowerCase()}` : `Show ${label.toLowerCase()}`}
        >
          {revealed ? 'Hide' : 'Show'}
        </button>
      </div>
      {error && (
        <p className="field-error" id={`${inputId}-error`} role="alert">
          {error}
        </p>
      )}
    </div>
  )
})

export default PasswordField
