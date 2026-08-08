import { useEffect, useState } from "react";
import { apiGet } from "../../lib/api";
import { FiltersModal } from "./FiltersModal";
import { Hero } from "./Hero";
import { Navbar } from "./Navbar";
import { RecipeGrid } from "./RecipeGrid";
import { SearchFilterBar } from "./SearchFilterBar";
import { EMPTY_FILTERS, type RecipeFilters } from "./types";
import { useRecipes } from "./useRecipes";

export function BrowsePage() {
  const [filters, setFilters] = useState<RecipeFilters>(EMPTY_FILTERS);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [categories, setCategories] = useState<string[]>([]);

  useEffect(() => {
    apiGet<{ data: Record<string, number> }>("/categories", undefined, {
      auth: false,
    })
      .then(({ data }) => setCategories(Object.keys(data)))
      .catch(() => setCategories([]));
  }, []);

  const { recipes, status, hasMore, loadMore } = useRecipes(filters);

  const activeFilterCount = [
    filters.category,
    filters.difficulty,
    ...filters.cuisine,
    ...filters.dietary,
    filters.minTime,
    filters.maxTime,
  ].filter((v) => v !== "" && v !== undefined).length;

  return (
    <div className="min-h-screen">
      <Navbar />

      <Hero />

      <SearchFilterBar
        query={filters.q}
        onQueryChange={(q) => setFilters((f) => ({ ...f, q }))}
        onOpenFilters={() => setFiltersOpen(true)}
        activeFilterCount={activeFilterCount}
      />

      <FiltersModal
        open={filtersOpen}
        onClose={() => setFiltersOpen(false)}
        categories={categories}
        filters={filters}
        onApply={(next) => setFilters(next)}
      />

      <main className="mt-10 py-6 px-8 lg:px-24">
        <RecipeGrid
          recipes={recipes}
          status={status}
          hasMore={hasMore}
          onLoadMore={loadMore}
        />
      </main>
    </div>
  );
}
