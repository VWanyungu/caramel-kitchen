import {
  ClockPlus,
  CookingPot,
  Flame,
  Scroll,
  Search,
  SlidersHorizontal,
  Sparkles,
  Tag,
  UserStar,
  X,
  Zap,
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

  if (filters.q) {
    activeChips.push({
      key: "q",
      label: `Search: "${filters.q}"`,
      onClear: () => {
        setDraft("");
        onFiltersChange({ ...filters, q: "" });
      },
    });
  }

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
    <div id="browse-filter-bar" className="mt-2 md:mt-6 mb-6 px-3 lg:px-24 font-sans">
      <div className="flex gap-1 md:gap-3 items-center justify-start md:flex-wrap overflow-x-auto">
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

      <div className="flex justify-between gap-1 items-center mt-4">
        <form
          onSubmit={(e) => e.preventDefault()}
          className="border-2 border-white dark:border-[#120905] flex gap-2 items-center justify-between w-full py-2 px-2 hover:bg-white dark:hover:bg-[#1d120a] hover:border-2 hover:border-butter/30 dark:hover:border-butter/30 focus-within:border-2 focus-within:border-butter/30 focus-within:bg-white dark:focus-within:bg-[#1d120a] bg-gray-100/50 dark:bg-[#1d120a]/40 rounded-full transition-all duration-300"
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

        <div className="border-2 border-white dark:border-[#120905] flex gap-2 items-center justify-between py-2 px-2 hover:bg-white dark:hover:bg-[#1d120a] hover:border-2 hover:border-butter/30 dark:hover:border-butter/30 focus-within:border-2 focus-within:border-butter/30 focus-within:bg-white dark:focus-within:bg-[#1d120a] bg-gray-100/50 dark:bg-[#1d120a]/40 rounded-full transition-all duration-300">
          <Button
            variant="primary"
            size="md"
            onClick={onOpenFilters}
            className="p-3! rounded-full! h-max!"
          >
            <SlidersHorizontal size={18} />
          </Button>
        </div>
      </div>


      <div className="mt-4 flex flex-col gap-2 md:gap-4 sm:flex-row sm:items-center sm:justify-between flex-wrap">
        <div className="flex flex-col gap-3 items-start">
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider flex items-center gap-1 mr-1 select-none">
              Popular:
            </span>

            <button
              type="button"
              onClick={() =>
                onFiltersChange({
                  ...filters,
                  dietary: filters.dietary.includes("budget_friendly")
                    ? filters.dietary
                    : [...filters.dietary, "budget_friendly"],
                })
              }
              className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-stone-800 bg-gray-50 dark:bg-[#1d120a] px-3.5 py-1 text-xs font-medium text-gray-700 dark:text-gray-200 hover:bg-amber-50 hover:border-amber-300 dark:hover:bg-[#251810] dark:hover:border-amber-900/50 hover:text-caramel transition-all duration-200 cursor-pointer shadow-2xs group"
            >
              <Tag className="w-3.5 h-3.5 text-amber-500 group-hover:scale-110 transition-transform" />
              <span>budget friendly</span>
            </button>

            <button
              type="button"
              onClick={() =>
                onFiltersChange({
                  ...filters,
                  cuisine: Array.from(
                    new Set([...filters.cuisine, "Kenyan", "East African"])
                  ),
                })
              }
              className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-stone-800 bg-gray-50 dark:bg-[#1d120a] px-3.5 py-1 text-xs font-medium text-gray-700 dark:text-gray-200 hover:bg-amber-50 hover:border-amber-300 dark:hover:bg-[#251810] dark:hover:border-amber-900/50 hover:text-caramel transition-all duration-200 cursor-pointer shadow-2xs group"
            >
              <Flame className="w-3.5 h-3.5 text-amber-600 group-hover:scale-110 transition-transform" />
              <span>Kenyand and East African</span>
            </button>

            <button
              type="button"
              onClick={() =>
                onFiltersChange({
                  ...filters,
                  maxTime: 30,
                  difficulty: "beginner",
                })
              }
              className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-stone-800 bg-gray-50 dark:bg-[#1d120a] px-3.5 py-1 text-xs font-medium text-gray-700 dark:text-gray-200 hover:bg-amber-50 hover:border-amber-300 dark:hover:bg-[#251810] dark:hover:border-amber-900/50 hover:text-caramel transition-all duration-200 cursor-pointer shadow-2xs group"
            >
              <Zap className="w-3.5 h-3.5 text-yellow-500 group-hover:scale-110 transition-transform" />
              <span>Quick and easy</span>
            </button>

            <button
              type="button"
              onClick={() =>
                onFiltersChange({
                  ...filters,
                  maxTime: 30,
                  difficulty: "beginner",
                })
              }
              className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-stone-800 bg-gray-50 dark:bg-[#1d120a] px-3.5 py-1 text-xs font-medium text-gray-700 dark:text-gray-200 hover:bg-amber-50 hover:border-amber-300 dark:hover:bg-[#251810] dark:hover:border-amber-900/50 hover:text-caramel transition-all duration-200 cursor-pointer shadow-2xs group"
            >
              <Zap className="w-3.5 h-3.5 text-yellow-500 group-hover:scale-110 transition-transform" />
              <span>International</span>
            </button>

            <button
              type="button"
              onClick={() =>
                onFiltersChange({
                  ...filters,
                  maxTime: 30,
                  difficulty: "beginner",
                })
              }
              className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-stone-800 bg-gray-50 dark:bg-[#1d120a] px-3.5 py-1 text-xs font-medium text-gray-700 dark:text-gray-200 hover:bg-amber-50 hover:border-amber-300 dark:hover:bg-[#251810] dark:hover:border-amber-900/50 hover:text-caramel transition-all duration-200 cursor-pointer shadow-2xs group"
            >
              <Zap className="w-3.5 h-3.5 text-yellow-500 group-hover:scale-110 transition-transform" />
              <span>Breakfast Ideas</span>
            </button>

            <button
              type="button"
              onClick={() =>
                onFiltersChange({
                  ...filters,
                  maxTime: 30,
                  difficulty: "beginner",
                })
              }
              className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 dark:border-stone-800 bg-gray-50 dark:bg-[#1d120a] px-3.5 py-1 text-xs font-medium text-gray-700 dark:text-gray-200 hover:bg-amber-50 hover:border-amber-300 dark:hover:bg-[#251810] dark:hover:border-amber-900/50 hover:text-caramel transition-all duration-200 cursor-pointer shadow-2xs group"
            >
              <Zap className="w-3.5 h-3.5 text-yellow-500 group-hover:scale-110 transition-transform" />
              <span>Seasonal</span>
            </button>
          </div>

          {activeChips.length > 0 ? (
            <div className="flex justify-start items-center gap-3">
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
            </div>
          ) : (
            <>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
