import {
  Bookmark,
  CalendarPlus,
  Camera,
  ChevronDown,
  Clock,
  DollarSign,
  Info,
  ShoppingCart,
  Users,
} from "lucide-react";
import React, { useState } from "react";
import { AllergenAlert } from "./AllergenAlert";
import { RecipeRatingModule } from "./RecipeRatingModule";
import { Button } from "./ui";

interface RecipeMobileInfoDropdownProps {
  recipe: any;
  prepTime: number;
  cookTime: number;
  isSaved: boolean;
  setIsSaved: React.Dispatch<React.SetStateAction<boolean>>;
  isInMealPlan: boolean;
  setIsInMealPlan: React.Dispatch<React.SetStateAction<boolean>>;
  isShoppingListSaved: boolean;
  setIsShoppingListSaved: React.Dispatch<React.SetStateAction<boolean>>;
  checkedIngredients: Record<number, boolean>;
  toggleIngredient: (index: number) => void;
  className?: string;
}

export function RecipeMobileInfoDropdown({
  recipe,
  prepTime,
  cookTime,
  isSaved,
  setIsSaved,
  isInMealPlan,
  setIsInMealPlan,
  isShoppingListSaved,
  setIsShoppingListSaved,
  checkedIngredients,
  toggleIngredient,
  className = "",
}: RecipeMobileInfoDropdownProps) {
  const [isOpen, setIsOpen] = useState(false);

  const allergens = recipe.dietary_flags
    ? recipe.dietary_flags.filter(
      (f: string) =>
        ![
          "vegan",
          "vegetarian",
          "gluten_free",
          "dairy_free",
          "halal",
          "keto",
          "low_carb",
        ].includes(f),
    )
    : [];

  return (
    <div
      className={`border border-taupe/15 dark:border-stone-850 bg-white dark:bg-[#1d120a] shadow-xs overflow-hidden transition-all duration-300 ${className}`}
    >
      {/* FAQ / Accordion Header Button */}
      <button
        type="button"
        onClick={() => setIsOpen((prev) => !prev)}
        aria-expanded={isOpen}
        className="w-full p-4 sm:p-5 flex items-center justify-between gap-4 text-left cursor-pointer hover:bg-gray-50/70 dark:hover:bg-stone-900/40 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-caramel"
      >
        <div className="flex items-start gap-3.5 min-w-0">
          <div className="p-2 rounded-xl bg-caramel/10 text-caramel dark:bg-caramel/20 dark:text-caramel shrink-0 mt-0.5">
            <Info size={18} />
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h2 className="font-serif text-sm md:text-base sm:text-lg font-semibold text-ink dark:text-white/90">
                Additional Recipe Information
              </h2>
              {/* <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-gray-100 dark:bg-stone-800 text-gray-600 dark:text-gray-300">
                {isOpen ? "Expanded" : "Tap to view"}
              </span> */}
            </div>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 leading-relaxed line-clamp-2 sm:line-clamp-none">
              Includes prep & cook times, servings, allergen alerts, nutrition
              facts, ingredients checklist, ratings, and recipe video.
            </p>
          </div>
        </div>

        <div
          className={`p-1.5 rounded-full bg-gray-100 dark:bg-stone-800 text-gray-600 dark:text-gray-300 transition-transform duration-300 shrink-0 ${isOpen ? "rotate-180 bg-caramel/15 text-caramel" : ""
            }`}
        >
          <ChevronDown size={18} />
        </div>
      </button>

      {/* Accordion Content Panel */}
      {isOpen && (
        <div className="p-4 sm:p-6 pt-2 sm:pt-2 border-t border-taupe/10 dark:border-stone-800/80 space-y-6 animate-fadeIn">
          {/* 1. Metrics & Action Bar */}
          <div className="rounded-xl bg-gray-50/70 dark:bg-[#150c07] border border-taupe/10 dark:border-stone-800/60 p-4 sm:p-5 space-y-4">
            {/* Key Metrics */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-center">
              <div className="bg-white dark:bg-[#1d120a] p-2.5 rounded-xl border border-taupe/10 dark:border-stone-800">
                <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center justify-center gap-1 mb-1">
                  <Clock size={12} /> Prep
                </span>
                <span className="font-bold text-sm text-ink dark:text-white/90">
                  {prepTime} Min
                </span>
              </div>

              <div className="bg-white dark:bg-[#1d120a] p-2.5 rounded-xl border border-taupe/10 dark:border-stone-800">
                <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center justify-center gap-1 mb-1">
                  <Clock size={12} /> Cook
                </span>
                <span className="font-bold text-sm text-ink dark:text-white/90">
                  {cookTime} Min
                </span>
              </div>

              <div className="bg-white dark:bg-[#1d120a] p-2.5 rounded-xl border border-taupe/10 dark:border-stone-800">
                <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center justify-center gap-1 mb-1">
                  <Users size={12} /> Servings
                </span>
                <span className="font-bold text-sm text-ink dark:text-white/90">
                  {recipe.serving_size || 4}
                </span>
              </div>

              <div className="bg-white dark:bg-[#1d120a] p-2.5 rounded-xl border border-taupe/10 dark:border-stone-800">
                <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center justify-center gap-1 mb-1">
                  <DollarSign size={12} /> Cost
                </span>
                <span className="font-bold text-sm text-ink dark:text-white/90">
                  450 Ksh
                </span>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex flex-col sm:flex-row flex-wrap items-stretch sm:items-center gap-2.5 pt-1">
              <Button
                variant="primary"
                size="sm"
                icon={
                  <Bookmark
                    size={15}
                    className={
                      isSaved
                        ? "fill-white text-white"
                        : "fill-transparent text-white"
                    }
                  />
                }
                onClick={() => setIsSaved((prev) => !prev)}
                className="!bg-caramel hover:!bg-caramel/90 justify-center w-full sm:w-auto h-10"
              >
                {isSaved ? "Saved" : "Save Recipe"}
              </Button>
              <Button
                variant="outline"
                size="sm"
                icon={
                  <CalendarPlus
                    size={15}
                    className={isInMealPlan ? "text-caramel" : "text-ink"}
                  />
                }
                onClick={() => setIsInMealPlan((prev) => !prev)}
                className="justify-center w-full sm:w-auto h-10"
              >
                {isInMealPlan ? "Added to Meal Plan" : "Add to Meal Plan"}
              </Button>
              <Button
                variant="outline"
                size="sm"
                icon={
                  <ShoppingCart
                    size={15}
                    className={
                      isShoppingListSaved ? "text-caramel" : "text-ink"
                    }
                  />
                }
                onClick={() => setIsShoppingListSaved((prev) => !prev)}
                className="justify-center w-full sm:w-auto h-10"
              >
                {isShoppingListSaved
                  ? "Shopping List Saved"
                  : "Add to shopping list"}
              </Button>
            </div>
          </div>

          {/* 2. Allergen Advisory Alert */}
          {allergens.length > 0 && (
            <div>
              <AllergenAlert allergens={allergens} />
            </div>
          )}

          {/* 3. Customer Reviews / Rating Module */}
          <RecipeRatingModule
            recipeId={recipe.id}
            avgRating={recipe.avg_rating || 4.7}
            ratingCount={recipe.rating_count || 40}
          />

          {/* 4. Profile Card (Dietary Flags & Taste Tags) */}
          {(recipe.dietary_flags?.length > 0 ||
            recipe.taste_tags?.length > 0) && (
              <div className="rounded-xl bg-gray-50/70 dark:bg-[#150c07] border border-taupe/10 dark:border-stone-800/60 p-4 sm:p-5 space-y-3">
                <h3 className="font-serif text-base font-semibold text-ink dark:text-white/90">
                  Dietary & Taste Profile
                </h3>

                {recipe.dietary_flags && recipe.dietary_flags.length > 0 && (
                  <div>
                    <span className="block text-[10px] font-bold uppercase tracking-widest text-gray-400 mb-1.5">
                      Dietary Flags
                    </span>
                    <div className="flex flex-wrap gap-1.5">
                      {recipe.dietary_flags.map((flag: string) => (
                        <span
                          key={flag}
                          className="rounded-full bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 text-xs font-semibold px-3 py-1 inline-block capitalize"
                        >
                          {flag.replace("_", " ")}
                        </span>
                      ))}
                    </div>
                  </div>
                )}

                {recipe.taste_tags && recipe.taste_tags.length > 0 && (
                  <div>
                    <span className="block text-[10px] font-bold uppercase tracking-widest text-gray-400 mb-1.5">
                      Taste Tags
                    </span>
                    <div className="flex flex-wrap gap-1.5">
                      {recipe.taste_tags.map((tag: string) => (
                        <span
                          key={tag}
                          className="rounded-full bg-white dark:bg-stone-800 text-gray-700 dark:text-gray-300 text-xs font-medium px-3 py-1 border border-taupe/10 dark:border-stone-700 capitalize"
                        >
                          {tag}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}

          {/* 5. Nutrition Card */}
          <div className="rounded-xl bg-gray-50/70 dark:bg-[#150c07] border border-taupe/10 dark:border-stone-800/60 p-4 sm:p-5 space-y-3 font-sans">
            <div className="flex justify-between items-baseline">
              <h3 className="font-serif text-base font-semibold text-ink dark:text-white/90">
                Nutrition
              </h3>
              <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400">
                PER SERVING
              </span>
            </div>

            <div className="flex items-baseline gap-1 py-0.5">
              <span className="text-4xl font-extrabold tracking-tight text-caramel">
                {recipe.calories || 320}
              </span>
              <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">
                kcal
              </span>
            </div>

            <div className="grid grid-cols-4 gap-2">
              <div className="bg-white dark:bg-[#1d120a] p-2 rounded-xl border border-taupe/10 dark:border-stone-800 flex flex-col justify-between min-h-[50px]">
                <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400">
                  Protein
                </span>
                <span className="font-bold text-xs text-ink dark:text-white/90 mt-1">
                  {recipe.macros?.protein_g !== undefined
                    ? `${recipe.macros.protein_g}g`
                    : "18g"}
                </span>
              </div>
              <div className="bg-white dark:bg-[#1d120a] p-2 rounded-xl border border-taupe/10 dark:border-stone-800 flex flex-col justify-between min-h-[50px]">
                <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400">
                  Fat
                </span>
                <span className="font-bold text-xs text-ink dark:text-white/90 mt-1">
                  {recipe.macros?.fat_g !== undefined
                    ? `${recipe.macros.fat_g}g`
                    : "12g"}
                </span>
              </div>
              <div className="bg-white dark:bg-[#1d120a] p-2 rounded-xl border border-taupe/10 dark:border-stone-800 flex flex-col justify-between min-h-[50px]">
                <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400">
                  Carbs
                </span>
                <span className="font-bold text-xs text-ink dark:text-white/90 mt-1">
                  {recipe.macros?.carbs_g !== undefined
                    ? `${recipe.macros.carbs_g}g`
                    : "40g"}
                </span>
              </div>
              <div className="bg-white dark:bg-[#1d120a] p-2 rounded-xl border border-taupe/10 dark:border-stone-800 flex flex-col justify-between min-h-[50px]">
                <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400">
                  Fibre
                </span>
                <span className="font-bold text-xs text-ink dark:text-white/90 mt-1">
                  {recipe.macros?.fibre_g !== undefined
                    ? `${recipe.macros.fibre_g}g`
                    : "3g"}
                </span>
              </div>
            </div>
          </div>

          {/* 6. Ingredients Checklist Card */}
          <div className="rounded-xl bg-gray-50/70 dark:bg-[#150c07] border border-taupe/10 dark:border-stone-800/60 p-4 sm:p-5 space-y-3">
            <h3 className="font-serif text-base font-semibold text-ink dark:text-white/90">
              Ingredients Checklist
            </h3>

            <ul className="space-y-2.5 font-sans text-xs sm:text-sm">
              {recipe.ingredients?.map((item: any, idx: number) => {
                const isChecked = checkedIngredients[idx] || false;
                const label =
                  `${item.quantity || ""} ${item.unit || ""} ${item.name}`.trim();
                return (
                  <li
                    key={idx}
                    className="flex items-start gap-3 cursor-pointer select-none"
                  >
                    <input
                      type="checkbox"
                      checked={isChecked}
                      onChange={() => toggleIngredient(idx)}
                      className="mt-0.5 h-4 w-4 rounded border-gray-300 dark:border-stone-800 accent-caramel cursor-pointer"
                      id={`mobile-ingredient-${idx}`}
                    />
                    <label
                      htmlFor={`mobile-ingredient-${idx}`}
                      className={`cursor-pointer transition-colors ${isChecked
                        ? "line-through text-gray-400"
                        : "text-gray-700 dark:text-gray-300 font-medium"
                        }`}
                    >
                      {label}
                    </label>
                  </li>
                );
              })}
            </ul>
          </div>

          {/* 7. Follow Creator */}
          <div className="rounded-xl bg-gray-50/70 dark:bg-[#150c07] border border-taupe/10 dark:border-stone-800/60 p-4 sm:p-5 space-y-3 font-sans">
            <h3 className="font-serif text-base font-semibold text-ink dark:text-white/90">
              Follow Creator
            </h3>

            <div className="flex flex-wrap items-center gap-3">
              <a
                href="https://x.com/leotunakula"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2.5 px-3 py-2 rounded-xl bg-white dark:bg-[#1d120a] border border-taupe/10 dark:border-stone-800 hover:border-caramel/40 transition-colors"
              >
                <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-black text-white font-bold text-xs">
                  X
                </div>
                <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                  @leotunakula
                </span>
              </a>

              <a
                href="https://instagram.com/leotunakula.app"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2.5 px-3 py-2 rounded-xl bg-white dark:bg-[#1d120a] border border-taupe/10 dark:border-stone-800 hover:border-caramel/40 transition-colors"
              >
                <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-[#78350f] text-[#fdba74]">
                  <Camera size={13} className="text-[#fdba74]" />
                </div>
                <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                  @leotunakula.app
                </span>
              </a>
            </div>
          </div>

          {/* 8. Recipe Video */}
          {recipe.video_url && (
            <div className="rounded-xl bg-gray-50/70 dark:bg-[#150c07] border border-taupe/10 dark:border-stone-800/60 overflow-hidden space-y-2">
              <h3 className="font-serif text-base font-semibold text-ink dark:text-white/90 p-4 pb-0">
                Recipe Video
              </h3>

              <div className="relative aspect-video w-full overflow-hidden">
                <iframe
                  width="100%"
                  height="100%"
                  src={recipe.video_url.replace("watch?v=", "embed/")}
                  title={recipe.title}
                  frameBorder="0"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                  referrerPolicy="strict-origin-when-cross-origin"
                  allowFullScreen
                  className="absolute inset-0 h-full w-full"
                />
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
