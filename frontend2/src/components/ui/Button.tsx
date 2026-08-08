import React, { forwardRef } from 'react'

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'dark' | 'outline' | 'ghost' | 'chip'
  size?: 'sm' | 'md' | 'lg'
  fullWidth?: boolean
  isActive?: boolean
  icon?: React.ReactNode
  iconPosition?: 'left' | 'right'
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'secondary',
      size = 'md',
      fullWidth = false,
      isActive = false,
      icon,
      iconPosition = 'left',
      children,
      className = '',
      type = 'button',
      ...props
    },
    ref
  ) => {
    // Base classes matching FiltersModal style
    const baseClasses =
      'inline-flex items-center justify-center font-sans font-semibold cursor-pointer transition-colors duration-150 motion-reduce:transition-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-caramel disabled:opacity-50 disabled:cursor-not-allowed select-none'

    // Size variants
    const sizeClasses = {
      sm: 'px-4 py-1.5 text-xs rounded-full',
      md: 'px-6 py-2.5 text-xs rounded-full',
      lg: 'px-7 py-3.5 text-sm rounded-full',
    }[size]

    // Style variants matching established design system
    let variantClasses = ''

    if (variant === 'chip') {
      variantClasses = isActive
        ? 'border border-black bg-black text-white shadow-xs'
        : 'border border-gray-300 text-gray-600 bg-white hover:bg-ink/5'
    } else {
      switch (variant) {
        case 'primary':
          variantClasses = 'bg-butter hover:bg-butter/90 text-white shadow-xs border border-transparent'
          break
        case 'dark':
          variantClasses = 'bg-black hover:bg-gray-900 text-white border border-black shadow-xs'
          break
        case 'secondary':
        case 'outline':
          variantClasses = 'bg-white hover:bg-ink/5 text-ink border border-gray-300 shadow-xs'
          break
        case 'ghost':
          variantClasses = 'bg-transparent text-gray-500 hover:text-ink hover:bg-gray-100 border border-transparent'
          break
      }
    }

    const widthClass = fullWidth ? 'w-full' : ''

    return (
      <button
        ref={ref}
        type={type}
        className={`${baseClasses} ${sizeClasses} ${variantClasses} ${widthClass} ${className}`.trim()}
        {...props}
      >
        {icon && iconPosition === 'left' && (
          <span className="shrink-0 mr-2 flex items-center">{icon}</span>
        )}
        <span>{children}</span>
        {icon && iconPosition === 'right' && (
          <span className="shrink-0 ml-2 flex items-center">{icon}</span>
        )}
      </button>
    )
  }
)

Button.displayName = 'Button'
