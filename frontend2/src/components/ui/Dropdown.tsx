import { Check, ChevronDown } from 'lucide-react'
import React, { useEffect, useRef, useState } from 'react'

export interface DropdownOption {
  label: string
  value: string
}

export interface DropdownProps {
  label?: string
  options: (DropdownOption | string)[]
  value?: string
  defaultValue?: string
  onChange?: (value: string) => void
  placeholder?: string
  size?: 'sm' | 'md' | 'lg'
  fullWidth?: boolean
  disabled?: boolean
  className?: string
  triggerClassName?: string
  menuClassName?: string
}

export const Dropdown: React.FC<DropdownProps> = ({
  label,
  options,
  value: controlledValue,
  defaultValue,
  onChange,
  placeholder = 'Select option...',
  size = 'md',
  fullWidth = false,
  disabled = false,
  className = '',
  triggerClassName = '',
  menuClassName = '',
}) => {
  const normalizedOptions: DropdownOption[] = options.map((opt) =>
    typeof opt === 'string' ? { label: opt, value: opt } : opt
  )

  const [internalValue, setInternalValue] = useState<string>(
    controlledValue ?? defaultValue ?? (normalizedOptions[0]?.value || '')
  )

  const isControlled = controlledValue !== undefined
  const currentValue = isControlled ? controlledValue : internalValue

  const [isOpen, setIsOpen] = useState(false)
  const dropdownRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape' && isOpen) {
        setIsOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
      document.removeEventListener('keydown', handleKeyDown)
    }
  }, [isOpen])

  const selectedOption = normalizedOptions.find((o) => o.value === currentValue)

  const handleSelect = (val: string) => {
    if (!isControlled) {
      setInternalValue(val)
    }
    onChange?.(val)
    setIsOpen(false)
  }

  const sizeClasses = {
    sm: 'px-4 py-1.5 text-xs rounded-full',
    md: 'px-5 py-2.5 text-xs rounded-full',
    lg: 'px-6 py-3 text-sm rounded-full',
  }[size]

  return (
    <div
      className={`relative ${fullWidth ? 'w-full' : 'inline-block'} ${className}`.trim()}
      ref={dropdownRef}
    >
      {label && (
        <label className="mb-2 block text-xs font-semibold uppercase tracking-wider text-gray-500 font-sans">
          {label}
        </label>
      )}

      <button
        type="button"
        disabled={disabled}
        onClick={() => setIsOpen((prev) => !prev)}
        aria-expanded={isOpen}
        aria-haspopup="listbox"
        className={`flex items-center justify-between gap-2.5 font-sans font-semibold cursor-pointer border border-gray-300 bg-white text-ink shadow-xs hover:bg-ink/5 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-caramel transition-colors disabled:opacity-50 disabled:cursor-not-allowed select-none ${
          fullWidth ? 'w-full' : ''
        } ${sizeClasses} ${triggerClassName}`.trim()}
      >
        <span className="truncate">{selectedOption ? selectedOption.label : placeholder}</span>
        <ChevronDown
          size={14}
          className={`shrink-0 transition-transform duration-200 text-gray-500 ${
            isOpen ? 'rotate-180' : ''
          }`}
        />
      </button>

      {isOpen && (
        <div
          role="listbox"
          className={`absolute left-0 right-0 top-full mt-2 max-h-60 overflow-y-auto rounded-2xl border border-gray-200 bg-white/95 backdrop-blur-md p-1.5 shadow-xl z-50 animate-in fade-in zoom-in-95 duration-150 ${menuClassName}`.trim()}
        >
          {normalizedOptions.map((option) => {
            const isSelected = currentValue === option.value
            return (
              <button
                key={option.value}
                type="button"
                role="option"
                aria-selected={isSelected}
                onClick={() => handleSelect(option.value)}
                className={`w-full flex items-center justify-between gap-3 rounded-xl px-4 py-2.5 text-xs font-sans font-medium transition-colors cursor-pointer ${
                  isSelected
                    ? 'bg-caramel/15 text-caramel font-semibold'
                    : 'text-ink hover:bg-gray-100/80'
                }`}
              >
                <span className="truncate">{option.label}</span>
                {isSelected && <Check size={14} className="text-caramel shrink-0" />}
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}
