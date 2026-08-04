import { useEffect, useState, type FormEvent } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import AppShell from '../components/app/AppShell'
import RecipeCard from '../components/browse/RecipeCard'
import Button from '../components/ui/Button'
import { extractErrorMessage } from '../lib/api'
import { countActiveFilters, searchParamsToFilters } from '../lib/filterQueryString'
import { listRecipes, searchRecipes } from '../lib/recipesApi'
import { humanize } from '../lib/recipeTaxonomy'
import type { RecipeCard as RecipeCardData, RecipeFilters } from '../types/browse'
import './user-home.css'

const PAGE_SIZE = 20

interface ActiveChip {
  key: keyof RecipeFilters
  label: string
}

function activeChips(filters: RecipeFilters): ActiveChip[] {
  const chips: ActiveChip[] = []
  if (filters.category) chips.push({ key: 'category', label: `Category: ${humanize(filters.category)}` })
  if (filters.course) chips.push({ key: 'course', label: `Course: ${humanize(filters.course)}` })
  if (filters.cooking_method) chips.push({ key: 'cooking_method', label: `Method: ${humanize(filters.cooking_method)}` })
  if (filters.difficulty) chips.push({ key: 'difficulty', label: `Difficulty: ${humanize(filters.difficulty)}` })
  if (filters.dietary.length) chips.push({ key: 'dietary', label: `Dietary: ${filters.dietary.map(humanize).join(', ')}` })
  if (filters.taste.length) chips.push({ key: 'taste', label: `Taste: ${filters.taste.map(humanize).join(', ')}` })
  if (filters.cuisine.length) chips.push({ key: 'cuisine', label: `Cuisine: ${filters.cuisine.map(humanize).join(', ')}` })
  if (filters.min_time) chips.push({ key: 'min_time', label: `Min ${filters.min_time} min` })
  if (filters.max_time) chips.push({ key: 'max_time', label: `Max ${filters.max_time} min` })
  if (filters.max_calories) chips.push({ key: 'max_calories', label: `Under ${filters.max_calories} kcal` })
  if (filters.context) chips.push({ key: 'context', label: humanize(filters.context) })
  return chips
}

export default function UserHomePage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const filters = searchParamsToFilters(searchParams)
  const query = searchParams.get('q') ?? ''
  const [searchInput, setSearchInput] = useState(query)

  const [recipes, setRecipes] = useState<RecipeCardData[]>([])
  const [afterId, setAfterId] = useState<string | undefined>(undefined)
  const [loading, setLoading] = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    // Keep the search box in sync when the URL's `q` changes from outside this input
    // (clearing filters, removing a chip, navigating back from /filters).
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setSearchInput(query)
  }, [query])

  useEffect(() => {
    let cancelled = false

    // Canonical React data-fetching-with-cancellation pattern (see react.dev "You Might Not
    // Need an Effect"): resetting loading/error synchronously before the fetch is intentional.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true)
    setError(null)
    const fetcher = query
      ? searchRecipes(query, filters, { limit: PAGE_SIZE })
      : listRecipes(filters, { limit: PAGE_SIZE })

    fetcher
      .then((result) => {
        if (cancelled) return
        setRecipes(result.data)
        setAfterId(result.meta.after_id)
      })
      .catch((err) => {
        if (!cancelled) setError(extractErrorMessage(err, 'Could not load recipes.'))
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })

    return () => {
      cancelled = true
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams.toString()])

  async function handleLoadMore() {
    setLoadingMore(true)
    try {
      const result = query
        ? await searchRecipes(query, filters, { limit: PAGE_SIZE, offset: recipes.length })
        : await listRecipes(filters, { limit: PAGE_SIZE, after_id: afterId })
      setRecipes((current) => [...current, ...result.data])
      setAfterId(result.meta.after_id)
    } catch (err) {
      setError(extractErrorMessage(err, 'Could not load more recipes.'))
    } finally {
      setLoadingMore(false)
    }
  }

  function handleSearchSubmit(event: FormEvent) {
    event.preventDefault()
    const next = new URLSearchParams(searchParams)
    if (searchInput.trim()) {
      next.set('q', searchInput.trim())
    } else {
      next.delete('q')
    }
    setSearchParams(next)
  }

  function removeFilter(key: keyof RecipeFilters) {
    const next = new URLSearchParams(searchParams)
    next.delete(key)
    setSearchParams(next)
  }

  const chips = activeChips(filters)
  const filterCount = countActiveFilters(filters)

  return (
    <AppShell>
      <div className="browse-page">
        <div className="browse-header">
          <div>
            <p className="eyebrow">Discover</p>
            <h1 className="shell-title">Find something to cook</h1>
          </div>
          <Link to="/filters">
            <Button type="button" variant="ghost">
              Advanced filters{filterCount > 0 ? ` (${filterCount})` : ''}
            </Button>
          </Link>
        </div>

        <form className="browse-search" onSubmit={handleSearchSubmit} role="search">
          <input
            className="field-input browse-search-input"
            type="search"
            placeholder="Search recipes, ingredients…"
            value={searchInput}
            onChange={(event) => setSearchInput(event.target.value)}
            aria-label="Search recipes"
          />
          <Button type="submit">Search</Button>
        </form>

        {chips.length > 0 && (
          <div className="browse-active-chips">
            {chips.map((chip) => (
              <button
                type="button"
                key={chip.key}
                className="browse-active-chip"
                onClick={() => removeFilter(chip.key)}
              >
                {chip.label} <span aria-hidden="true">×</span>
              </button>
            ))}
            <button type="button" className="browse-clear-all" onClick={() => setSearchParams(new URLSearchParams())}>
              Clear all
            </button>
          </div>
        )}

        {error && (
          <p className="form-banner-error" role="alert">
            {error}
          </p>
        )}

        {loading ? (
          <p className="browse-empty">Loading recipes…</p>
        ) : recipes.length === 0 ? (
          <div className="browse-empty">
            <p>No recipes match yet — try adjusting your filters or search.</p>
            {filterCount > 0 && (
              <Button type="button" variant="ghost" onClick={() => setSearchParams(new URLSearchParams())}>
                Clear filters
              </Button>
            )}
          </div>
        ) : (
          <>
            <div className="browse-grid">
              {recipes.map((recipe) => (
                <RecipeCard key={recipe.id} recipe={recipe} />
              ))}
            </div>
            {afterId && !query && (
              <div className="browse-load-more">
                <Button type="button" variant="ghost" loading={loadingMore} onClick={handleLoadMore}>
                  Load more
                </Button>
              </div>
            )}
            {query && recipes.length >= PAGE_SIZE && (
              <div className="browse-load-more">
                <Button type="button" variant="ghost" loading={loadingMore} onClick={handleLoadMore}>
                  Load more
                </Button>
              </div>
            )}
          </>
        )}
      </div>
    </AppShell>
  )
}
