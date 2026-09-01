import React from 'react'

export interface DurationPickerProps {
  title?: string
  options?: number[]
  value?: number
  onChange?: (value: number | undefined) => void
  caption?: string
  className?: string
}

export const DurationPicker: React.FC<DurationPickerProps> = ({
  title = 'total time',
  options = [30, 60, 90, 120],
  value,
  onChange,
  caption = '',
  className = '',
}) => {
  const handleSelect = (optionValue: number) => {
    if (value === optionValue) {
      onChange?.(undefined)
    } else {
      onChange?.(optionValue)
    }
  }

  return (
    <div
      className={`space-y-5 font-sans ${className}`.trim()}
    >
      <h3 className="text-[11px] font-bold tracking-widest text-neutral-400 uppercase">
        {title}
      </h3>

      <div className="flex items-center justify-between gap-2.5 sm:gap-4">
        {options.map((option) => {
          const isSelected = value === option

          return (
            <button
              key={option}
              type="button"
              onClick={() => handleSelect(option)}
              aria-pressed={isSelected}
              className={`relative w-16 h-16 sm:w-20 sm:h-20 rounded-full flex flex-col items-center justify-center cursor-pointer transition-all duration-200 select-none shrink-0 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white bg-white text-neutral-900 shadow-md scale-105 ring-1 ring-black ${isSelected
                ? 'ring-butter'
                : ''
                }`}
            >
              {/* Clock Face SVG Ticks */}
              <svg
                className="absolute inset-0 w-full h-full pointer-events-none"
                viewBox="0 0 100 100"
              >
                {Array.from({ length: 12 }).map((_, i) => {
                  const angle = i * 30
                  const isMajor = i % 3 === 0
                  return (
                    <line
                      key={i}
                      x1="50"
                      y1={isMajor ? '6' : '8'}
                      x2="50"
                      y2={isMajor ? '13' : '11'}
                      // stroke={isSelected ? '#18181b' : '#ffffff'}
                      stroke={'black'}
                      strokeOpacity={
                        isMajor
                          ? 0.75
                          : 0.35

                      }
                      strokeWidth={isMajor ? '2' : '1.2'}
                      strokeLinecap="round"
                      transform={`rotate(${angle} 50 50)`}
                    />
                  )
                })}
              </svg>

              {/* Text display inside clock face */}
              <span className="text-base sm:text-xl font-bold leading-none tracking-tight z-10">
                {option}
              </span>
              <span className="text-[10px] sm:text-[11px] font-medium opacity-80 leading-none mt-0.5 sm:mt-1 z-10">
                min
              </span>
            </button>
          )
        })}
      </div>

      {caption && (
        <p className="text-xs text-neutral-400 leading-relaxed font-sans">
          {caption}
        </p>
      )}
    </div>
  )
}
