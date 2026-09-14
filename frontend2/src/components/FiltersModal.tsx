import { X } from "lucide-react";
import { useEffect, useState } from "react";
import { Button, Dropdown, MultiSelectDropdown, DurationPicker } from "./ui";
import {
  EMPTY_FILTERS,
  type Difficulty,
  type RecipeFilters,
} from "../features/browse/types";

const CUISINES = [
  "Kenyan",
  "East African",
  "African",
  "Indian",
  "Italian",
  "Chinese",
  "Mexican",
  "Japanese",
  "Thai",
  "Korean",
  "Other International cuisines",
];

const DIETARY_FLAGS = [
  "Vegetarian",
  "Vegan",
  "Gluten-Free",
  "Dairy-Free",
  "High Protein",
];

const COURSES = [
  "Starter/Appetizer",
  "Main Course",
  "Side Dish",
  "Dessert",
  "Snack",
]

const MEALS = [
  "Breakfast",
  "Lunch",
  "Dinner",
  "Tea Time",
  "Snack",
]

const COOKING_METHOD = [
  "Boiling",
  "Frying",
  "Baking",
  "Grilling",
  "Roasting",
  "Steaming",
  "Air Frying",
  "Air Frying",
  "No-Cooking"
]

const COOKING_TIME = [
  "Under 15 minutes",
  "15–30 minutes",
  "30–60 minutes",
  "60+ minutes",
]

const TASTE = [
  "Sweet",
  "Savory",
  "Spicy",
  "Mild",
  "Tangy",
]




const DIFFICULTIES: Difficulty[] = ["beginner", "intermediate", "advanced"];

interface FiltersModalProps {
  open: boolean;
  onClose: () => void;
  categories: string[];
  filters: RecipeFilters;
  onApply: (filters: RecipeFilters) => void;
}



export function FiltersModal({
  open,
  onClose,
  categories,
  filters,
  onApply,
}: FiltersModalProps) {
  const [draft, setDraft] = useState<RecipeFilters>(filters);

  useEffect(() => {
    const set = () => {
      if (open) setDraft(filters);
    };
    set();
  }, [open, filters]);

  useEffect(() => {
    if (!open) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, onClose]);

  if (!open) return null;

  const categoryOptions = [
    { label: "Any category", value: "" },
    ...categories.map((c) => ({ label: c, value: c })),
  ];

  return (
    <div className="fixed inset-0 z-30 flex items-end justify-center bg-black/40 backdrop-blur-xs p-0 sm:items-center sm:p-6">
      <button
        type="button"
        aria-label="Close filters"
        onClick={onClose}
        className="absolute inset-0 cursor-default"
      />

      <div
        role="dialog"
        aria-modal="true"
        aria-label="Filter recipes"
        className="relative z-10 max-h-[85vh] w-full max-w-lg overflow-y-auto rounded-t-2xl bg-white p-6 shadow-2xl border border-gray-100 sm:rounded-2xl"
      >
        <div className="mb-6 flex items-center justify-between border-b border-gray-100 pb-4">
          <h2 className="font-serif text-xl text-ink font-semibold">
            Filter Recipes
          </h2>
          <Button
            variant="ghost"
            size="sm"
            onClick={onClose}
            aria-label="Close"
            className="p-2! rounded-full text-gray-400 hover:text-ink hover:bg-gray-100"
          >
            <X className="h-5 w-5" />
          </Button>
        </div>

        <div className="space-y-6 font-sans">
          <div>
            <Dropdown
              label="Category"
              options={categoryOptions}
              value={draft.category}
              placeholder="Any category"
              fullWidth
              onChange={(val) => setDraft((d) => ({ ...d, category: val }))}
            />
          </div>

          <div>
            <span className="mb-2 block text-xs font-semibold uppercase tracking-wider text-gray-500">
              Difficulty
            </span>
            <div className="flex gap-2">
              {DIFFICULTIES.map((level) => {
                const isSelected = draft.difficulty === level;
                return (
                  <Button
                    key={level}
                    variant="chip"
                    size="sm"
                    isActive={isSelected}
                    onClick={() =>
                      setDraft((d) => ({
                        ...d,
                        difficulty: isSelected ? "" : level,
                      }))
                    }
                    className="capitalize"
                  >
                    {level}
                  </Button>
                );
              })}
            </div>
          </div>

          <div>
            <MultiSelectDropdown
              label="Cuisine"
              options={CUISINES.map((c) => ({ label: c, value: c }))}
              value={draft.cuisine}
              placeholder="Any cuisine"
              fullWidth
              onChange={(val) => setDraft((d) => ({ ...d, cuisine: val }))}
            />
          </div>

          <div>
            <MultiSelectDropdown
              label="Dietary"
              options={DIETARY_FLAGS.map((d) => ({ label: d.replace("_", " "), value: d }))}
              value={draft.dietary}
              placeholder="Any dietary"
              fullWidth
              onChange={(val) => setDraft((d) => ({ ...d, dietary: val }))}
            />
          </div>

          <div>
            <MultiSelectDropdown
              label="Courses"
              options={COURSES.map((c) => ({ label: c, value: c }))}
              value={draft.courses}
              placeholder="Any course"
              fullWidth
              onChange={(val) => setDraft((d) => ({ ...d, courses: val }))}
            />
          </div>

          <div>
            <MultiSelectDropdown
              label="Meals"
              options={MEALS.map((m) => ({ label: m, value: m }))}
              value={draft.meals}
              placeholder="Any meal"
              fullWidth
              onChange={(val) => setDraft((d) => ({ ...d, meals: val }))}
            />
          </div>

          <div>
            <MultiSelectDropdown
              label="Cooking Method"
              options={COOKING_METHOD.map((c) => ({ label: c, value: c }))}
              value={draft.cookingMethods}
              placeholder="Any method"
              fullWidth
              onChange={(val) => setDraft((d) => ({ ...d, cookingMethods: val }))}
            />
          </div>

          <div>
            <MultiSelectDropdown
              label="Cooking Time"
              options={COOKING_TIME.map((c) => ({ label: c, value: c }))}
              value={draft.cookingTimes}
              placeholder="Any time"
              fullWidth
              onChange={(val) => setDraft((d) => ({ ...d, cookingTimes: val }))}
            />
          </div>

          <div>
            <MultiSelectDropdown
              label="Taste"
              options={TASTE.map((t) => ({ label: t, value: t }))}
              value={draft.tastes}
              placeholder="Any taste"
              fullWidth
              onChange={(val) => setDraft((d) => ({ ...d, tastes: val }))}
            />
          </div>

          <div>
            <DurationPicker
              title="Total time"
              options={[15, 30, 60]}
              value={draft.maxTime}
              onChange={(val) => setDraft((d) => ({ ...d, maxTime: val }))}
              caption=""
            />
          </div>
        </div>

        <div className="mt-8 flex gap-3 border-t border-gray-100 pt-4">
          <Button
            variant="outline"
            fullWidth
            onClick={() => setDraft((d) => ({ ...EMPTY_FILTERS, q: d.q }))}
          >
            Clear all
          </Button>
          <Button
            variant="primary"
            fullWidth
            onClick={() => {
              onApply(draft);
              onClose();
            }}
          >
            Apply filters
          </Button>
        </div>
      </div>
    </div>
  );
}
