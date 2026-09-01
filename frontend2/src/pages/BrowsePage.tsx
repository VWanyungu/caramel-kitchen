import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { apiGet } from "../lib/api";
import { FiltersModal } from "../components/FiltersModal";
import { Hero } from "../components/Hero";
import { Navbar } from "../components/Navbar";
import { RecipeGrid } from "../components/RecipeGrid";
import { SearchFilterBar } from "../components/SearchFilterBar";
import { CategoriesGrid } from "../components/CategoriesGrid";
import { EMPTY_FILTERS, type RecipeFilters } from "../features/browse/types";
import { useRecipes } from "../features/browse/useRecipes";
import { PLACEHOLDER_RECIPES } from "../features/browse/placeholderRecipes";

type ActiveTab = "recipes" | "categories" | "trending" | "new";

export function BrowsePage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const qParam = searchParams.get("q") || "";

  const [filters, setFilters] = useState<RecipeFilters>(() => ({
    ...EMPTY_FILTERS,
    q: qParam,
  }));
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [categories, setCategories] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState<ActiveTab>("recipes");
  const navigate = useNavigate();

  // Sync URL search query changes into local filters state
  useEffect(() => {
    setFilters((f) => ({ ...f, q: qParam }));
  }, [qParam]);

  // Sync internal filter query changes back to URL search params
  useEffect(() => {
    if (filters.q !== qParam) {
      setSearchParams((prev) => {
        if (filters.q) {
          prev.set("q", filters.q);
        } else {
          prev.delete("q");
        }
        return prev;
      }, { replace: true });
    }
  }, [filters.q, qParam, setSearchParams]);

  const handleQueryChange = (q: string) => {
    setSearchParams(
      (prev) => {
        if (q) {
          prev.set("q", q);
        } else {
          prev.delete("q");
        }
        return prev;
      },
      { replace: true }
    );
  };

  useEffect(() => {
    apiGet<{ data: Record<string, number> }>("/categories", undefined, {
      auth: false,
    })
      .then(({ data }) => setCategories(Object.keys(data)))
      .catch(() => setCategories([]));
  }, []);

  const { recipes, status, hasMore, loadMore } = useRecipes(filters);

  const handleSelectCategory = (catKey: string) => {
    if (catKey === "rift_valley") {
      setFilters((prev) => ({
        ...prev,
        category: "",
        cuisine: ["rift_valley"],
      }));
    } else {
      setFilters((prev) => ({
        ...prev,
        category: catKey,
        cuisine: [],
      }));
    }
    setActiveTab("recipes");
  };

  const handleSurpriseMe = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    const pool = recipes.length > 0 ? recipes : PLACEHOLDER_RECIPES;
    if (pool.length > 0) {
      const randomIndex = Math.floor(Math.random() * pool.length);
      const selectedRecipe = pool[randomIndex];
      navigate(`/recipes/${selectedRecipe.id}`);
    }
  };

  return (
    <div className="min-h-screen ">
      {/* <Navbar /> */}

      <div className="lg:px-52">

        {/* <Hero /> */}

        <SearchFilterBar
          query={filters.q}
          onQueryChange={handleQueryChange}
          onOpenFilters={() => setFiltersOpen(true)}
          filters={filters}
          onFiltersChange={setFilters}
          activeTab={activeTab}
          onActiveTabChange={setActiveTab}
        />

        <FiltersModal
          open={filtersOpen}
          onClose={() => setFiltersOpen(false)}
          categories={categories}
          filters={filters}
          onApply={(next) => setFilters(next)}
        />

        <main className=" px-8 lg:px-24 relative overflow-hidden min-h-[500px]">
          {/* Recipes view */}
          <div
            className={`transition-all duration-500 ease-in-out ${activeTab === "recipes"
              ? "opacity-100 translate-y-0 scale-100"
              : "opacity-0 translate-y-4 scale-95 pointer-events-none absolute inset-x-8 lg:inset-x-24 top-6"
              }`}
          >
            <RecipeGrid
              recipes={recipes}
              status={status}
              hasMore={hasMore}
              onLoadMore={loadMore}
            />
          </div>

          {/* Categories view */}
          <div
            className={`transition-all duration-500 ease-in-out ${activeTab === "categories"
              ? "opacity-100 translate-y-0 scale-100"
              : "opacity-0 -translate-y-4 scale-95 pointer-events-none absolute inset-x-8 lg:inset-x-24 top-6"
              }`}
          >
            <CategoriesGrid
              onSelectCategory={handleSelectCategory}
              onSurpriseMe={handleSurpriseMe}
            />
          </div>
        </main>
      </div>

    </div>
  );
}
