import { forwardRef, useId, type TextareaHTMLAttributes } from 'react'
import './ui.css'

interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label: string
  error?: string
}

const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(function Textarea(
  { label, error, id, rows = 4, ...rest },
  ref,
) {
  const generatedId = useId()
  const textareaId = id ?? generatedId

  return (
    <div className="field">
      <label className="field-label" htmlFor={textareaId}>
        {label}
      </label>
      <textarea
        id={textareaId}
        ref={ref}
        rows={rows}
        className="field-input field-textarea"
        aria-invalid={Boolean(error)}
        aria-describedby={error ? `${textareaId}-error` : undefined}
        {...rest}
      />
      {error && (
        <p className="field-error" id={`${textareaId}-error`} role="alert">
          {error}
        </p>
      )}
    </div>
  )
})

export default Textarea
