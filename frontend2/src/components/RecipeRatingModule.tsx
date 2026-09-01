import { Star } from "lucide-react";
import { useState } from "react";
import { apiPost } from "../lib/api";

interface RatingBreakdown {
  stars: number;
  percentage: number;
}

interface RecipeRatingModuleProps {
  recipeId?: string;
  avgRating?: number;
  ratingCount?: number;
  breakdown?: RatingBreakdown[];
  onRate?: (rating: number) => void;
}

export function RecipeRatingModule({
  recipeId,
  avgRating = 4.7,
  ratingCount = 40,
  breakdown: initialBreakdown = [
    { stars: 5, percentage: 84 },
    { stars: 4, percentage: 9 },
    { stars: 3, percentage: 4 },
    { stars: 2, percentage: 2 },
    { stars: 1, percentage: 1 },
  ],
  onRate,
}: RecipeRatingModuleProps) {
  const [userRating, setUserRating] = useState<number | null>(null);
  const [hoverRating, setHoverRating] = useState<number | null>(null);
  const [currentAvg, setCurrentAvg] = useState(avgRating);
  const [currentCount, setCurrentCount] = useState(ratingCount);
  const [breakdown, setBreakdown] = useState(initialBreakdown);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Handle user submitting a rating
  const handleSelectRating = async (stars: number) => {
    setUserRating(stars);

    // Show notification toast
    setToastMessage(
      `Thank you! You rated this recipe ${stars} star${stars > 1 ? "s" : ""}.`,
    );
    setTimeout(() => {
      setToastMessage(null);
    }, 3500);

    // Calculate new average and count
    const newCount = currentCount + 1;
    const newAvg = Number(
      ((currentAvg * currentCount + stars) / newCount).toFixed(1),
    );
    setCurrentAvg(newAvg);
    setCurrentCount(newCount);

    // Recalculate breakdown dynamically
    setBreakdown((prev) =>
      prev.map((row) => {
        if (row.stars === stars) {
          const newPercentage = Math.min(100, Math.round(row.percentage + 2));
          return { ...row, percentage: newPercentage };
        }
        return row;
      }),
    );

    if (onRate) onRate(stars);

    if (recipeId) {
      try {
        await apiPost(`/recipes/${recipeId}/rate`, { rating: stars });
      } catch {
        // Fallback gracefully if endpoint is simulated
      }
    }
  };

  // Render 5 visual stars for aggregate badge
  const renderAggregateStars = () => {
    return Array.from({ length: 5 }).map((_, i) => {
      const fillPercentage = Math.max(0, Math.min(1, currentAvg - i));
      return (
        <div key={i} className="relative inline-block">
          <Star size={17} className="text-amber-200 dark:text-stone-700" />
          {fillPercentage > 0 && (
            <div
              className="absolute top-0 left-0 overflow-hidden"
              style={{ width: `${fillPercentage * 100}%` }}
            >
              <Star
                size={17}
                className="text-amber-400 fill-amber-400 dark:text-amber-400 dark:fill-amber-400"
              />
            </div>
          )}
        </div>
      );
    });
  };

  return (
    <>
      {/* Notification Toast */}
      {toastMessage && (
        <div className="fixed top-6 right-6 z-50 bg-[#1d120a] dark:bg-parchment text-white dark:text-ink px-4 py-3 rounded-2xl shadow-xl border border-taupe/20 flex items-center gap-3 animate-fade-in transition-all duration-300">
          <div className="p-1.5 bg-amber-400/20 text-amber-400 dark:text-amber-600 rounded-full flex items-center justify-center">
            <Star size={16} className="fill-current" />
          </div>
          <span className="text-xs sm:text-sm font-semibold">
            {toastMessage}
          </span>
        </div>
      )}

      <div className="rounded-2xl bg-white dark:bg-[#1d120a] border border-taupe/15 dark:border-stone-850 p-6 sm:p-7 shadow-xs font-sans space-y-6 transition-colors duration-300">
        {/* Title */}
        <h2 className="font-serif text-lg text-center font-semibold text-ink dark:text-white/70">
          Customer reviews
        </h2>

        {/* Average rating pill badge */}
        <div className="flex flex-col items-center space-y-2">
          <div className="inline-flex items-center gap-2.5 bg-[#fbf5eb] dark:bg-[#251810] border border-caramel/10 dark:border-caramel/20 px-4 py-2 rounded-full shadow-3xs">
            <div className="flex items-center gap-1">
              {renderAggregateStars()}
            </div>
            <span className="text-xs sm:text-sm font-bold text-ink dark:text-white">
              {currentAvg.toFixed(1)} out of 5
            </span>
          </div>

          <p className="text-xs text-gray-400 font-medium tracking-wide">
            {currentCount} customer ratings
          </p>
        </div>

        {/* Flat Rating Breakdown Bars (No 3D effects/shadows) */}
        <div className="space-y-3 pt-1">
          {breakdown.map((row) => (
            <div key={row.stars} className="flex items-center gap-3 text-xs">
              {/* Flat label */}
              <span className="w-11 font-semibold text-caramel dark:text-caramel/90">
                {row.stars} star
              </span>

              {/* Flat progress bar container */}
              <div className="relative flex-1 h-2.5 rounded-full bg-gray-100 dark:bg-stone-800 overflow-hidden">
                <div
                  className="h-full rounded-full bg-[#f5b842] dark:bg-[#e29b3e] transition-all duration-500 ease-out"
                  style={{ width: `${row.percentage}%` }}
                />
              </div>

              {/* Flat percentage label */}
              <span className="w-9 text-right font-semibold text-gray-500 dark:text-gray-400">
                {row.percentage}%
              </span>
            </div>
          ))}
        </div>

        {/* Interactive User Rating Section */}
        <div className="pt-4 border-t border-gray-100 dark:border-stone-850/60 text-center space-y-2.5">
          <span className="block text-xs font-bold uppercase tracking-wider text-ink dark:text-parchment">
            Rate this recipe
          </span>

          {/* Interactive Star Buttons */}
          <div
            className="flex items-center justify-center gap-1.5"
            onMouseLeave={() => setHoverRating(null)}
          >
            {[1, 2, 3, 4, 5].map((starValue) => {
              const isFilled =
                hoverRating !== null
                  ? starValue <= hoverRating
                  : userRating !== null && starValue <= userRating;

              return (
                <button
                  key={starValue}
                  type="button"
                  onClick={() => handleSelectRating(starValue)}
                  onMouseEnter={() => setHoverRating(starValue)}
                  className="p-1 cursor-pointer transition-transform hover:scale-115 focus:outline-hidden"
                  aria-label={`Rate ${starValue} star${starValue > 1 ? "s" : ""}`}
                >
                  <Star
                    size={22}
                    className={`transition-colors duration-150 ${
                      isFilled
                        ? "text-amber-400 fill-amber-400"
                        : "text-gray-300 dark:text-stone-700 hover:text-amber-300"
                    }`}
                  />
                </button>
              );
            })}
          </div>
        </div>

        {/* Calculation Link / Tooltip Toggle */}
        {/* <div className="pt-1 text-center">
          <button
            type="button"
            onClick={() => setShowCalculationInfo((prev) => !prev)}
            className="inline-flex items-center gap-1 text-xs font-semibold text-sky-600 dark:text-sky-400 hover:text-sky-700 dark:hover:text-sky-300 transition-colors cursor-pointer"
          >
            <span>How do we calculate ratings?</span>
          </button>

          {showCalculationInfo && (
            <div className="mt-3 p-3 rounded-xl bg-gray-50 dark:bg-[#120905] border border-gray-200/60 dark:border-stone-800 text-[11px] text-gray-600 dark:text-gray-400 leading-relaxed text-left animate-fade-in">
              Ratings are calculated by combining verified cook reviews, preparation feedback, and community star ratings to provide an honest, unskewed score.
            </div>
          )}
        </div> */}
      </div>
    </>
  );
}
