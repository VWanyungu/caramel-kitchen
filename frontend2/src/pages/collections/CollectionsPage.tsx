import { useState, useEffect } from "react";
import { Bookmark, BookOpen, Calendar, Film, Layers } from "lucide-react";
import { CollectionCard } from "../../components/CollectionCard";
import { MOCK_COLLECTIONS } from "./mockData";
import {
  getSavedCollectionIds,
  subscribeToSavedCollections,
} from "../../lib/savedCollectionsStorage";

type FilterTab = "all" | "saved" | "seasonal" | "meal_plans" | "videos";

export function CollectionsPage() {
  const [activeTab, setActiveTab] = useState<FilterTab>("all");
  const [savedIds, setSavedIds] = useState<string[]>(getSavedCollectionIds());
  const collections = MOCK_COLLECTIONS;

  useEffect(() => {
    setSavedIds(getSavedCollectionIds());
    const unsubscribe = subscribeToSavedCollections(() => {
      setSavedIds(getSavedCollectionIds());
    });
    return unsubscribe;
  }, []);

  const filteredCollections = collections.filter((collection) => {
    if (activeTab === "all") return true;
    if (activeTab === "saved") return savedIds.includes(collection.id);
    if (activeTab === "seasonal") return collection.is_seasonal;
    if (activeTab === "videos") {
      return collection.items?.some((item) => item.item_type === "video");
    }
    if (activeTab === "meal_plans") {
      return collection.name.toLowerCase().includes("plan");
    }
    return true;
  });

  return (
    <div className="min-h-screen w-full bg-white dark:bg-[#120905] transition-colors duration-300 pb-20">
      {/* Hero Section */}
      <section className="relative px-4 sm:px-8 lg:px-24 pt-12 lg:pt-20 pb-12 overflow-hidden">
        <div className="absolute inset-0 bg-caramel/5 dark:bg-caramel/10" />
        <div className="relative z-10 max-w-4xl">
          <h1 className="font-display text-4xl sm:text-5xl lg:text-6xl font-bold text-ink dark:text-white leading-tight tracking-tight mb-4">
            Curated <span className="text-caramel italic font-light">Collections</span>
          </h1>
          <p className="text-lg text-gray-600 dark:text-gray-300 max-w-2xl leading-relaxed">
            Discover our hand-picked selections of premium recipes, seasonal guides, and expert video tutorials. 
            Designed to inspire your next culinary masterpiece.
          </p>
        </div>
      </section>

      {/* Filters & Content */}
      <section className="px-4 sm:px-8 lg:px-24 py-8">
        {/* Filter Tabs */}
        <div className="flex flex-wrap items-center gap-3 mb-10">
          <button
            onClick={() => setActiveTab("all")}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-semibold transition-all duration-200 cursor-pointer ${
              activeTab === "all"
                ? "bg-ink dark:bg-white text-white dark:text-ink shadow-md"
                : "bg-gray-100 dark:bg-stone-900 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-stone-800"
            }`}
          >
            <Layers size={16} />
            <span>All</span>
          </button>

          <button
            onClick={() => setActiveTab("saved")}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-semibold transition-all duration-200 cursor-pointer ${
              activeTab === "saved"
                ? "bg-caramel text-white shadow-md shadow-caramel/20"
                : "bg-gray-100 dark:bg-stone-900 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-stone-800"
            }`}
          >
            <Bookmark size={16} />
            <span>Saved ({savedIds.length})</span>
          </button>

          <button
            onClick={() => setActiveTab("seasonal")}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-semibold transition-all duration-200 cursor-pointer ${
              activeTab === "seasonal"
                ? "bg-emerald-500 text-white shadow-md shadow-emerald-500/20"
                : "bg-gray-100 dark:bg-stone-900 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-stone-800"
            }`}
          >
            <Calendar size={16} />
            <span>Seasonal</span>
          </button>

          <button
            onClick={() => setActiveTab("videos")}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-semibold transition-all duration-200 cursor-pointer ${
              activeTab === "videos"
                ? "bg-blue-500 text-white shadow-md shadow-blue-500/20"
                : "bg-gray-100 dark:bg-stone-900 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-stone-800"
            }`}
          >
            <Film size={16} />
            <span>Video Courses</span>
          </button>

          <button
            onClick={() => setActiveTab("meal_plans")}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-semibold transition-all duration-200 cursor-pointer ${
              activeTab === "meal_plans"
                ? "bg-amber-500 text-white shadow-md shadow-amber-500/20"
                : "bg-gray-100 dark:bg-stone-900 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-stone-800"
            }`}
          >
            <BookOpen size={16} />
            <span>Meal Plans</span>
          </button>
        </div>

        {/* Collections Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 lg:gap-8">
          {filteredCollections.map((collection) => (
            <CollectionCard key={collection.id} collection={collection} />
          ))}
        </div>

        {filteredCollections.length === 0 && (
          <div className="py-20 flex flex-col items-center justify-center text-center">
            <Layers size={48} className="text-gray-300 dark:text-stone-700 mb-4" />
            <h3 className="text-xl font-display font-bold text-ink dark:text-white mb-2">No collections found</h3>
            <p className="text-gray-500 dark:text-gray-400 max-w-md">
              {activeTab === "saved"
                ? "You haven't saved any collections yet. Click the bookmark icon on any collection card to save it."
                : "We couldn't find any collections matching your selected filter. Try selecting a different category or clearing your filters."}
            </p>
          </div>
        )}
      </section>
    </div>
  );
}
