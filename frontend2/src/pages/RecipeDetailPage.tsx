import {
  Bookmark,
  CalendarPlus,
  Camera,
  Clock,
  DollarSign,
  Lightbulb,
  ShoppingCart,
  Users,
} from "lucide-react";
import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";

import { Button } from "../components/ui";
import { PLACEHOLDER_RECIPES } from "../features/browse/placeholderRecipes";
import { RecipeCard } from "../components/RecipeCard";
import { StepImageCarousel } from "../components/StepImageCarousel";
import { AllergenAlert } from "../components/AllergenAlert";
import { RecipeComments } from "../components/RecipeComments";
import { RecipeRatingModule } from "../components/RecipeRatingModule";
import { apiGet } from "../lib/api";

export function RecipeDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [recipe, setRecipe] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const [isSaved, setIsSaved] = useState(false);
  const [isInMealPlan, setIsInMealPlan] = useState(false);
  const [isShoppingListSaved, setIsShoppingListSaved] = useState(false);

  // Default checked state for ingredients
  const [checkedIngredients, setCheckedIngredients] = useState<
    Record<number, boolean>
  >({});

  const toggleIngredient = (index: number) => {
    setCheckedIngredients((prev) => ({
      ...prev,
      [index]: !prev[index],
    }));
  };

  useEffect(() => {
    if (!id) return;
    setLoading(true);
    setCheckedIngredients({});

    apiGet<{ data: any }>(`/recipes/${id}`, undefined, { auth: false })
      .then(({ data }) => {
        setRecipe(data);
        setLoading(false);
      })
      .catch(() => {
        // Fallback to placeholder recipe
        const placeholder = PLACEHOLDER_RECIPES.find((r) => r.id === id);
        if (placeholder) {
          // Enrich placeholder with dummy ingredients and steps if not already provided
          const enriched: any = {
            prep_time_mins: 15,
            cook_time_mins: placeholder.total_time_mins - 15,
            serving_size: 4,
            macros: {
              protein_g: 22,
              carbs_g: 45,
              fat_g: 12,
              fibre_g: 4,
            },
            ...placeholder,
          };

          if (placeholder.ingredients && placeholder.steps) {
            // Already fully defined in the placeholder data store
          } else if (placeholder.slug === "swahili-mahamri") {
            enriched.ingredients = [
              { name: "all-purpose flour", quantity: 3, unit: "cups" },
              { name: "instant yeast", quantity: 1, unit: "tsp" },
              { name: "ground cardamom", quantity: 1, unit: "tsp" },
              { name: "sugar", quantity: 0.5, unit: "cup" },
              { name: "heavy coconut milk", quantity: 1, unit: "cup" },
              {
                name: "vegetable oil (for deep frying)",
                quantity: 500,
                unit: "ml",
              },
            ];
            enriched.steps = [
              {
                order: 1,
                instruction:
                  "In a bowl, mix flour, yeast, sugar, and ground cardamom.",
              },
              {
                order: 2,
                instruction:
                  "Gradually add coconut milk, kneading until you have a smooth, non-sticky dough.",
              },
              {
                order: 3,
                instruction:
                  "Divide dough into 4 balls. Roll each ball into a circle and cut into quarters.",
              },
              {
                order: 4,
                instruction:
                  "Heat oil on medium-high. Deep fry the triangles until golden brown and puffed.",
              },
            ];
          } else if (placeholder.slug === "kenyan-githeri") {
            enriched.ingredients = [
              { name: "boiled maize (corn)", quantity: 2, unit: "cups" },
              { name: "boiled red beans", quantity: 2, unit: "cups" },
              { name: "onion, chopped", quantity: 1, unit: "large" },
              { name: "tomatoes, chopped", quantity: 2, unit: "medium" },
              { name: "garlic cloves, minced", quantity: 2, unit: "whole" },
              { name: "vegetable oil", quantity: 2, unit: "tbsp" },
              { name: "curry powder & salt", quantity: 1, unit: "tsp" },
            ];
            enriched.steps = [
              {
                order: 1,
                instruction:
                  "Heat oil in a pot and sauté the chopped onion and minced garlic until soft.",
              },
              {
                order: 2,
                instruction:
                  "Add the tomatoes and curry powder. Cook until the tomatoes form a thick paste.",
              },
              {
                order: 3,
                instruction:
                  "Toss in the pre-boiled maize and beans, mixing thoroughly.",
              },
              {
                order: 4,
                instruction:
                  "Pour in 1 cup of water, cover, and let it simmer for 15 minutes to blend the flavors.",
              },
            ];
          } else if (placeholder.slug === "millet-uji-groundnuts") {
            enriched.ingredients = [
              { name: "millet flour", quantity: 0.5, unit: "cup" },
              { name: "water", quantity: 3, unit: "cups" },
              { name: "lemon juice or sour milk", quantity: 2, unit: "tbsp" },
              { name: "sugar to taste", quantity: 3, unit: "tbsp" },
              { name: "roasted groundnuts", quantity: 0.5, unit: "cup" },
            ];
            enriched.steps = [
              {
                order: 1,
                instruction:
                  "Mix millet flour with 1 cup of cold water until smooth.",
              },
              {
                order: 2,
                instruction:
                  "Bring the remaining 2 cups of water to a boil in a pot.",
              },
              {
                order: 3,
                instruction:
                  "Pour the flour paste into the boiling water while stirring continuously to avoid lumps.",
              },
              {
                order: 4,
                instruction:
                  "Simmer on low heat for 10 minutes. Add lemon juice and sugar, then serve warm with groundnuts.",
              },
            ];
          } else if (placeholder.slug === "fried-tilapia-ugali") {
            enriched.ingredients = [
              {
                name: "whole tilapia fish, cleaned and scaled",
                quantity: 1,
                unit: "whole",
              },
              { name: "maize flour (for ugali)", quantity: 2, unit: "cups" },
              {
                name: "sukuma wiki (kale), chopped",
                quantity: 1,
                unit: "bunch",
              },
              { name: "onion, finely chopped", quantity: 1, unit: "medium" },
              { name: "tomato, chopped", quantity: 1, unit: "large" },
              { name: "vegetable oil", quantity: 250, unit: "ml" },
            ];
            enriched.steps = [
              {
                order: 1,
                instruction:
                  "Make shallow cuts on the fish. Season with salt and deep fry until crispy and golden.",
              },
              {
                order: 2,
                instruction:
                  "In a pot, bring 3 cups of water to a boil, slowly add maize flour, and stir to form a firm Ugali.",
              },
              {
                order: 3,
                instruction:
                  "Sauté the chopped onion in a pan, add tomatoes, and then cook the sukuma wiki for 5 minutes.",
              },
              {
                order: 4,
                instruction:
                  "Serve the hot fried tilapia alongside the Ugali and sukuma wiki.",
              },
            ];
          } else if (placeholder.slug === "mursik-with-ugali") {
            enriched.ingredients = [
              {
                name: "sour milk (fermented in gourd)",
                quantity: 500,
                unit: "ml",
              },
              {
                name: "millet or maize flour (for ugali)",
                quantity: 2,
                unit: "cups",
              },
              { name: "water", quantity: 3, unit: "cups" },
              {
                name: "charcoal ash (from Senetwet tree)",
                quantity: 0.5,
                unit: "tsp",
              },
            ];
            enriched.steps = [
              {
                order: 1,
                instruction:
                  "Prepare the gourd by smoking it with embers of the Senetwet tree.",
              },
              {
                order: 2,
                instruction:
                  "Pour milk into the gourd and let it ferment for 3 to 5 days.",
              },
              {
                order: 3,
                instruction:
                  "Prepare hot firm Ugali using millet or maize flour.",
              },
              {
                order: 4,
                instruction:
                  "Serve the hot Ugali alongside the cold, rich, traditional Mursik.",
              },
            ];
          } else {
            // Default placeholder ingredients and steps
            enriched.ingredients = [
              {
                name: "Main ingredient for " + placeholder.title,
                quantity: 500,
                unit: "g",
              },
              { name: "Secondary ingredient", quantity: 2, unit: "tbsp" },
              { name: "Salt and seasoning", quantity: 1, unit: "tsp" },
            ];
            enriched.steps = [
              {
                order: 1,
                instruction: `Prepare the ingredients for ${placeholder.title}.`,
              },
              {
                order: 2,
                instruction:
                  "Combine ingredients in a pan and cook on medium heat.",
              },
              { order: 3, instruction: "Season to taste and serve warm!" },
            ];
          }
          setRecipe(enriched);
        } else {
          setRecipe(null);
        }
        setLoading(false);
      });
  }, [id]);

  // Related recipes using existing RecipeCard component
  const relatedRecipes = PLACEHOLDER_RECIPES.filter((r) => r.id !== id).slice(
    0,
    4,
  );

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50/50 dark:bg-[#120905] transition-colors duration-300">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-caramel border-t-transparent" />
      </div>
    );
  }

  if (!recipe) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-gray-50/50 dark:bg-[#120905] text-ink dark:text-parchment font-sans p-6 transition-colors duration-300">
        <h2 className="text-xl font-bold text-ink dark:text-parchment">
          Recipe not found
        </h2>
        <p className="text-gray-500 dark:text-gray-400 mt-2 text-center">
          The recipe you are looking for does not exist or has been removed.
        </p>
        <Link
          to="/"
          className="mt-6 rounded-full bg-caramel hover:bg-caramel/90 px-6 py-2.5 text-white font-semibold shadow-md transition-colors"
        >
          Back to Browse
        </Link>
      </div>
    );
  }

  const prepTime = recipe.prep_time_mins || 15;
  const cookTime =
    recipe.cook_time_mins ||
    (recipe.total_time_mins ? recipe.total_time_mins - prepTime : 20);
  // const totalTime = recipe.total_time_mins || (prepTime + cookTime);

  return (
    <div className="bg-gray-50/50 dark:bg-[#120905] pb-20 px-8 lg:px-52 text-ink dark:text-parchment transition-colors duration-300">
      <main className="mx-auto px-4 sm:px-6 lg:px-24 pt-6">
        {/* Hero Image Banner */}
        <div className="relative aspect-[21/9] min-h-[360px] sm:min-h-[440px] w-full overflow-hidden rounded-3xl shadow-xl">
          <img
            src={recipe.thumbnail_url || "/tuscan-pasta-hero.jpg"}
            alt={recipe.title}
            className="h-full w-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/40 to-transparent" />

          <div className="absolute bottom-6 left-6 right-6 sm:bottom-10 sm:left-10 sm:right-10 text-white font-sans">
            <div className="flex items-center gap-2 mb-3">
              <span className="rounded-full bg-caramel px-3.5 py-1 text-[11px] font-bold uppercase tracking-wider text-white">
                {recipe.course || "Main"}
              </span>
              <span className="rounded-full bg-white/20 backdrop-blur-md px-3.5 py-1 text-[11px] font-semibold uppercase tracking-wider text-white border border-white/30 capitalize">
                {recipe.difficulty}
              </span>
            </div>

            <h1 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium tracking-tight text-white mb-2">
              {recipe.title}
            </h1>
            <p className="max-w-2xl text-xs sm:text-sm lg:text-base font-light text-white/90 leading-relaxed">
              {recipe.description ||
                "A delicious, carefully curated recipe designed to delight your senses and satisfy your culinary cravings."}
            </p>
          </div>
        </div>

        {/* Metrics & Action Bar */}
        <div className="mt-6 rounded-xl bg-white dark:bg-[#1d120a] border border-taupe/15 dark:border-stone-850 p-10 shadow-xs flex flex-wrap items-center justify-between gap-6 font-sans transition-colors duration-300">
          {/* Key Metrics */}
          <div className="flex items-center gap-6 sm:gap-8 flex-wrap">
            <div className="flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center gap-1 mb-1">
                <Clock size={13} /> Prep Time
              </span>
              <span className="font-bold text-sm text-ink dark:text-white/70">
                {prepTime} Min
              </span>
            </div>

            <div className="h-8 w-px bg-gray-200 dark:bg-stone-700 hidden sm:block" />

            <div className="flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center gap-1 mb-1">
                <Clock size={13} /> Cook Time
              </span>
              <span className="font-bold text-sm text-ink dark:text-white/70">
                {cookTime} Min
              </span>
            </div>

            <div className="h-8 w-px bg-gray-200 dark:bg-stone-700 hidden sm:block" />

            <div className="flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center gap-1 mb-1">
                <Users size={13} /> Servings
              </span>
              <span className="font-bold text-sm text-ink dark:text-white/70">
                {recipe.serving_size || 4} Servings
              </span>
            </div>

            <div className="h-8 w-px bg-gray-200 dark:bg-stone-700 hidden sm:block" />

            <div className="flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center gap-1 mb-1">
                <DollarSign size={13} /> Cost
              </span>
              <span className="font-bold text-sm text-ink dark:text-white/70">
                450 Ksh
              </span>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-wrap items-center gap-3">
            <Button
              variant="primary"
              size="md"
              icon={
                <Bookmark
                  size={16}
                  className={
                    isSaved
                      ? "fill-white text-white"
                      : "fill-transparent text-white"
                  }
                />
              }
              onClick={() => setIsSaved((prev) => !prev)}
              className="!bg-caramel hover:!bg-caramel/90"
            >
              {isSaved ? "Saved" : "Save Recipe"}
            </Button>
            <Button
              variant="outline"
              size="md"
              icon={
                <CalendarPlus
                  size={16}
                  className={isInMealPlan ? "text-caramel" : "text-ink"}
                />
              }
              onClick={() => setIsInMealPlan((prev) => !prev)}
            >
              {isInMealPlan ? "Added to Meal Plan" : "Add to Meal Plan"}
            </Button>
            <Button
              variant="outline"
              size="md"
              icon={
                <ShoppingCart
                  size={16}
                  className={isShoppingListSaved ? "text-caramel" : "text-ink"}
                />
              }
              onClick={() => setIsShoppingListSaved((prev) => !prev)}
            >
              {isShoppingListSaved
                ? "Shopping List Saved"
                : "Add to shopping list"}
            </Button>
          </div>
        </div>

        {/* Allergen Advisory Alert */}
        <div className="mt-6">
          <AllergenAlert
            allergens={
              recipe.dietary_flags
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
                : []
            }
          />
        </div>

        {/* Main Content 2-Column Layout */}
        <div className="mt-8 grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-10">
          {/* Left Sidebar Column (4 cols) */}
          <div className="lg:col-span-4 space-y-4">
            {/* Customer Reviews / Rating Module */}
            <RecipeRatingModule
              recipeId={recipe.id}
              avgRating={recipe.avg_rating || 4.7}
              ratingCount={recipe.rating_count || 40}
            />

            {/* Profile Card */}
            <div className="rounded-xl bg-white dark:bg-[#1d120a] border border-taupe/15 dark:border-stone-850 p-6 shadow-xs space-y-4 transition-colors duration-300">
              <h2 className="font-serif text-lg font-semibold text-ink dark:text-white/70 dark:border-stone-850 pb-1">
                Profile
              </h2>

              {recipe.dietary_flags && recipe.dietary_flags.length > 0 && (
                <div>
                  <span className="block text-[11px] font-bold uppercase tracking-widest text-gray-400 mb-2">
                    Dietary Flags
                  </span>
                  <div className="flex flex-wrap gap-2">
                    {recipe.dietary_flags.map((flag: string) => (
                      <span
                        key={flag}
                        className="rounded-full bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 text-xs font-semibold px-3.5 py-1.5 inline-block capitalize"
                      >
                        {flag.replace("_", " ")}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {recipe.taste_tags && recipe.taste_tags.length > 0 && (
                <div>
                  <span className="block text-[11px] font-bold uppercase tracking-widest text-gray-400 mb-2">
                    Taste Tags
                  </span>
                  <div className="flex flex-wrap gap-2">
                    {recipe.taste_tags.map((tag: string) => (
                      <span
                        key={tag}
                        className="rounded-full bg-gray-100 dark:bg-stone-900 text-gray-700 dark:text-gray-300 text-xs font-medium px-3.5 py-1.5 capitalize"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Nutrition Card */}
            <div className="rounded-xl bg-white dark:bg-[#1d120a] border border-taupe/15 dark:border-stone-850 p-6 shadow-xs space-y-4 font-sans transition-colors duration-300">
              <div className="flex justify-between items-baseline pb-3">
                <h2 className="font-serif text-lg font-semibold text-ink dark:text-white/70">
                  Nutrition
                </h2>
                <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400">
                  PER SERVING
                </span>
              </div>

              <div className="flex items-baseline gap-1 py-1">
                <span className="text-5xl font-extrabold tracking-tight text-caramel">
                  {recipe.calories || 320}
                </span>
                <span className="text-sm font-semibold text-gray-500 dark:text-gray-400">
                  kcal
                </span>
              </div>

              <div className="grid grid-cols-4 gap-2">
                <div className="bg-gray-50 dark:bg-[#120905] p-2 rounded-xl flex flex-col justify-between min-h-[56px] transition-colors duration-300">
                  <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400">
                    Protein
                  </span>
                  <span className="font-bold text-xs sm:text-sm text-ink dark:text-white/70 mt-1">
                    {recipe.macros?.protein_g !== undefined
                      ? `${recipe.macros.protein_g}g`
                      : "18g"}
                  </span>
                </div>
                <div className="bg-gray-50 dark:bg-[#120905] p-2 rounded-xl flex flex-col justify-between min-h-[56px] transition-colors duration-300">
                  <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400">
                    Fat
                  </span>
                  <span className="font-bold text-xs sm:text-sm text-ink dark:text-white/70 mt-1">
                    {recipe.macros?.fat_g !== undefined
                      ? `${recipe.macros.fat_g}g`
                      : "12g"}
                  </span>
                </div>
                <div className="bg-gray-50 dark:bg-[#120905] p-2 rounded-xl flex flex-col justify-between min-h-[56px] transition-colors duration-300">
                  <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400">
                    Carbs
                  </span>
                  <span className="font-bold text-xs sm:text-sm text-ink dark:text-white/70 mt-1">
                    {recipe.macros?.carbs_g !== undefined
                      ? `${recipe.macros.carbs_g}g`
                      : "40g"}
                  </span>
                </div>
                <div className="bg-gray-50 dark:bg-[#120905] p-2 rounded-xl flex flex-col justify-between min-h-[56px] transition-colors duration-300">
                  <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400">
                    Fibre
                  </span>
                  <span className="font-bold text-xs sm:text-sm text-ink dark:text-white/70 mt-1">
                    {recipe.macros?.fibre_g !== undefined
                      ? `${recipe.macros.fibre_g}g`
                      : "3g"}
                  </span>
                </div>
              </div>
            </div>

            {/* Ingredients Card */}
            <div className="rounded-xl bg-white dark:bg-[#1d120a] border border-taupe/15 dark:border-stone-850 p-6 shadow-xs space-y-4 transition-colors duration-300">
              <h2 className="font-serif text-lg font-semibold text-ink dark:text-white/70 pb-1">
                Ingredients
              </h2>

              <ul className="space-y-3 font-sans text-xs sm:text-sm">
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
                        id={`ingredient-${idx}`}
                      />
                      <label
                        htmlFor={`ingredient-${idx}`}
                        className={`cursor-pointer transition-colors ${
                          isChecked
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

            {/* Follow creator Card */}
            <div className="rounded-xl bg-white dark:bg-[#1d120a] border border-taupe/15 dark:border-stone-850 p-6 shadow-xs space-y-4 font-sans transition-colors duration-300">
              <div>
                <h2 className="font-serif text-lg font-bold text-ink dark:text-white/70">
                  Follow creator
                </h2>
                {/* <p className="text-xs text-gray-600 mt-1 leading-relaxed">
                  Fresh ideas, kitchen moments, and what Mpishi is cooking 👨‍🍳
                </p> */}
              </div>

              <div className="space-y-3 pt-2">
                <a
                  href="https://x.com/leotunakula"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-4 group cursor-pointer"
                >
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-black text-white font-bold text-base transition-transform group-hover:scale-105">
                    X
                  </div>
                  <span className="text-sm font-semibold text-gray-700 dark:text-gray-300 group-hover:text-ink dark:group-hover:text-white/70 transition-colors">
                    @leotunakula
                  </span>
                </a>

                <a
                  href="https://instagram.com/leotunakula.app"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-4 group cursor-pointer"
                >
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[#78350f] text-[#fdba74] transition-transform group-hover:scale-105">
                    <Camera size={18} className="text-[#fdba74]" />
                  </div>
                  <span className="text-sm font-semibold text-gray-700 dark:text-gray-300 group-hover:text-ink dark:group-hover:text-white/70 transition-colors">
                    @leotunakula.app
                  </span>
                </a>
              </div>
            </div>

            {/* Recipe Video Card */}
            {recipe.video_url && (
              <div className="rounded-xl bg-white dark:bg-[#1d120a] border border-taupe/15 dark:border-stone-850 shadow-xs space-y-4 transition-colors duration-300">
                <h2 className="font-serif text-lg p-6 font-semibold text-ink dark:text-white/70 pb-1">
                  Recipe Video
                </h2>

                <div className="relative aspect-video rounded-b-xl overflow-hidden shadow-sm">
                  <iframe
                    width="1905"
                    height="756"
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

          {/* Right Main Column: Cooking Steps (8 cols) */}
          <div className="lg:col-span-8">
            <div className="">
              <div className="relative pl-12 space-y-12">
                {/* Continuous Vertical Timeline Line */}
                <div className="absolute left-5 top-4 bottom-8 w-0.5 bg-caramel/30" />

                {recipe.steps?.map((step: any, idx: number) => {
                  const stepNum = step.order || idx + 1;
                  return (
                    <div key={idx} className="relative">
                      {/* Step Number Circle */}
                      <div className="absolute -left-12 top-0 w-10 h-10 rounded-full border-2 border-caramel bg-white dark:bg-[#120905] text-caramel font-bold text-sm flex items-center justify-center shadow-xs z-10 font-sans transition-colors duration-300">
                        {stepNum}
                      </div>

                      <div>
                        <h3 className="font-sans font-bold text-base text-ink dark:text-white/70 mb-1">
                          Step {stepNum}
                        </h3>
                        <p className="font-sans text-xs sm:text-sm text-gray-600 dark:text-gray-300 leading-relaxed w-full">
                          {step.instruction}
                        </p>

                        {step.tips && step.tips.length > 0 && (
                          <div className="mt-3 w-full rounded-lg border border-caramel/20 dark:border-caramel/10 bg-caramel/5 dark:bg-caramel/10 px-4 py-3">
                            <p className="mb-2 flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-caramel">
                              <Lightbulb size={13} />
                              {step.tips.length === 1 ? "Tip" : "Tips"}
                            </p>
                            {step.tips.length === 1 ? (
                              <p className="font-sans text-xs sm:text-sm leading-relaxed text-gray-700 dark:text-gray-300">
                                {step.tips[0]}
                              </p>
                            ) : (
                              <ul className="list-disc space-y-1.5 pl-4 font-sans text-xs sm:text-sm leading-relaxed text-gray-700 dark:text-gray-300">
                                {step.tips.map(
                                  (tip: string, tipIndex: number) => (
                                    <li key={tipIndex}>{tip}</li>
                                  ),
                                )}
                              </ul>
                            )}
                          </div>
                        )}

                        {step.images && step.images.length > 0 && (
                          <StepImageCarousel
                            images={step.images}
                            stepTitle={`Step ${stepNum}`}
                          />
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Comments Section right below recipe steps */}
            <RecipeComments />
          </div>
        </div>

        {/* You Might Also Like Section */}
        <section className="mt-16 border-t border-gray-200/20 pt-8">
          <h2 className="font-serif text-lg sm:text-xl text-ink font-semibold mb-8">
            More recipes from {recipe.author?.full_name || "Caramel Kitchen"}
          </h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-8">
            {relatedRecipes.map((r) => (
              <RecipeCard key={r.id} recipe={r} />
            ))}
          </div>
        </section>
      </main>
    </div>
  );
}
