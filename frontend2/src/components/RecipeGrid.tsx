import type { RecipeCard as RecipeCardData } from "../features/browse/types";
import { RecipeCard } from "./RecipeCard";

interface RecipeGridProps {
  recipes: RecipeCardData[];
  status: "loading" | "success" | "error";
  hasMore: boolean;
  onLoadMore: () => void;
}

function SkeletonCard() {
  return (
    <div className="aspect-[3/4] animate-pulse rounded-xl bg-taupe/20 motion-reduce:animate-none" />
  );
}

export function RecipeGrid({
  recipes,
  status,
  hasMore,
  onLoadMore,
}: RecipeGridProps) {
  if (status === "loading") {
    return (
      <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4">
        {Array.from({ length: 10 }).map((_, i) => (
          <SkeletonCard key={i} />
        ))}
      </div>
    );
  }

  if (status === "error") {
    return (
      <p className="py-16 text-center font-sans text-taupe">
        Something went wrong loading recipes. Please try again.
      </p>
    );
  }

  if (recipes.length === 0) {
    return (
      <p className="py-16 text-center font-sans text-taupe">
        No recipes match your search. Try a different term or clear a few
        filters.
      </p>
    );
  }

  return (
    <div>
      <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4">
        {recipes.map((recipe) => (
          <RecipeCard key={recipe.id} recipe={recipe} />
        ))}
      </div>

      {hasMore && (
        <div className="mt-8 flex justify-center">
          <button
            type="button"
            onClick={onLoadMore}
            className="rounded-full border border-taupe/30 px-6 py-2.5 font-sans text-sm text-ink transition-colors hover:border-caramel motion-reduce:transition-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-caramel"
          >
            Load more
          </button>
        </div>
      )}
    </div>
  );
}
