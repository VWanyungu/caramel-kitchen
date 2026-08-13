import {
  ChefHat,
  CookingPot,
  Scroll,
  Search,
  SlidersHorizontal,
} from "lucide-react";
import { useEffect, useState } from "react";
import { Button, Dropdown } from "../../components/ui";

interface SearchFilterBarProps {
  query: string;
  onQueryChange: (q: string) => void;
  onOpenFilters: () => void;
  activeFilterCount: number;
}

const SELECT_OPTIONS = [
  "Vegetarian",
  "Gluten Free",
  "High Protein",
  "Quick & Easy",
  "Desserts",
];

export function SearchFilterBar({
  query,
  onQueryChange,
  onOpenFilters,
  activeFilterCount,
}: SearchFilterBarProps) {
  const [draft, setDraft] = useState(query);

  useEffect(() => {
    const timeout = setTimeout(() => onQueryChange(draft), 300);
    return () => clearTimeout(timeout);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [draft]);

  return (
    <div className="mt-12 mb-6 px-8 lg:px-24 font-sans">
      <div className="flex gap-6 items-center justify-start">
        <Button
          variant="outline"
          size="md"
          icon={<CookingPot size={16} />}
          className="bg-gray-100! border-transparent! hover:bg-gray-200!"
        >
          Recipes
        </Button>

        <Button
          variant="ghost"
          size="md"
          icon={<Scroll size={16} />}
          className="text-gray-400 hover:text-ink"
        >
          Categories
        </Button>

        <Button
          variant="ghost"
          size="md"
          icon={<ChefHat size={16} />}
          className="text-gray-400 hover:text-ink"
        >
          Authors
        </Button>
      </div>

      <form
        onSubmit={(e) => e.preventDefault()}
        className="border-2 border-white flex gap-2 items-center justify-between mt-4 w-full py-2 px-2 hover:bg-white hover:border-2 hover:border-butter/30 focus-within:border-2 focus-within:border-butter/30 focus-within:bg-white bg-gray-100/50 rounded-full"
      >
        <input
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          placeholder="What recipe are you looking for?"
          type="search"
          aria-label="Search recipes"
          className="flex-1 focus:outline-none ml-6 h-full bg-transparent text-sm text-ink placeholder:text-gray-400"
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

      <div className="mt-4 flex items-center justify-between pl-6">
        <div className="flex gap-4 items-center justify-start flex-wrap">
          <span className="font-bold text-sm text-ink">Popular:</span>

          <Button
            variant="chip"
            size="sm"
            onClick={() => setDraft("vegetarian")}
          >
            vegetarian
          </Button>

          <Button
            variant="chip"
            size="sm"
            onClick={() => setDraft("high protein")}
          >
            high protein
          </Button>

          <Button
            variant="chip"
            size="sm"
            onClick={() => setDraft("high fibre")}
          >
            high fibre
          </Button>

          <Button
            variant="chip"
            size="sm"
            onClick={() => setDraft("gluten free")}
          >
            gluten free
          </Button>
        </div>

        <div className="flex gap-6 items-center">
          <Dropdown
            options={SELECT_OPTIONS}
            size="sm"
            onChange={(val) => setDraft(val)}
          />

          <Button
            variant="outline"
            size="sm"
            icon={<SlidersHorizontal size={18} />}
            onClick={onOpenFilters}
            className="relative"
          >
            Filters
            {activeFilterCount > 0 && (
              <span className="ml-1.5 flex h-5 w-5 items-center justify-center rounded-full bg-caramel text-xs font-medium text-white">
                {activeFilterCount}
              </span>
            )}
          </Button>
        </div>
      </div>
    </div>
  );
}
