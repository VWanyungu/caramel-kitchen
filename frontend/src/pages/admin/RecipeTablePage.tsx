import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import ConfirmDialog from '../../components/admin/ConfirmDialog'
import StatusDot from '../../components/admin/StatusDot'
import Button from '../../components/ui/Button'
import { archiveRecipe, deleteRecipe, listRecipes, publishRecipe } from '../../lib/adminRecipesApi'
import { extractErrorMessage } from '../../lib/api'
import { humanize } from '../../lib/recipeTaxonomy'
import type { AdminRecipe, RecipeStatus } from '../../types/recipe'
import './recipe-table.css'

const TABS: Array<{ label: string; value: RecipeStatus | 'all' }> = [
  { label: 'All', value: 'all' },
  { label: 'Draft', value: 'draft' },
  { label: 'Scheduled', value: 'scheduled' },
  { label: 'Live', value: 'live' },
  { label: 'Archived', value: 'archived' },
]

export default function RecipeTablePage() {
  const [tab, setTab] = useState<RecipeStatus | 'all'>('all')
  const [recipes, setRecipes] = useState<AdminRecipe[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [pendingId, setPendingId] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<AdminRecipe | null>(null)

  const load = useCallback(async (status: RecipeStatus | 'all') => {
    setLoading(true)
    setError(null)
    try {
      const data = await listRecipes(status)
      setRecipes(data)
    } catch (err) {
      setError(extractErrorMessage(err, 'Could not load recipes.'))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    let cancelled = false

    // Canonical React data-fetching-with-cancellation pattern (see react.dev "You Might Not
    // Need an Effect"): resetting loading/error synchronously before the fetch is intentional.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true)
    setError(null)
    listRecipes(tab)
      .then((data) => {
        if (!cancelled) setRecipes(data)
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
  }, [tab])

  async function handlePublish(recipe: AdminRecipe) {
    setActionError(null)
    setPendingId(recipe.id)
    try {
      await publishRecipe(recipe.id)
      await load(tab)
    } catch (err) {
      setActionError(extractErrorMessage(err, 'Could not publish this recipe.'))
    } finally {
      setPendingId(null)
    }
  }

  async function handleArchive(recipe: AdminRecipe) {
    setActionError(null)
    setPendingId(recipe.id)
    try {
      await archiveRecipe(recipe.id)
      await load(tab)
    } catch (err) {
      setActionError(extractErrorMessage(err, 'Could not archive this recipe.'))
    } finally {
      setPendingId(null)
    }
  }

  async function handleDelete() {
    if (!deleteTarget) return
    setActionError(null)
    setPendingId(deleteTarget.id)
    try {
      await deleteRecipe(deleteTarget.id)
      setDeleteTarget(null)
      await load(tab)
    } catch (err) {
      setActionError(extractErrorMessage(err, 'Could not delete this recipe.'))
    } finally {
      setPendingId(null)
    }
  }

  return (
    <div className="recipe-table-page">
      <div className="recipe-table-header">
        <div>
          <p className="eyebrow">Content</p>
          <h1 className="recipe-table-title">Your recipes</h1>
        </div>
        <Link to="/admin/recipes/new">
          <Button type="button">New Recipe</Button>
        </Link>
      </div>

      <div className="status-tabs" role="tablist" aria-label="Filter recipes by status">
        {TABS.map((item) => (
          <button
            key={item.value}
            type="button"
            role="tab"
            aria-selected={tab === item.value}
            className={['status-tab', tab === item.value ? 'is-active' : ''].join(' ')}
            onClick={() => setTab(item.value)}
          >
            {item.label}
          </button>
        ))}
      </div>

      {actionError && (
        <p className="form-banner-error" role="alert">
          {actionError}
        </p>
      )}

      {error && (
        <p className="form-banner-error" role="alert">
          {error}
        </p>
      )}

      {loading ? (
        <p className="recipe-table-empty">Loading recipes…</p>
      ) : recipes.length === 0 ? (
        <div className="recipe-table-empty">
          <p>No recipes yet — create your first one.</p>
          <Link to="/admin/recipes/new">
            <Button type="button">New Recipe</Button>
          </Link>
        </div>
      ) : (
        <div className="recipe-table-wrap">
          <table className="recipe-table">
            <thead>
              <tr>
                <th>Title</th>
                <th>Status</th>
                <th>Category</th>
                <th>Course</th>
                <th>Method</th>
                <th>Updated</th>
                <th aria-label="Actions" />
              </tr>
            </thead>
            <tbody>
              {recipes.map((recipe) => (
                <tr key={recipe.id}>
                  <td>
                    <span className="recipe-table-recipe-title">{recipe.title}</span>
                  </td>
                  <td>
                    <StatusDot status={recipe.status} />
                  </td>
                  <td>{recipe.dish_category ? humanize(recipe.dish_category) : '—'}</td>
                  <td>{recipe.course ? humanize(recipe.course) : '—'}</td>
                  <td>{humanize(recipe.primary_method)}</td>
                  <td>{new Date(recipe.updated_at).toLocaleDateString()}</td>
                  <td>
                    <div className="recipe-table-actions">
                      <Link to={`/admin/recipes/${recipe.id}/edit`} className="recipe-table-link">
                        Edit
                      </Link>
                      {recipe.status !== 'live' && recipe.status !== 'archived' && (
                        <button
                          type="button"
                          className="recipe-table-link"
                          disabled={pendingId === recipe.id}
                          onClick={() => handlePublish(recipe)}
                        >
                          Publish
                        </button>
                      )}
                      {recipe.status !== 'archived' && (
                        <button
                          type="button"
                          className="recipe-table-link"
                          disabled={pendingId === recipe.id}
                          onClick={() => handleArchive(recipe)}
                        >
                          Archive
                        </button>
                      )}
                      <button
                        type="button"
                        className="recipe-table-link recipe-table-link-danger"
                        disabled={pendingId === recipe.id}
                        onClick={() => setDeleteTarget(recipe)}
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <ConfirmDialog
        open={Boolean(deleteTarget)}
        title="Delete this recipe?"
        description={`"${deleteTarget?.title}" will be permanently removed. This can't be undone.`}
        confirmLabel="Delete"
        destructive
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  )
}
