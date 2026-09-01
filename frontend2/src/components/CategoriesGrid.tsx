import { useEffect, useState } from "react";
import { apiGet } from "../lib/api";
import { Dices } from "lucide-react";
import React from "react";

interface CategoriesGridProps {
  onSelectCategory: (categoryName: string) => void;
  onSurpriseMe: (e: React.MouseEvent) => void;
}

const CATEGORY_MAP: Record<string, { label: string; image: string }> = {
  egg_dishes: {
    label: "Egg Dishes",
    image: "https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=600&q=80",
  },
  rice_dishes: {
    label: "Rice Dishes",
    image: "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=600&q=80",
  },
  soups_stews: {
    label: "Soups & Stews",
    image: "/category_central.jpg",
  },
  meat_dishes: {
    label: "Meat Dishes",
    image: "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=600&q=80",
  },
  fish_seafood: {
    label: "Fish & Seafood",
    image: "/category_nyanza.jpg",
  },
  salads: {
    label: "Salads",
    image: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=600&q=80",
  },
  pasta_noodles: {
    label: "Pasta & Noodles",
    image: "/tuscan-pasta-hero.jpg",
  },
  breakfast: {
    label: "Breakfast",
    image: "/category_coastal.jpg",
  },
  baked_goods: {
    label: "Baked Goods",
    image: "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80",
  },
  drinks_juices: {
    label: "Drinks & Juices",
    image: "/category_western.jpg",
  },
  snacks: {
    label: "Snacks",
    image: "https://images.unsplash.com/photo-1599490659213-e2b9527bb087?auto=format&fit=crop&w=600&q=80",
  },
  vegetarian: {
    label: "Vegetarian",
    image: "https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80",
  },
};

const DEFAULT_CATEGORIES = ["breakfast", "soups_stews", "drinks_juices", "fish_seafood"];

export function CategoriesGrid({
  onSelectCategory,
  onSurpriseMe,
}: CategoriesGridProps) {
  const [categories, setCategories] = useState<string[]>([]);

  useEffect(() => {
    apiGet<{ data: Record<string, number> }>("/categories", undefined, {
      auth: false,
    })
      .then(({ data }) => setCategories(Object.keys(data)))
      .catch(() => setCategories([]));
  }, []);

  const displayCategories = categories.length > 0 ? categories : DEFAULT_CATEGORIES;

  return (
    <div className="font-sans">
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8 pt-8">
        {displayCategories.map((catKey) => {
          const mapped = CATEGORY_MAP[catKey] || {
            label: catKey.replace("_", " "),
            image: "https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=600&q=80",
          };

          return (
            <div
              key={catKey}
              onClick={() => onSelectCategory(catKey)}
              className="group relative h-32 rounded-full overflow-hidden cursor-pointer shadow-lg transition-all duration-300 hover:-translate-y-1.5 hover:shadow-xl select-none"
            >
              {/* Background image & zoom transition */}
              <div
                className="absolute inset-0 bg-cover bg-center transition-transform duration-500 group-hover:scale-105"
                style={{ backgroundImage: `url(${mapped.image})` }}
              />

              {/* Dark overlay for readability */}
              <div className="absolute inset-0 bg-black/45 group-hover:bg-black/35 transition-colors duration-300" />

              {/* Center Title */}
              <div className="absolute inset-0 flex items-center justify-center z-10">
                <span className="text-white text-base font-bold tracking-wide text-center px-4 capitalize">
                  {mapped.label}
                </span>
              </div>
            </div>
          );
        })}

      </div>
    </div>
  );
}
