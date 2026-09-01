import {
  ClockPlus,
  CookingPot,
  Flame,
  Scroll,
  Search,
  SlidersHorizontal,
  UserStar,
  X,
} from "lucide-react";
import { useEffect, useState } from "react";
import { Button } from "./ui";
import { EMPTY_FILTERS, type RecipeFilters } from "../features/browse/types";

interface SearchFilterBarProps {
  query: string;
  onQueryChange: (q: string) => void;
  onOpenFilters: () => void;
  filters: RecipeFilters;
  onFiltersChange: (next: RecipeFilters) => void;
  activeTab: "recipes" | "categories" | "trending" | "new" | "for_you";
  onActiveTabChange: (
    tab: "recipes" | "categories" | "trending" | "new" | "for_you",
  ) => void;
}

export function SearchFilterBar({
  query,
  onQueryChange,
  onOpenFilters,
  filters,
  onFiltersChange,
  activeTab,
  onActiveTabChange,
}: SearchFilterBarProps) {
  const [draft, setDraft] = useState(query);

  useEffect(() => {
    const timeout = setTimeout(() => onQueryChange(draft), 300);
    return () => clearTimeout(timeout);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [draft]);

  // Sync draft query when filters.q changes externally (e.g. on clear all)
  useEffect(() => {
    setDraft(filters.q);
  }, [filters.q]);

  // Build active filter chips for display
  const activeChips: { key: string; label: string; onClear: () => void }[] = [];

  if (filters.category) {
    activeChips.push({
      key: "category",
      label: `Category: ${filters.category}`,
      onClear: () => onFiltersChange({ ...filters, category: "" }),
    });
  }

  if (filters.difficulty) {
    activeChips.push({
      key: "difficulty",
      label: `Difficulty: ${filters.difficulty}`,
      onClear: () => onFiltersChange({ ...filters, difficulty: "" }),
    });
  }

  filters.cuisine.forEach((c) => {
    activeChips.push({
      key: `cuisine-${c}`,
      label: c,
      onClear: () =>
        onFiltersChange({
          ...filters,
          cuisine: filters.cuisine.filter((x) => x !== c),
        }),
    });
  });

  filters.dietary.forEach((d) => {
    activeChips.push({
      key: `dietary-${d}`,
      label: d.replace("_", " "),
      onClear: () =>
        onFiltersChange({
          ...filters,
          dietary: filters.dietary.filter((x) => x !== d),
        }),
    });
  });

  if (filters.minTime !== undefined) {
    activeChips.push({
      key: "minTime",
      label: `Min: ${filters.minTime}m`,
      onClear: () => onFiltersChange({ ...filters, minTime: undefined }),
    });
  }

  if (filters.maxTime !== undefined) {
    activeChips.push({
      key: "maxTime",
      label: `Max: ${filters.maxTime}m`,
      onClear: () => onFiltersChange({ ...filters, maxTime: undefined }),
    });
  }

  // const activeFilterCount = activeChips.length;

  return (
    <div id="browse-filter-bar" className="mt-6 mb-6 px-8 lg:px-24 font-sans">
      <div className="flex gap-3 items-center justify-start flex-wrap">
        <Button
          variant={activeTab === "recipes" ? "outline" : "ghost"}
          size="md"
          icon={<CookingPot size={16} />}
          className={
            activeTab === "recipes"
              ? "bg-gray-100! dark:bg-[#1d120a]! border-transparent! hover:bg-gray-200! dark:hover:bg-[#251810]! text-ink dark:text-caramel!"
              : "text-gray-400 hover:text-ink dark:hover:text-parchment"
          }
          onClick={() => onActiveTabChange("recipes")}
        >
          Recipes
        </Button>

        <Button
          variant={activeTab === "categories" ? "outline" : "ghost"}
          size="md"
          icon={<Scroll size={16} />}
          className={
            activeTab === "categories"
              ? "bg-gray-100! dark:bg-[#1d120a]! border-transparent! hover:bg-gray-200! dark:hover:bg-[#251810]! text-ink dark:text-caramel!"
              : "text-gray-400 hover:text-ink dark:hover:text-parchment"
          }
          onClick={() => onActiveTabChange("categories")}
        >
          Categories
        </Button>

        <Button
          variant={activeTab === "trending" ? "outline" : "ghost"}
          size="md"
          icon={<Flame size={16} />}
          className={
            activeTab === "trending"
              ? "bg-gray-100! dark:bg-[#1d120a]! border-transparent! hover:bg-gray-200! dark:hover:bg-[#251810]! text-ink dark:text-caramel!"
              : "text-gray-400 hover:text-ink dark:hover:text-parchment"
          }
          onClick={() => onActiveTabChange("trending")}
        >
          Trending
        </Button>

        <Button
          variant={activeTab === "new" ? "outline" : "ghost"}
          size="md"
          icon={<ClockPlus size={16} />}
          className={
            activeTab === "new"
              ? "bg-gray-100! dark:bg-[#1d120a]! border-transparent! hover:bg-gray-200! dark:hover:bg-[#251810]! text-ink dark:text-caramel!"
              : "text-gray-400 hover:text-ink dark:hover:text-parchment"
          }
          onClick={() => onActiveTabChange("new")}
        >
          New
        </Button>

        <Button
          variant={activeTab === "for_you" ? "outline" : "ghost"}
          size="md"
          icon={<UserStar size={16} />}
          className={
            activeTab === "for_you"
              ? "bg-gray-100! dark:bg-[#1d120a]! border-transparent! hover:bg-gray-200! dark:hover:bg-[#251810]! text-ink dark:text-caramel!"
              : "text-gray-400 hover:text-ink dark:hover:text-parchment"
          }
          onClick={() => onActiveTabChange("for_you")}
        >
          For you
        </Button>

        {/* <Button
          variant="ghost"
          size="md"
          icon={<ChefHat size={16} />}
          className="text-gray-400 hover:text-ink opacity-60 cursor-not-allowed"
          disabled
        >
          Chefs
        </Button>

        <Button
          variant="ghost"
          size="md"
          icon={<ChefHat size={16} />}
          className="text-gray-400 hover:text-ink opacity-60 cursor-not-allowed"
          disabled
        >
          Meal plans
        </Button> */}
      </div>

      <form
        onSubmit={(e) => e.preventDefault()}
        className="border-2 border-white dark:border-[#120905] flex gap-2 items-center justify-between mt-4 w-full py-2 px-2 hover:bg-white dark:hover:bg-[#1d120a] hover:border-2 hover:border-butter/30 dark:hover:border-butter/30 focus-within:border-2 focus-within:border-butter/30 focus-within:bg-white dark:focus-within:bg-[#1d120a] bg-gray-100/50 dark:bg-[#1d120a]/40 rounded-full transition-all duration-300"
      >
        <input
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          placeholder="What recipe are you looking for?"
          type="search"
          aria-label="Search recipes"
          className="flex-1 focus:outline-none ml-6 h-full bg-transparent text-sm text-ink dark:text-caramel placeholder:text-gray-400"
        />

        <Button
          type="submit"
          variant="primary"
          size="sm"
          className="p-3! 1rounded-full!"
          aria-label="Search"
        >
          <Search size={18} />
        </Button>
      </form>

      <div className="mt-4 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between pl-6 flex-wrap">
        <div className="flex gap-3 items-center justify-start flex-wrap">
          {activeChips.length > 0 ? (
            <>
              {activeChips.map((chip) => (
                <div
                  key={chip.key}
                  className="inline-flex items-center gap-1.5 rounded-full border border-gray-300 dark:border-stone-800 bg-white dark:bg-[#1d120a] px-3 py-1 text-xs text-gray-600 dark:text-gray-300 shadow-2xs hover:bg-gray-50 dark:hover:bg-[#120905] transition-colors font-sans select-none"
                >
                  <span className="capitalize">{chip.label}</span>
                  <button
                    type="button"
                    onClick={chip.onClear}
                    aria-label={`Remove ${chip.label} filter`}
                    className="cursor-pointer rounded-full p-0.5 text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition-colors focus:outline-none"
                  >
                    <X className="h-3 w-3" />
                  </button>
                </div>
              ))}
              <button
                type="button"
                onClick={() => {
                  setDraft("");
                  onFiltersChange({ ...EMPTY_FILTERS, q: "" });
                }}
                className="text-xs text-caramel hover:text-mahogany font-semibold cursor-pointer underline underline-offset-2 ml-1"
              >
                Clear all
              </button>
            </>
          ) : (
            <span className="text-sm text-gray-400 font-sans">
              No active filters
            </span>
          )}
        </div>

        <div className="flex gap-6 items-center self-end sm:self-auto">
          <Button
            variant="dark"
            size="sm"
            icon={<SlidersHorizontal size={18} />}
            onClick={onOpenFilters}
            className="relative "
          >
            Filters
            {/* {activeFilterCount > 0 && (
              <span className="ml-1.5 flex h-5 w-5 items-center justify-center rounded-full bg-caramel text-xs font-medium text-white">
                {activeFilterCount}
              </span>
            )} */}
          </Button>
        </div>
      </div>
    </div>
  );
}
