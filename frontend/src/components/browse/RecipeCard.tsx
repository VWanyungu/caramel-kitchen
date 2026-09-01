import TastePill, { type TasteTone } from '../ui/TastePill'
import { humanize } from '../../lib/recipeTaxonomy'
import type { RecipeCard as RecipeCardData } from '../../types/browse'
import './recipe-card.css'

export default function RecipeCard({ recipe }: { recipe: RecipeCardData }) {
  return (
    <article className="recipe-card">
      <div className="recipe-card-thumb" aria-hidden="true">
        {recipe.thumbnail_url ? (
          <img src={recipe.thumbnail_url} alt="" loading="lazy" />
        ) : (
          <span className="recipe-card-thumb-fallback">{recipe.title.charAt(0)}</span>
        )}
      </div>

      <div className="recipe-card-body">
        <h3 className="recipe-card-title">{recipe.title}</h3>

        <div className="recipe-card-meta">
          <span>{recipe.total_time_mins} min</span>
          <span aria-hidden="true">·</span>
          <span>{humanize(recipe.difficulty)}</span>
          {recipe.avg_rating > 0 && (
            <>
              <span aria-hidden="true">·</span>
              <span>★ {recipe.avg_rating.toFixed(1)}</span>
            </>
          )}
        </div>

        {recipe.taste_tags.length > 0 && (
          <div className="recipe-card-pills">
            {recipe.taste_tags.map((tag) => (
              <TastePill key={tag} label={humanize(tag)} active tone={tag as TasteTone} />
            ))}
          </div>
        )}

        {recipe.dietary_flags.length > 0 && (
          <div className="recipe-card-dietary">
            {recipe.dietary_flags.map((flag) => (
              <span key={flag} className="recipe-card-dietary-badge">
                {humanize(flag)}
              </span>
            ))}
          </div>
        )}
      </div>
    </article>
  )
}
