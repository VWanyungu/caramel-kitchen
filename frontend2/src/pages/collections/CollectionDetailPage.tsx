import { useState } from "react";
import { useParams, Link } from "react-router-dom";
import { ChevronLeft, Layers, PlayCircle, BookOpen, UtensilsCrossed } from "lucide-react";
import { MOCK_COLLECTIONS } from "./mockData";
import { RecipeGrid } from "../../components/RecipeGrid";
import type { RecipeCard } from "../../features/browse/types";
import type { VideoCard } from "./types";

type Tab = "recipes" | "videos" | "meal_plans";

export function CollectionDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [activeTab, setActiveTab] = useState<Tab>("recipes");

  const collection = MOCK_COLLECTIONS.find(c => c.id === id);

  if (!collection) {
    return (
      <div className="min-h-screen flex items-center justify-center text-ink dark:text-white">
        <h2>Collection not found</h2>
      </div>
    );
  }

  // Extract items
  const recipes = collection.items
    ?.filter(item => item.item_type === "recipe" && item.recipe)
    .map(item => item.recipe as RecipeCard) || [];

  const videos = collection.items
    ?.filter(item => item.item_type === "video" && item.video)
    .map(item => item.video as VideoCard) || [];

  return (
    <div className="min-h-screen w-full bg-white dark:bg-[#120905] transition-colors duration-300 pb-20">
      {/* Hero Section */}
      <section className="relative h-[40vh] min-h-[300px] w-full">
        <img
          src={collection.cover_image_url}
          alt={collection.name}
          className="absolute inset-0 w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-[#120905] via-black/40 to-transparent" />

        <div className="absolute inset-0 px-4 sm:px-8 lg:px-24 pt-8 pb-12 flex flex-col justify-between">
          <Link
            to="/collections"
            className="flex items-center gap-2 text-white/80 hover:text-white transition-colors w-fit bg-black/30 backdrop-blur-md px-3 py-1.5 rounded-full text-sm font-medium"
          >
            <ChevronLeft size={16} />
            Back to Collections
          </Link>

          <div className="max-w-4xl">
            {collection.is_seasonal && (
              <span className="inline-block px-3 py-1 rounded-full bg-emerald-500 text-white text-xs font-bold tracking-wider uppercase mb-4">
                {collection.season_name}
              </span>
            )}
            <h1 className="font-display text-4xl sm:text-5xl lg:text-6xl font-bold text-white leading-tight tracking-tight mb-4">
              {collection.name}
            </h1>
            <p className="text-lg text-gray-200 max-w-2xl leading-relaxed">
              {collection.description}
            </p>
          </div>
        </div>
      </section>

      {/* Content Section */}
      <section className="px-4 sm:px-8 lg:px-24 py-8">

        {/* Tabs */}
        <div className="flex border-b border-taupe/20 dark:border-stone-800 mb-8 overflow-x-auto hide-scrollbar">
          <button
            onClick={() => setActiveTab("recipes")}
            className={`flex items-center gap-2 px-6 py-4 font-semibold text-sm transition-all whitespace-nowrap ${activeTab === "recipes"
              ? "text-caramel border-b-2 border-caramel"
              : "text-gray-500 hover:text-ink dark:hover:text-white"
              }`}
          >
            <UtensilsCrossed size={18} />
            Recipes ({recipes.length})
          </button>

          <button
            onClick={() => setActiveTab("videos")}
            className={`flex items-center gap-2 px-6 py-4 font-semibold text-sm transition-all whitespace-nowrap ${activeTab === "videos"
              ? "text-caramel border-b-2 border-caramel"
              : "text-gray-500 hover:text-ink dark:hover:text-white"
              }`}
          >
            <PlayCircle size={18} />
            Videos ({videos.length})
          </button>

          <button
            onClick={() => setActiveTab("meal_plans")}
            className={`flex items-center gap-2 px-6 py-4 font-semibold text-sm transition-all whitespace-nowrap ${activeTab === "meal_plans"
              ? "text-caramel border-b-2 border-caramel"
              : "text-gray-500 hover:text-ink dark:hover:text-white"
              }`}
          >
            <BookOpen size={18} />
            Meal Plans (0)
          </button>
        </div>

        {/* Tab Content */}
        <div className="min-h-[400px]">
          {activeTab === "recipes" && (
            recipes.length > 0 ? (
              <RecipeGrid
                recipes={recipes}
                status="success"
                hasMore={false}
                onLoadMore={() => { }}
              />
            ) : (
              <div className="py-20 flex flex-col items-center justify-center text-center">
                <UtensilsCrossed size={48} className="text-gray-300 dark:text-stone-700 mb-4" />
                <h3 className="text-xl font-display font-bold text-ink dark:text-white mb-2">No recipes</h3>
                <p className="text-gray-500 dark:text-gray-400 max-w-md">
                  This collection doesn't have any recipes yet.
                </p>
              </div>
            )
          )}

          {activeTab === "videos" && (
            videos.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {videos.map(video => (
                  <div key={video.id} className="group relative flex flex-col h-full overflow-hidden rounded-2xl bg-white dark:bg-stone-900 border border-taupe/20 dark:border-stone-800 shadow-sm hover:shadow-xl transition-all cursor-pointer">
                    <div className="relative aspect-video w-full overflow-hidden">
                      <img src={video.thumbnail_url} alt={video.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                      <div className="absolute inset-0 bg-black/20 group-hover:bg-black/10 transition-colors" />
                      <PlayCircle size={48} className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-white opacity-80 group-hover:opacity-100 group-hover:scale-110 transition-all drop-shadow-lg" />
                      <div className="absolute bottom-2 right-2 bg-black/70 text-white text-[10px] font-bold px-2 py-1 rounded-md backdrop-blur-sm">
                        {video.duration_mins} MIN
                      </div>
                    </div>
                    <div className="p-4">
                      <h4 className="font-bold text-ink dark:text-white mb-1 line-clamp-2">{video.title}</h4>
                      <p className="text-sm text-gray-500 dark:text-gray-400 line-clamp-2">{video.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="py-20 flex flex-col items-center justify-center text-center">
                <PlayCircle size={48} className="text-gray-300 dark:text-stone-700 mb-4" />
                <h3 className="text-xl font-display font-bold text-ink dark:text-white mb-2">No videos</h3>
                <p className="text-gray-500 dark:text-gray-400 max-w-md">
                  This collection doesn't have any video courses yet.
                </p>
              </div>
            )
          )}

          {activeTab === "meal_plans" && (
            <div className="py-20 flex flex-col items-center justify-center text-center">
              <BookOpen size={48} className="text-gray-300 dark:text-stone-700 mb-4" />
              <h3 className="text-xl font-display font-bold text-ink dark:text-white mb-2">No meal plans</h3>
              <p className="text-gray-500 dark:text-gray-400 max-w-md">
                This collection doesn't have any meal plans attached.
              </p>
            </div>
          )}
        </div>
      </section>
    </div>
  );
}
