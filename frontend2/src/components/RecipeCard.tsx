import { Bookmark, Star, Banknote } from "lucide-react";
import { useState, type MouseEvent } from "react";
import { Link } from "react-router-dom";
import { apiPost } from "../lib/api";
import type { RecipeCard as RecipeCardData } from "../features/browse/types";
import { usePremiumModal } from "../context/PremiumModalContext";

export function RecipeCard({ recipe }: { recipe: RecipeCardData }) {
  const [saved, setSaved] = useState(false);
  const [pending, setPending] = useState(false);
  const { openPremiumModal, isPremium } = usePremiumModal();

  const handleToggleSave = async (e: MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (pending) return;

    if (saved) {
      setSaved(false);
      return;
    }

    setSaved(true);
    setPending(true);
    try {
      await apiPost(`/recipes/${recipe.id}/save`);
    } catch {
      setSaved(false);
    } finally {
      setPending(false);
    }
  };

  const handleCardClick = (e: MouseEvent) => {
    if (recipe.is_special && !isPremium) {
      e.preventDefault();
      openPremiumModal({
        featureName: "Exclusive Pro Recipe",
        featureDescription: `"${recipe.title}" is a special culinary creation available exclusively to Caramel Silver & Bronze plan members.`,
      });
    }
  };

  const handleProBadgeClick = (e: MouseEvent) => {
    if (!isPremium) {
      e.preventDefault();
      e.stopPropagation();
      openPremiumModal({
        featureName: "Exclusive Pro Recipe",
        featureDescription: `"${recipe.title}" is a special culinary creation available exclusively to Caramel Silver & Bronze plan members.`,
      });
    }
  };

  return (
    <Link
      to={`/recipes/${recipe.id}`}
      onClick={handleCardClick}
      className="group block cursor-pointer"
    >
      <div className="relative aspect-[2/3] overflow-hidden rounded-2xl bg-taupe/20 shadow-lg">
        <div
          className="absolute inset-0 bg-cover bg-center transition-transform duration-300 group-hover:scale-105 motion-reduce:transition-none motion-reduce:group-hover:scale-100 shadow-lg"
          style={
            recipe.thumbnail_url
              ? { backgroundImage: `url(${recipe.thumbnail_url})` }
              : undefined
          }
        />
        <button
          type="button"
          onClick={handleToggleSave}
          aria-pressed={saved}
          aria-label={saved ? "Remove from saved recipes" : "Save recipe"}
          className="cursor-pointer absolute right-4 top-4 rounded-full bg-ink/30 p-2 backdrop-blur-sm transition-colors hover:bg-ink/50 motion-reduce:transition-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-butter z-10"
        >
          <Bookmark
            className={`h-4 w-4 ${saved ? "fill-butter text-butter" : "fill-transparent text-parchment"}`}
          />
        </button>
      </div>

      <div className="mt-3">
        <h3
          className="text-sm leading-tight max-w-[30ch] font-semibold text-ink group-hover:text-caramel transition-colors"
          title={`${recipe.title}`}
        >
          {recipe.title.length > 40
            ? recipe.title.slice(0, 40) + "..."
            : recipe.title}
        </h3>
        <div className="mt-2 flex items-center justify-between gap-3 font-sans text-xs">

          <div className="flex gap-2 items-center justify-end">
            <span className="flex items-center gap-1 text-gray-400">
              <Star className="h-3.5 w-3.5 fill-gray-200 text-gray-400" />
              {recipe.avg_rating.toFixed(1)}
            </span>
            {/* <span className="flex items-center gap-1 text-gray-400">
              <Clock className="h-3.5 w-3.5" />
              {recipe.total_time_mins}m
            </span> */}
            <span className="flex items-center gap-1 text-gray-400">
              <Banknote className="h-3.5 w-3.5" />
              450 Ksh
            </span>

          </div>

          {recipe.is_special && (
            <span
              onClick={handleProBadgeClick}
              className={`rounded-sm px-2 py-0 text-[10px] uppercase font-bold tracking-wide bg-caramel hover:bg-caramel/90 text-white transition-colors cursor-pointer`}
            >
              PRO
            </span>
          )}
        </div>
      </div>
    </Link>
  );
}

