import { X } from 'lucide-react'
import { useEffect, useState } from 'react'
import { Button, Dropdown, DurationPicker } from '../../components/ui'
import { EMPTY_FILTERS, type Difficulty, type RecipeFilters } from './types'

const CUISINES = [
  'Italian',
  'Mexican',
  'Indian',
  'Chinese',
  'Thai',
  'Japanese',
  'French',
  'Mediterranean',
  'American',
  'Kenyan',
]

const DIETARY_FLAGS = [
  'vegan',
  'vegetarian',
  'gluten_free',
  'dairy_free',
  'nut_free',
  'keto',
  'low_carb',
  'halal',
]

const DIFFICULTIES: Difficulty[] = ['beginner', 'intermediate', 'advanced']

interface FiltersModalProps {
  open: boolean
  onClose: () => void
  categories: string[]
  filters: RecipeFilters
  onApply: (filters: RecipeFilters) => void
}

function toggleValue(list: string[], value: string): string[] {
  return list.includes(value) ? list.filter((v) => v !== value) : [...list, value]
}

export function FiltersModal({ open, onClose, categories, filters, onApply }: FiltersModalProps) {
  const [draft, setDraft] = useState<RecipeFilters>(filters)

  useEffect(() => {
    if (open) setDraft(filters)
  }, [open, filters])

  useEffect(() => {
    if (!open) return
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [open, onClose])

  if (!open) return null

  const categoryOptions = [
    { label: 'Any category', value: '' },
    ...categories.map((c) => ({ label: c, value: c })),
  ]

  return (
    <div className="fixed inset-0 z-30 flex items-end justify-center bg-black/40 backdrop-blur-xs p-0 sm:items-center sm:p-6">
      <button
        type="button"
        aria-label="Close filters"
        onClick={onClose}
        className="absolute inset-0 cursor-default"
      />

      <div
        role="dialog"
        aria-modal="true"
        aria-label="Filter recipes"
        className="relative z-10 max-h-[85vh] w-full max-w-lg overflow-y-auto rounded-t-2xl bg-white p-6 shadow-2xl border border-gray-100 sm:rounded-2xl"
      >
        <div className="mb-6 flex items-center justify-between border-b border-gray-100 pb-4">
          <h2 className="font-serif text-2xl text-ink font-semibold">Filter Recipes</h2>
          <Button
            variant="ghost"
            size="sm"
            onClick={onClose}
            aria-label="Close"
            className="!p-2 rounded-full text-gray-400 hover:text-ink hover:bg-gray-100"
          >
            <X className="h-5 w-5" />
          </Button>
        </div>

        <div className="space-y-6 font-sans">
          <div>
            <Dropdown
              label="Category"
              options={categoryOptions}
              value={draft.category}
              placeholder="Any category"
              fullWidth
              onChange={(val) => setDraft((d) => ({ ...d, category: val }))}
            />
          </div>

          <div>
            <span className="mb-2 block text-xs font-semibold uppercase tracking-wider text-gray-500">
              Difficulty
            </span>
            <div className="flex gap-2">
              {DIFFICULTIES.map((level) => {
                const isSelected = draft.difficulty === level
                return (
                  <Button
                    key={level}
                    variant="chip"
                    size="sm"
                    isActive={isSelected}
                    onClick={() =>
                      setDraft((d) => ({ ...d, difficulty: isSelected ? '' : level }))
                    }
                    className="capitalize"
                  >
                    {level}
                  </Button>
                )
              })}
            </div>
          </div>

          <div>
            <span className="mb-2 block text-xs font-semibold uppercase tracking-wider text-gray-500">
              Cuisine
            </span>
            <div className="flex flex-wrap gap-2">
              {CUISINES.map((cuisine) => {
                const isSelected = draft.cuisine.includes(cuisine)
                return (
                  <Button
                    key={cuisine}
                    variant="chip"
                    size="sm"
                    isActive={isSelected}
                    onClick={() =>
                      setDraft((d) => ({ ...d, cuisine: toggleValue(d.cuisine, cuisine) }))
                    }
                  >
                    {cuisine}
                  </Button>
                )
              })}
            </div>
          </div>

          <div>
            <span className="mb-2 block text-xs font-semibold uppercase tracking-wider text-gray-500">
              Dietary
            </span>
            <div className="flex flex-wrap gap-2">
              {DIETARY_FLAGS.map((flag) => {
                const isSelected = draft.dietary.includes(flag)
                return (
                  <Button
                    key={flag}
                    variant="chip"
                    size="sm"
                    isActive={isSelected}
                    onClick={() =>
                      setDraft((d) => ({ ...d, dietary: toggleValue(d.dietary, flag) }))
                    }
                    className="capitalize"
                  >
                    {flag.replace('_', ' ')}
                  </Button>
                )
              })}
            </div>
          </div>

          <div>
            <DurationPicker
              title="Total time"
              options={[30, 60, 90, 120]}
              value={draft.maxTime}
              onChange={(val) => setDraft((d) => ({ ...d, maxTime: val }))}
              caption=""
            />
          </div>
        </div>

        <div className="mt-8 flex gap-3 border-t border-gray-100 pt-4">
          <Button
            variant="outline"
            fullWidth
            onClick={() => setDraft((d) => ({ ...EMPTY_FILTERS, q: d.q }))}
          >
            Clear all
          </Button>
          <Button
            variant="primary"
            fullWidth
            onClick={() => {
              onApply(draft)
              onClose()
            }}
          >
            Apply filters
          </Button>
        </div>
      </div>
    </div>
  )
}
