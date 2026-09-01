import type { RecipeStatus } from '../../types/recipe'
import './admin.css'

const LABELS: Record<RecipeStatus, string> = {
  draft: 'Draft',
  scheduled: 'Scheduled',
  live: 'Live',
  archived: 'Archived',
}

export default function StatusDot({ status }: { status: RecipeStatus }) {
  return (
    <span className="status-dot-row">
      <span className={`status-dot status-dot-${status}`} aria-hidden="true" />
      {LABELS[status]}
    </span>
  )
}
