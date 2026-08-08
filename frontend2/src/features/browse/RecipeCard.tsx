import { Bookmark, Clock, Star } from "lucide-react";
import { useState, type MouseEvent } from "react";
import { apiPost } from "../../lib/api";
import type { RecipeCard as RecipeCardData } from "./types";

export function RecipeCard({ recipe }: { recipe: RecipeCardData }) {
  const [saved, setSaved] = useState(false);
  const [pending, setPending] = useState(false);

  const handleToggleSave = async (e: MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (pending) return;

    if (saved) {
      // No unsave/DELETE endpoint exists on the backend (append-only interaction log).
      // TODO: wire to a real unsave endpoint once one exists.
      setSaved(false);
      return;
    }

    setSaved(true);
    setPending(true);
    try {
      await apiPost(`/recipes/${recipe.id}/save`);
    } catch {
      setSaved(false);
    } finally {
      setPending(false);
    }
  };

  return (
    <div className="cursor-pointer">
      <div className="relative aspect-[16/9] overflow-hidden rounded-lg bg-taupe/20 shadow-lg">
        <div
          className="absolute inset-0 bg-cover bg-center transition-transform duration-300 group-hover:scale-105 motion-reduce:transition-none motion-reduce:group-hover:scale-100 shadow-lg"
          style={
            recipe.thumbnail_url
              ? { backgroundImage: `url(${recipe.thumbnail_url})` }
              : undefined
          }
        />
        {/* <div className="absolute inset-0 bg-gradient-to-t from-ink/100  to-transparent" /> */}
        <button
          type="button"
          onClick={handleToggleSave}
          aria-pressed={saved}
          aria-label={saved ? "Remove from saved recipes" : "Save recipe"}
          className="cursor-pointer absolute right-4 top-4 rounded-full bg-ink/30 p-2 backdrop-blur-sm transition-colors hover:bg-ink/50 motion-reduce:transition-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-butter"
        >
          <Bookmark
            className={`h-4 w-4 ${saved ? "fill-butter text-butter" : "fill-transparent text-parchment"}`}
          />
        </button>
      </div>



      <div className="mt-3">
        {/* <h3 className="text-sm leading-tight">
          {recipe.title}
        </h3> */}

        <div className="mt-2 flex items-center justify-between gap-3 font-sans text-xs">
          <h3 className="text-sm leading-tight max-w-[30ch]" title={`${recipe.title}`}>
            {recipe.title.length > 26 ? recipe.title.slice(0, 26) + '...' : recipe.title}
          </h3>
          <div className="flex gap-2 items-center justify-end">
            <span
              className={`rounded-sm px-2 py-1 text-[10px] uppercase bg-gray-200 text-gray-500 font-bold tracking-wide`}
            >
              {recipe.difficulty}
            </span>
            <span className="flex items-center gap-1 text-gray-400">
              <Star className="h-3.5 w-3.5 fill-gray-200 text-gray-400" />
              {recipe.avg_rating.toFixed(1)}
            </span>
            <span className="flex items-center gap-1 text-gray-400">
              <Clock className="h-3.5 w-3.5" />
              {recipe.total_time_mins}m
            </span>

          </div>

        </div>
      </div>
    </div>
  );
}
