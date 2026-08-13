import {
  Bookmark,
  Clock,
  Flame,
  PieChart,
  Play,
  Scale,
  Star,
  Wheat,
} from "lucide-react";
import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { Button } from "../components/ui";
import { PLACEHOLDER_RECIPES } from "../features/browse/placeholderRecipes";
import { RecipeCard } from "../features/browse/RecipeCard";

export function RecipeDetailPage() {
  const { id } = useParams();
  const [isSaved, setIsSaved] = useState(false);

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

  // Related recipes using existing RecipeCard component
  const relatedRecipes = PLACEHOLDER_RECIPES.slice(0, 3);

  const ingredientsList = [
    "12 oz penne or rigatoni pasta",
    "1 cup sun-dried tomatoes, drained and chopped",
    "3 cloves garlic, minced",
    "1 cup heavy cream",
    "1/2 cup grated parmesan cheese",
    "2 cups fresh baby spinach",
  ];

  const cookingSteps = [
    {
      step: 1,
      title: "Boil the Pasta",
      description:
        "Bring a large pot of salted water to a boil. Add the pasta and cook according to package instructions until al dente. Reserve 1/2 cup of pasta water before draining.",
      image: "/step-1.jpg",
    },
    {
      step: 2,
      title: "Sauté Aromatics",
      description:
        "In a large skillet over medium heat, add a tablespoon of the oil from the sun-dried tomatoes. Add minced garlic and sauté for 1 minute until fragrant. Add the chopped sun-dried tomatoes and cook for another 2 minutes.",
      image: "/step-2.jpg",
    },
    {
      step: 3,
      title: "Create the Sauce",
      description:
        "Lower the heat to medium-low. Pour in the heavy cream and reserved pasta water. Stir continuously for 2-3 minutes as it begins to gently simmer and thicken slightly.",
      image: "/step-3.jpg",
    },
    {
      step: 4,
      title: "Combine and Serve",
      description:
        "Stir in the parmesan cheese until melted. Add the fresh spinach and cook until just wilted. Toss in the cooked pasta, ensuring every noodle is coated in the creamy sauce. Serve immediately with extra parmesan.",
      image: "/tuscan-pasta-hero.jpg",
    },
  ];

  return (
    <div className=" bg-gray-50/50 pb-20 px-8 lg:px-24">
      <main className="mx-auto px-4 sm:px-6 lg:px-24 pt-6">
        {/* Hero Image Banner */}
        <div className="relative aspect-[21/9] min-h-[360px] sm:min-h-[440px] w-full overflow-hidden rounded-3xl shadow-xl">
          <img
            src="/tuscan-pasta-hero.jpg"
            alt="Tuscan Sun Pasta"
            className="h-full w-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/40 to-transparent" />

          <div className="absolute bottom-6 left-6 right-6 sm:bottom-10 sm:left-10 sm:right-10 text-white font-sans">
            <div className="flex items-center gap-2 mb-3">
              <span className="rounded-full bg-caramel px-3.5 py-1 text-[11px] font-bold uppercase tracking-wider text-white">
                DINNER
              </span>
              <span className="rounded-full bg-white/20 backdrop-blur-md px-3.5 py-1 text-[11px] font-semibold uppercase tracking-wider text-white border border-white/30">
                Beginner
              </span>
            </div>

            <h1 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-medium tracking-tight text-white mb-2">
              Tuscan Sun Pasta
            </h1>
            <p className="max-w-2xl text-xs sm:text-sm lg:text-base font-light text-white/90 leading-relaxed">
              A creamy, vibrant dish featuring sun-dried tomatoes, fresh
              spinach, and tender pasta. Perfect for a cozy weeknight dinner
              that feels like a summer escape.
            </p>
          </div>
        </div>

        {/* Metrics & Action Bar */}
        <div className="mt-6 rounded-xl bg-white p-10 shadow-xs flex flex-wrap items-center justify-between gap-6 font-sans">
          {/* Key Metrics */}
          <div className="flex items-center gap-6 sm:gap-8 flex-wrap">
            <div className="flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center gap-1 mb-1">
                <Clock size={13} /> Prep Time
              </span>
              <span className="font-bold text-sm text-ink">25 Min</span>
            </div>

            <div className="h-8 w-px bg-gray-200 hidden sm:block" />

            <div className="flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center gap-1 mb-1">
                <Flame size={13} /> Calories
              </span>
              <span className="font-bold text-sm text-ink">450 kcal</span>
            </div>

            <div className="h-8 w-px bg-gray-200 hidden sm:block" />

            <div className="flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center gap-1 mb-1">
                <Scale size={13} /> Protein
              </span>
              <span className="font-bold text-sm text-ink">12g</span>
            </div>

            <div className="h-8 w-px bg-gray-200 hidden sm:block" />

            <div className="flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center gap-1 mb-1">
                <PieChart size={13} /> Fat
              </span>
              <span className="font-bold text-sm text-ink">28g</span>
            </div>

            <div className="h-8 w-px bg-gray-200 hidden sm:block" />

            <div className="flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-gray-400 flex items-center gap-1 mb-1">
                <Wheat size={13} /> Carbs
              </span>
              <span className="font-bold text-sm text-ink">45g</span>
            </div>
          </div>

          {/* Action Button */}
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
        </div>

        {/* Main Content 2-Column Layout */}
        <div className="mt-10 grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-10">
          {/* Left Sidebar Column (4 cols) */}
          <div className="lg:col-span-4 space-y-4">
            {/* Profile Card */}
            <div className="rounded-xl bg-white p-6 shadow-xs space-y-4">
              <h2 className="font-serif text-lg font-semibold text-ink border-b border-gray-100 pb-1">
                Profile
              </h2>

              <div>
                <span className="block text-[11px] font-bold uppercase tracking-widest text-gray-400 mb-2">
                  Rating
                </span>
                <span className="rounded-full bg-amber-500/10 text-amber-700 text-xs font-semibold px-3.5 py-1.5 inline-block">
                  4.8
                </span>
              </div>

              <div>
                <span className="block text-[11px] font-bold uppercase tracking-widest text-gray-400 mb-2">
                  Dietary Flags
                </span>
                <span className="rounded-full bg-emerald-500/10 text-emerald-700 text-xs font-semibold px-3.5 py-1.5 inline-block">
                  Vegetarian
                </span>
              </div>

              <div>
                <span className="block text-[11px] font-bold uppercase tracking-widest text-gray-400 mb-2">
                  Taste Tags
                </span>
                <div className="flex flex-wrap gap-2">
                  <span className="rounded-full bg-gray-100 text-gray-700 text-xs font-medium px-3.5 py-1.5">
                    Savory
                  </span>
                  <span className="rounded-full bg-gray-100 text-gray-700 text-xs font-medium px-3.5 py-1.5">
                    Creamy
                  </span>
                  <span className="rounded-full bg-gray-100 text-gray-700 text-xs font-medium px-3.5 py-1.5">
                    Comforting
                  </span>
                </div>
              </div>
            </div>

            {/* Ingredients Card */}
            <div className="rounded-xl bg-white p-6 shadow-xs space-y-4">
              <h2 className="font-serif text-lg font-semibold text-ink border-b border-gray-100 pb-1">
                Ingredients
              </h2>

              <ul className="space-y-3 font-sans text-xs sm:text-sm">
                {ingredientsList.map((item, idx) => {
                  const isChecked = checkedIngredients[idx] || false;
                  return (
                    <li
                      key={idx}
                      className="flex items-start gap-3 cursor-pointer select-none"
                    >
                      <input
                        type="checkbox"
                        checked={isChecked}
                        onChange={() => toggleIngredient(idx)}
                        className="mt-0.5 h-4 w-4 rounded border-gray-300 accent-caramel cursor-pointer"
                        id={`ingredient-${idx}`}
                      />
                      <label
                        htmlFor={`ingredient-${idx}`}
                        className={`cursor-pointer transition-colors ${
                          isChecked
                            ? "line-through text-gray-400"
                            : "text-gray-700 font-medium"
                        }`}
                      >
                        {item}
                      </label>
                    </li>
                  );
                })}
              </ul>
            </div>

            {/* Recipe Video Card */}
            <div className="rounded-xl bg-white p-6 shadow-xs space-y-4">
              <h2 className="font-serif text-lg font-semibold text-ink border-b border-gray-100 pb-1">
                Recipe Video
              </h2>

              <div className="relative aspect-video rounded-xl overflow-hidden shadow-sm group cursor-pointer">
                <img
                  src="/step-3.jpg"
                  alt="Recipe Video Thumbnail"
                  className="h-full w-full object-cover group-hover:scale-105 transition-transform duration-300"
                />
                <div className="absolute inset-0 bg-black/30 group-hover:bg-black/20 transition-colors" />

                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-14 h-14 rounded-full bg-caramel text-white flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
                    <Play size={24} className="fill-white translate-x-0.5" />
                  </div>
                </div>

                <div className="absolute bottom-3 left-3 right-3 text-white font-sans">
                  <span className="text-[10px] font-bold uppercase tracking-wider bg-black/60 backdrop-blur-xs px-2 py-0.5 rounded">
                    TIPS
                  </span>
                  <p className="text-xs font-semibold mt-1 drop-shadow-sm">
                    Master Pasta Cooking - Essential Tips
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Right Main Column: Cooking Method (8 cols) */}
          <div className="lg:col-span-8">
            <div className="rounded-xl">
              {/* <h2 className="font-serif text-2xl font-semibold text-ink mb-8">
                Cooking Method
              </h2> */}

              <div className="relative pl-12 space-y-12">
                {/* Continuous Vertical Timeline Line */}
                <div className="absolute left-5 top-4 bottom-8 w-0.5 bg-caramel/30" />

                {cookingSteps.map((step) => (
                  <div key={step.step} className="relative">
                    {/* Step Number Circle */}
                    <div className="absolute -left-12 top-0 w-10 h-10 rounded-full border-2 border-caramel bg-white text-caramel font-bold text-sm flex items-center justify-center shadow-xs z-10 font-sans">
                      {step.step}
                    </div>

                    <div>
                      <h3 className="font-sans font-bold text-base text-ink mb-1">
                        {step.title}
                      </h3>
                      <p className="font-sans text-xs sm:text-sm text-gray-600 leading-relaxed max-w-2xl">
                        {step.description}
                      </p>

                      {step.image && (
                        <div className="mt-4 overflow-hidden rounded-xl border border-gray-100 shadow-sm max-h-[300px]">
                          <img
                            src={step.image}
                            alt={step.title}
                            className="w-full h-full object-cover hover:scale-102 transition-transform duration-300"
                          />
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* You Might Also Like Section */}
        <section className="mt-16 border-t border-gray-200/80 pt-8">
          <h2 className="font-serif text-lg sm:text-xl text-ink font-semibold mb-8">
            You Might Also Like
          </h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-8">
            {relatedRecipes.map((recipe) => (
              <RecipeCard key={recipe.id} recipe={recipe} />
            ))}
          </div>
        </section>
      </main>
    </div>
  );
}
