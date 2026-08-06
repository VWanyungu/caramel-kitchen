import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import AppShell from '../components/app/AppShell'
import Button from '../components/ui/Button'
import ChipToggleGroup from '../components/ui/ChipToggleGroup'
import SingleChipGroup from '../components/ui/SingleChipGroup'
import TextField from '../components/ui/TextField'
import { deletePreset, listPresets, savePreset } from '../lib/filterPresets'
import { filtersToSearchParams, searchParamsToFilters } from '../lib/filterQueryString'
import { getCategoryCounts, getDishTypeCounts, listRecipes } from '../lib/recipesApi'
import {
  COOKING_METHODS,
  COURSES,
  CUISINE_ORIGINS,
  DIETARY_FLAGS,
  DIFFICULTIES,
  DISH_CATEGORIES,
} from '../lib/recipeTaxonomy'
import type { FilterPreset, RecipeFilters } from '../types/browse'
import './advanced-filters.css'

const CONTEXT_OPTIONS = ['quick', 'family', 'meal_prep', 'healthy'] as const

export default function AdvancedFiltersPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const initialQuery = searchParams.get('q') ?? ''

  const [filters, setFilters] = useState<RecipeFilters>(() => searchParamsToFilters(searchParams))
  const [categoryCounts, setCategoryCounts] = useState<Record<string, number>>({})
  const [courseCounts, setCourseCounts] = useState<Record<string, number>>({})
  const [matchCount, setMatchCount] = useState<number | null>(null)
  const [countLoading, setCountLoading] = useState(false)
  const [presets, setPresets] = useState<FilterPreset[]>(() => listPresets())
  const [presetName, setPresetName] = useState('')

  useEffect(() => {
    getCategoryCounts().then(setCategoryCounts).catch(() => setCategoryCounts({}))
    getDishTypeCounts().then(setCourseCounts).catch(() => setCourseCounts({}))
  }, [])

  useEffect(() => {
    let cancelled = false
    // Debounced live match count as filters change — resetting the loading flag synchronously
    // before the debounce/fetch is the canonical React data-fetching pattern.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setCountLoading(true)
    const timeout = setTimeout(() => {
      listRecipes(filters, { limit: 1 })
        .then((result) => {
          if (!cancelled) setMatchCount(result.meta.count)
        })
        .catch(() => {
          if (!cancelled) setMatchCount(null)
        })
        .finally(() => {
          if (!cancelled) setCountLoading(false)
        })
    }, 400)

    return () => {
      cancelled = true
      clearTimeout(timeout)
    }
  }, [filters])

  function update<K extends keyof RecipeFilters>(key: K, value: RecipeFilters[K]) {
    setFilters((current) => ({ ...current, [key]: value }))
  }

  function handleApply() {
    const params = filtersToSearchParams(filters)
    if (initialQuery) params.set('q', initialQuery)
    navigate(`/home?${params.toString()}`)
  }

  function handleClearAll() {
    navigate('/home')
  }

  function handleSavePreset() {
    if (!presetName.trim()) return
    savePreset(presetName.trim(), filters)
    setPresets(listPresets())
    setPresetName('')
  }

  function handleApplyPreset(preset: FilterPreset) {
    setFilters(preset.filters)
  }

  function handleDeletePreset(id: string) {
    deletePreset(id)
    setPresets(listPresets())
  }

  return (
    <AppShell>
      <div className="filters-page">
        <p className="eyebrow">Refine</p>
        <h1 className="shell-title">Advanced filters</h1>

        <section className="filters-section">
          <SingleChipGroup
            label="Quick filters"
            hint="A shortcut that combines several filters at once"
            options={CONTEXT_OPTIONS}
            value={filters.context}
            allowClear
            onChange={(next) => update('context', next as RecipeFilters['context'])}
          />
        </section>

        <section className="filters-section">
          <SingleChipGroup
            label="Category"
            hint="What kind of dish"
            options={DISH_CATEGORIES}
            value={filters.category}
            allowClear
            counts={categoryCounts}
            onChange={(next) => update('category', next)}
          />
          <SingleChipGroup
            label="Course"
            hint="Where it sits in the meal sequence"
            options={COURSES}
            value={filters.course}
            allowClear
            counts={courseCounts}
            onChange={(next) => update('course', next)}
          />
          <SingleChipGroup
            label="Cooking method"
            hint="How it's prepared"
            options={COOKING_METHODS}
            value={filters.cooking_method}
            allowClear
            onChange={(next) => update('cooking_method', next)}
          />
        </section>

        <section className="filters-section">
          <ChipToggleGroup
            label="Taste"
            hint="How the dish tastes"
            options={['sour', 'sweet', 'tangy', 'spicy', 'savory', 'bitter', 'umami', 'mild']}
            value={filters.taste}
            onChange={(next) => update('taste', next)}
          />
          <ChipToggleGroup
            label="Dietary"
            hint="Lifestyle & health restrictions"
            options={DIETARY_FLAGS}
            value={filters.dietary}
            onChange={(next) => update('dietary', next)}
          />
          <ChipToggleGroup
            label="Cuisine"
            hint="Regional food culture"
            options={CUISINE_ORIGINS}
            value={filters.cuisine}
            onChange={(next) => update('cuisine', next)}
          />
        </section>

        <section className="filters-section">
          <h2 className="filters-section-title">Time &amp; difficulty</h2>
          <div className="filters-grid">
            <TextField
              label="Min time (mins)"
              type="number"
              min={0}
              value={filters.min_time ?? ''}
              onChange={(event) => update('min_time', event.target.value ? Number(event.target.value) : null)}
            />
            <TextField
              label="Max time (mins)"
              type="number"
              min={0}
              value={filters.max_time ?? ''}
              onChange={(event) => update('max_time', event.target.value ? Number(event.target.value) : null)}
            />
            <TextField
              label="Max calories"
              type="number"
              min={0}
              value={filters.max_calories ?? ''}
              onChange={(event) => update('max_calories', event.target.value ? Number(event.target.value) : null)}
            />
          </div>
          <SingleChipGroup
            label="Difficulty"
            options={DIFFICULTIES}
            value={filters.difficulty}
            allowClear
            onChange={(next) => update('difficulty', next)}
          />
        </section>

        <div className="filters-match-count" aria-live="polite">
          {countLoading ? 'Counting matches…' : matchCount !== null ? `${matchCount} recipes match` : ''}
        </div>

        <section className="filters-section">
          <h2 className="filters-section-title">Saved presets</h2>
          {presets.length === 0 ? (
            <p className="filters-preset-empty">No saved presets yet.</p>
          ) : (
            <ul className="filters-preset-list">
              {presets.map((preset) => (
                <li key={preset.id} className="filters-preset-row">
                  <span>{preset.name}</span>
                  <div className="filters-preset-actions">
                    <button type="button" className="filters-link" onClick={() => handleApplyPreset(preset)}>
                      Apply
                    </button>
                    <button
                      type="button"
                      className="filters-link filters-link-danger"
                      onClick={() => handleDeletePreset(preset.id)}
                    >
                      Delete
                    </button>
                  </div>
                </li>
              ))}
            </ul>
          )}
          <div className="filters-save-preset">
            <TextField
              label="Save current filters as"
              placeholder="e.g. Quick weeknight dinners"
              value={presetName}
              onChange={(event) => setPresetName(event.target.value)}
            />
            <Button type="button" variant="ghost" onClick={handleSavePreset}>
              Save preset
            </Button>
          </div>
        </section>

        <div className="filters-actions">
          <Button type="button" variant="ghost" onClick={handleClearAll}>
            Clear all
          </Button>
          <Button type="button" onClick={handleApply}>
            Apply filters
          </Button>
        </div>
      </div>
    </AppShell>
  )
}
