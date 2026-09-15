import React, { useState } from "react";
import {
  Utensils,
  Video,
  Layers,
  Calendar,
  Tag,
  Plus,
  Search,
  Edit3,
  Trash2,
  CheckCircle2,
  Globe,
  Flame,
  Star,
  ShieldCheck,
  FolderPlus,
  RefreshCw,
  X,
} from "lucide-react";
import { Button } from "../components/ui";
import { PLACEHOLDER_RECIPES } from "../features/browse/placeholderRecipes";
import { SOFIA_VIDEOS } from "../data/sofiaVideosData";
import { MOCK_COLLECTIONS } from "./collections/mockData";

type AdminTab = "recipes" | "videos" | "collections" | "meal_plans" | "taxonomies";

interface CategoryItem {
  id: string;
  name: string;
  count: number;
  color: string;
}

interface CuisineItem {
  id: string;
  name: string;
  region: string;
  recipeCount: number;
}

interface TasteTag {
  id: string;
  name: string;
  flavorProfile: string;
}

export function AdminPortalPage() {
  const [activeTab, setActiveTab] = useState<AdminTab>("recipes");
  const [searchQuery, setSearchQuery] = useState("");
  const [toastMsg, setToastMsg] = useState<string | null>(null);

  // Modal State
  const [showAddModal, setShowAddModal] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [newCategory, setNewCategory] = useState("Main Dishes");

  // Sample Taxonomies state
  const [categories] = useState<CategoryItem[]>([
    { id: "cat-1", name: "Main Dishes", count: 48, color: "bg-amber-500/10 text-amber-600 border-amber-500/20" },
    { id: "cat-2", name: "Pastry & Baking", count: 24, color: "bg-rose-500/10 text-rose-600 border-rose-500/20" },
    { id: "cat-3", name: "Soups & Stews", count: 18, color: "bg-emerald-500/10 text-emerald-600 border-emerald-500/20" },
    { id: "cat-4", name: "Seafood", count: 15, color: "bg-blue-500/10 text-blue-600 border-blue-500/20" },
    { id: "cat-5", name: "Desserts", count: 30, color: "bg-purple-500/10 text-purple-600 border-purple-500/20" },
  ]);

  const [cuisines] = useState<CuisineItem[]>([
    { id: "cui-1", name: "Italian", region: "European", recipeCount: 32 },
    { id: "cui-2", name: "Swahili & Coastal", region: "East African", recipeCount: 28 },
    { id: "cui-3", name: "French Classical", region: "European", recipeCount: 22 },
    { id: "cui-4", name: "Japanese & Asian", region: "East Asian", recipeCount: 19 },
    { id: "cui-5", name: "Mediterranean", region: "Southern European", recipeCount: 25 },
  ]);

  const [tasteTags] = useState<TasteTag[]>([
    { id: "tag-1", name: "Umami Rich", flavorProfile: "Savory & Deep" },
    { id: "tag-2", name: "Spicy & Aromatic", flavorProfile: "Chili & Peppers" },
    { id: "tag-3", name: "Citrus Zing", flavorProfile: "Fresh & Acidic" },
    { id: "tag-4", name: "Crispy & Crunchy", flavorProfile: "Textural" },
    { id: "tag-5", name: "Creamy & Silky", flavorProfile: "Rich & Dairy" },
    { id: "tag-6", name: "Gluten-Free", flavorProfile: "Dietary" },
  ]);

  const triggerToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => {
      setToastMsg((prev) => (prev === msg ? null : prev));
    }, 3000);
  };

  const handleCreateContent = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim()) return;
    triggerToast(`Added new ${activeTab.slice(0, -1)}: "${newTitle}"!`);
    setNewTitle("");
    setShowAddModal(false);
  };

  const handleDeleteItem = (title: string) => {
    triggerToast(`Removed "${title}" from catalog.`);
  };

  // Filter recipes
  const filteredRecipes = PLACEHOLDER_RECIPES.filter((r) =>
    r.title.toLowerCase().includes(searchQuery.toLowerCase()),
  );

  // Filter videos
  const filteredVideos = SOFIA_VIDEOS.filter((v) =>
    v.title.toLowerCase().includes(searchQuery.toLowerCase()),
  );

  // Filter collections
  const filteredCollections = MOCK_COLLECTIONS.filter((c) =>
    c.name.toLowerCase().includes(searchQuery.toLowerCase()),
  );

  return (
    <div className="min-h-screen bg-gray-50/70 dark:bg-[#120905] text-ink dark:text-parchment pb-24 transition-colors duration-300">
      {/* Toast Notification */}
      {toastMsg && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 bg-caramel text-white px-5 py-3 rounded-2xl shadow-xl animate-fade-in border border-amber-300/20">
          <CheckCircle2 size={18} />
          <span className="text-sm font-medium">{toastMsg}</span>
        </div>
      )}

      {/* Header Banner */}
      <div className="bg-gradient-to-r from-[#1c120c] via-[#24160e] to-[#1a0e08] text-white border-b border-taupe/20 dark:border-stone-850 pt-10 pb-8 px-4 sm:px-8">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/20 text-amber-400 text-xs font-bold uppercase tracking-wider border border-amber-500/30">
              <ShieldCheck size={14} />
              <span>Admin & Content Portal</span>
            </div>
            <h1 className="font-serif text-3xl sm:text-4xl font-bold tracking-tight">
              Caramel Content Manager
            </h1>
            <p className="text-xs sm:text-sm text-stone-300 max-w-xl">
              Central management dashboard for recipes, Learn with Sofia videos, collections, meal plan templates, and flavor taxonomies.
            </p>
          </div>

          <button
            onClick={() => setShowAddModal(true)}
            className="px-5 py-2.5 rounded-2xl bg-caramel hover:bg-caramel-dark text-white font-bold text-xs flex items-center gap-2 shadow-lg transition-all cursor-pointer"
          >
            <Plus size={16} />
            <span>Create New Content</span>
          </button>
        </div>

        {/* Dashboard Overview Cards */}
        <div className="max-w-7xl mx-auto grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-5 gap-3 sm:gap-4 mt-8">
          <div className="bg-white/5 backdrop-blur-md p-4 rounded-2xl border border-white/10 flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-amber-500/20 text-amber-400">
              <Utensils size={20} />
            </div>
            <div>
              <span className="text-xs text-stone-400 block font-medium">Recipes</span>
              <strong className="text-lg font-bold text-white">{PLACEHOLDER_RECIPES.length + 120}</strong>
            </div>
          </div>

          <div className="bg-white/5 backdrop-blur-md p-4 rounded-2xl border border-white/10 flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-rose-500/20 text-rose-400">
              <Video size={20} />
            </div>
            <div>
              <span className="text-xs text-stone-400 block font-medium">Sofia Videos</span>
              <strong className="text-lg font-bold text-white">{SOFIA_VIDEOS.length}</strong>
            </div>
          </div>

          <div className="bg-white/5 backdrop-blur-md p-4 rounded-2xl border border-white/10 flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-blue-500/20 text-blue-400">
              <Layers size={20} />
            </div>
            <div>
              <span className="text-xs text-stone-400 block font-medium">Collections</span>
              <strong className="text-lg font-bold text-white">{MOCK_COLLECTIONS.length}</strong>
            </div>
          </div>

          <div className="bg-white/5 backdrop-blur-md p-4 rounded-2xl border border-white/10 flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-emerald-500/20 text-emerald-400">
              <Calendar size={20} />
            </div>
            <div>
              <span className="text-xs text-stone-400 block font-medium">Meal Plans</span>
              <strong className="text-lg font-bold text-white">8</strong>
            </div>
          </div>

          <div className="bg-white/5 backdrop-blur-md p-4 rounded-2xl border border-white/10 flex items-center gap-3 col-span-2 sm:col-span-1">
            <div className="p-2.5 rounded-xl bg-purple-500/20 text-purple-400">
              <Tag size={20} />
            </div>
            <div>
              <span className="text-xs text-stone-400 block font-medium">Taxonomies</span>
              <strong className="text-lg font-bold text-white">42 Tags</strong>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-8 mt-8 space-y-6">
        {/* Navigation Tabs Bar */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2 border-b border-taupe/15 dark:border-stone-850 scrollbar-none text-xs sm:text-sm font-bold">
          <button
            onClick={() => setActiveTab("recipes")}
            className={`px-5 py-3 rounded-2xl transition-all cursor-pointer flex items-center gap-2 whitespace-nowrap ${
              activeTab === "recipes"
                ? "bg-caramel text-white shadow-md"
                : "bg-white dark:bg-[#1c120c] text-gray-600 dark:text-stone-300 border border-taupe/10 dark:border-stone-800 hover:bg-gray-100 dark:hover:bg-stone-800"
            }`}
          >
            <Utensils size={16} />
            <span>Recipes ({PLACEHOLDER_RECIPES.length})</span>
          </button>

          <button
            onClick={() => setActiveTab("videos")}
            className={`px-5 py-3 rounded-2xl transition-all cursor-pointer flex items-center gap-2 whitespace-nowrap ${
              activeTab === "videos"
                ? "bg-caramel text-white shadow-md"
                : "bg-white dark:bg-[#1c120c] text-gray-600 dark:text-stone-300 border border-taupe/10 dark:border-stone-800 hover:bg-gray-100 dark:hover:bg-stone-800"
            }`}
          >
            <Video size={16} />
            <span>Sofia Masterclasses ({SOFIA_VIDEOS.length})</span>
          </button>

          <button
            onClick={() => setActiveTab("collections")}
            className={`px-5 py-3 rounded-2xl transition-all cursor-pointer flex items-center gap-2 whitespace-nowrap ${
              activeTab === "collections"
                ? "bg-caramel text-white shadow-md"
                : "bg-white dark:bg-[#1c120c] text-gray-600 dark:text-stone-300 border border-taupe/10 dark:border-stone-800 hover:bg-gray-100 dark:hover:bg-stone-800"
            }`}
          >
            <Layers size={16} />
            <span>Collections ({MOCK_COLLECTIONS.length})</span>
          </button>

          <button
            onClick={() => setActiveTab("meal_plans")}
            className={`px-5 py-3 rounded-2xl transition-all cursor-pointer flex items-center gap-2 whitespace-nowrap ${
              activeTab === "meal_plans"
                ? "bg-caramel text-white shadow-md"
                : "bg-white dark:bg-[#1c120c] text-gray-600 dark:text-stone-300 border border-taupe/10 dark:border-stone-800 hover:bg-gray-100 dark:hover:bg-stone-800"
            }`}
          >
            <Calendar size={16} />
            <span>Meal Plans</span>
          </button>

          <button
            onClick={() => setActiveTab("taxonomies")}
            className={`px-5 py-3 rounded-2xl transition-all cursor-pointer flex items-center gap-2 whitespace-nowrap ${
              activeTab === "taxonomies"
                ? "bg-caramel text-white shadow-md"
                : "bg-white dark:bg-[#1c120c] text-gray-600 dark:text-stone-300 border border-taupe/10 dark:border-stone-800 hover:bg-gray-100 dark:hover:bg-stone-800"
            }`}
          >
            <Tag size={16} />
            <span>Categories, Cuisines & Tags</span>
          </button>
        </div>

        {/* Search & Actions Bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="relative w-full sm:w-80">
            <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder={`Search ${activeTab}...`}
              className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-white dark:bg-[#1c120c] border border-taupe/20 dark:border-stone-800 text-xs text-ink dark:text-parchment focus:outline-none focus:ring-2 focus:ring-caramel/40"
            />
          </div>

          <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
            <button
              onClick={() => triggerToast("Refreshed data list")}
              className="p-2.5 rounded-xl bg-white dark:bg-[#1c120c] border border-taupe/20 dark:border-stone-800 text-gray-500 hover:text-caramel transition-colors cursor-pointer"
              title="Refresh"
            >
              <RefreshCw size={16} />
            </button>
            <Button
              variant="primary"
              size="sm"
              icon={<Plus size={14} />}
              onClick={() => setShowAddModal(true)}
            >
              Add Item
            </Button>
          </div>
        </div>

        {/* Section 1: Recipes */}
        {activeTab === "recipes" && (
          <div className="bg-white dark:bg-[#1c120c] rounded-3xl border border-taupe/10 dark:border-stone-850 overflow-hidden shadow-xs animate-fade-in">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs text-ink dark:text-parchment">
                <thead className="bg-gray-50/80 dark:bg-[#120905]/60 text-gray-500 dark:text-stone-400 font-bold uppercase tracking-wider border-b border-taupe/10 dark:border-stone-850">
                  <tr>
                    <th className="py-4 px-6">Recipe Name</th>
                    <th className="py-4 px-4">Category</th>
                    <th className="py-4 px-4">Prep Time</th>
                    <th className="py-4 px-4">Rating</th>
                    <th className="py-4 px-4">Status</th>
                    <th className="py-4 px-6 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-taupe/10 dark:divide-stone-850">
                  {filteredRecipes.map((recipe) => (
                    <tr key={recipe.id} className="hover:bg-gray-50/50 dark:hover:bg-stone-900/40 transition-colors">
                      <td className="py-4 px-6 flex items-center gap-3 font-semibold">
                        <img
                          src={recipe.thumbnail_url || ""}
                          alt={recipe.title}
                          className="w-10 h-10 rounded-xl object-cover ring-1 ring-amber-500/20"
                        />
                        <span className="line-clamp-1 max-w-xs">{recipe.title}</span>
                      </td>
                      <td className="py-4 px-4">
                        <span className="px-2.5 py-1 rounded-full bg-caramel/10 text-caramel dark:text-amber-400 font-semibold text-[11px] capitalize">
                          {recipe.dish_category || "Main"}
                        </span>
                      </td>
                      <td className="py-4 px-4 text-gray-500 dark:text-stone-400">{recipe.total_time_mins} mins</td>
                      <td className="py-4 px-4 font-bold text-amber-500">
                        <div className="flex items-center gap-1">
                          <Star size={13} className="fill-amber-500" />
                          <span>{recipe.avg_rating}</span>
                        </div>
                      </td>
                      <td className="py-4 px-4">
                        <span className="px-2.5 py-1 rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 font-semibold text-[11px]">
                          Published
                        </span>
                      </td>
                      <td className="py-4 px-6 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => triggerToast(`Editing "${recipe.title}"`)}
                            className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-stone-800 text-gray-500 hover:text-caramel cursor-pointer"
                          >
                            <Edit3 size={15} />
                          </button>
                          <button
                            onClick={() => handleDeleteItem(recipe.title)}
                            className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-stone-800 text-gray-500 hover:text-red-500 cursor-pointer"
                          >
                            <Trash2 size={15} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Section 2: Sofia Videos */}
        {activeTab === "videos" && (
          <div className="bg-white dark:bg-[#1c120c] rounded-3xl border border-taupe/10 dark:border-stone-850 overflow-hidden shadow-xs animate-fade-in">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs text-ink dark:text-parchment">
                <thead className="bg-gray-50/80 dark:bg-[#120905]/60 text-gray-500 dark:text-stone-400 font-bold uppercase tracking-wider border-b border-taupe/10 dark:border-stone-850">
                  <tr>
                    <th className="py-4 px-6">Video Title</th>
                    <th className="py-4 px-4">Topic / Category</th>
                    <th className="py-4 px-4">Level</th>
                    <th className="py-4 px-4">Duration</th>
                    <th className="py-4 px-4">Views</th>
                    <th className="py-4 px-6 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-taupe/10 dark:divide-stone-850">
                  {filteredVideos.map((video) => (
                    <tr key={video.id} className="hover:bg-gray-50/50 dark:hover:bg-stone-900/40 transition-colors">
                      <td className="py-4 px-6 flex items-center gap-3 font-semibold">
                        <img
                          src={video.thumbnailUrl}
                          alt={video.title}
                          className="w-12 h-8 rounded-lg object-cover ring-1 ring-amber-500/20"
                        />
                        <span className="line-clamp-1 max-w-sm">{video.title}</span>
                      </td>
                      <td className="py-4 px-4 font-semibold text-caramel dark:text-amber-400">
                        {video.category}
                      </td>
                      <td className="py-4 px-4">
                        <span className="px-2 py-0.5 rounded-md bg-amber-500/10 text-amber-600 dark:text-amber-400 font-bold text-[10px]">
                          {video.level}
                        </span>
                      </td>
                      <td className="py-4 px-4 text-gray-500 dark:text-stone-400">{video.duration}</td>
                      <td className="py-4 px-4 text-gray-500 dark:text-stone-400">{video.views}</td>
                      <td className="py-4 px-6 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => triggerToast(`Editing video "${video.title}"`)}
                            className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-stone-800 text-gray-500 hover:text-caramel cursor-pointer"
                          >
                            <Edit3 size={15} />
                          </button>
                          <button
                            onClick={() => handleDeleteItem(video.title)}
                            className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-stone-800 text-gray-500 hover:text-red-500 cursor-pointer"
                          >
                            <Trash2 size={15} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Section 3: Collections */}
        {activeTab === "collections" && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 animate-fade-in">
            {filteredCollections.map((col) => (
              <div
                key={col.id}
                className="bg-white dark:bg-[#1c120c] rounded-3xl p-5 border border-taupe/10 dark:border-stone-850 shadow-xs space-y-4 flex flex-col justify-between"
              >
                <div className="space-y-3">
                  <div className="relative aspect-video rounded-2xl overflow-hidden bg-black/10">
                    <img src={col.cover_image_url} alt={col.name} className="w-full h-full object-cover" />
                    <div className="absolute top-2.5 left-2.5 flex items-center gap-1.5">
                      {col.is_premium && (
                        <span className="px-2.5 py-0.5 rounded-full bg-amber-500 text-white text-[10px] font-bold uppercase">
                          PRO
                        </span>
                      )}
                      {col.is_seasonal && (
                        <span className="px-2.5 py-0.5 rounded-full bg-emerald-500 text-white text-[10px] font-bold uppercase">
                          Seasonal
                        </span>
                      )}
                    </div>
                  </div>
                  <h3 className="font-serif text-base font-bold text-ink dark:text-parchment">{col.name}</h3>
                  <p className="text-xs text-gray-500 dark:text-stone-400 line-clamp-2 leading-relaxed">
                    {col.description}
                  </p>
                </div>

                <div className="pt-3 border-t border-taupe/10 dark:border-stone-850 flex items-center justify-between">
                  <span className="text-xs text-gray-400">{col.items?.length || 0} items included</span>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => triggerToast(`Editing collection "${col.name}"`)}
                      className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-stone-800 text-gray-500 hover:text-caramel cursor-pointer"
                    >
                      <Edit3 size={15} />
                    </button>
                    <button
                      onClick={() => handleDeleteItem(col.name)}
                      className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-stone-800 text-gray-500 hover:text-red-500 cursor-pointer"
                    >
                      <Trash2 size={15} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Section 4: Meal Plans */}
        {activeTab === "meal_plans" && (
          <div className="bg-white dark:bg-[#1c120c] rounded-3xl p-8 border border-taupe/10 dark:border-stone-850 shadow-xs space-y-6 animate-fade-in">
            <div className="flex items-center justify-between border-b border-taupe/10 dark:border-stone-850 pb-4">
              <div>
                <h3 className="font-serif text-lg font-bold text-ink dark:text-parchment">
                  Weekly Meal Plan Templates
                </h3>
                <p className="text-xs text-gray-500 dark:text-stone-400">
                  Pre-configured macro targets and day schedules for user subscriptions.
                </p>
              </div>
              <Button variant="primary" size="sm" icon={<Plus size={14} />} onClick={() => setShowAddModal(true)}>
                Add Meal Template
              </Button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {[
                { title: "High Protein Muscle & Balance", calories: "2,400 kcal/day", days: 7, tags: ["High Protein", "Fitness"] },
                { title: "Mediterranean Heart Healthy", calories: "1,850 kcal/day", days: 7, tags: ["Low Sugar", "Healthy"] },
                { title: "Quick 30-Minute Family Prep", calories: "2,100 kcal/day", days: 5, tags: ["Family", "Quick"] },
                { title: "Plant-Based & Fiber Rich", calories: "1,950 kcal/day", days: 7, tags: ["Vegan", "Clean"] },
              ].map((mp, i) => (
                <div key={i} className="p-5 rounded-2xl bg-gray-50/50 dark:bg-[#120905]/50 border border-taupe/10 dark:border-stone-800 flex items-center justify-between">
                  <div className="space-y-1">
                    <h4 className="font-bold text-sm text-ink dark:text-parchment">{mp.title}</h4>
                    <p className="text-xs text-gray-500 dark:text-stone-400">
                      {mp.days} Days • {mp.calories}
                    </p>
                    <div className="flex gap-1.5 pt-1">
                      {mp.tags.map((t) => (
                        <span key={t} className="px-2 py-0.5 rounded-md bg-caramel/10 text-caramel text-[10px] font-semibold">
                          {t}
                        </span>
                      ))}
                    </div>
                  </div>
                  <div className="flex items-center gap-1">
                    <button onClick={() => triggerToast(`Editing ${mp.title}`)} className="p-2 text-gray-400 hover:text-caramel cursor-pointer">
                      <Edit3 size={15} />
                    </button>
                    <button onClick={() => handleDeleteItem(mp.title)} className="p-2 text-gray-400 hover:text-red-500 cursor-pointer">
                      <Trash2 size={15} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Section 5: Taxonomies, Categories, Cuisines & Taste Tags */}
        {activeTab === "taxonomies" && (
          <div className="space-y-8 animate-fade-in">
            {/* Categories */}
            <div className="bg-white dark:bg-[#1c120c] rounded-3xl p-6 sm:p-8 border border-taupe/10 dark:border-stone-850 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-taupe/10 dark:border-stone-850 pb-3">
                <h3 className="font-serif text-lg font-bold text-ink dark:text-parchment flex items-center gap-2">
                  <Utensils size={18} className="text-caramel" />
                  <span>Recipe Categories</span>
                </h3>
                <button onClick={() => triggerToast("Add Category Modal")} className="text-xs font-bold text-caramel hover:underline cursor-pointer flex items-center gap-1">
                  <Plus size={14} /> Add Category
                </button>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3">
                {categories.map((cat) => (
                  <div key={cat.id} className={`p-4 rounded-2xl border ${cat.color} flex flex-col justify-between space-y-2`}>
                    <span className="font-bold text-xs">{cat.name}</span>
                    <span className="text-[11px] opacity-75">{cat.count} Recipes</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Cuisines */}
            <div className="bg-white dark:bg-[#1c120c] rounded-3xl p-6 sm:p-8 border border-taupe/10 dark:border-stone-850 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-taupe/10 dark:border-stone-850 pb-3">
                <h3 className="font-serif text-lg font-bold text-ink dark:text-parchment flex items-center gap-2">
                  <Globe size={18} className="text-caramel" />
                  <span>World Cuisines</span>
                </h3>
                <button onClick={() => triggerToast("Add Cuisine Modal")} className="text-xs font-bold text-caramel hover:underline cursor-pointer flex items-center gap-1">
                  <Plus size={14} /> Add Cuisine
                </button>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
                {cuisines.map((cui) => (
                  <div key={cui.id} className="p-4 rounded-2xl bg-gray-50/70 dark:bg-[#120905]/50 border border-taupe/10 dark:border-stone-800 space-y-1">
                    <span className="font-bold text-xs text-ink dark:text-parchment block">{cui.name}</span>
                    <span className="text-[10px] text-gray-500 dark:text-stone-400 block">{cui.region}</span>
                    <span className="text-[11px] text-caramel font-semibold block">{cui.recipeCount} Recipes</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Taste Tags */}
            <div className="bg-white dark:bg-[#1c120c] rounded-3xl p-6 sm:p-8 border border-taupe/10 dark:border-stone-850 shadow-xs space-y-4">
              <div className="flex items-center justify-between border-b border-taupe/10 dark:border-stone-850 pb-3">
                <h3 className="font-serif text-lg font-bold text-ink dark:text-parchment flex items-center gap-2">
                  <Flame size={18} className="text-caramel" />
                  <span>Flavor Profiles & Taste Tags</span>
                </h3>
                <button onClick={() => triggerToast("Add Taste Tag Modal")} className="text-xs font-bold text-caramel hover:underline cursor-pointer flex items-center gap-1">
                  <Plus size={14} /> Add Taste Tag
                </button>
              </div>

              <div className="flex flex-wrap gap-2.5">
                {tasteTags.map((tag) => (
                  <div key={tag.id} className="px-3.5 py-2 rounded-2xl bg-amber-500/10 text-amber-700 dark:text-amber-400 border border-amber-500/20 text-xs font-semibold flex items-center gap-2">
                    <span>{tag.name}</span>
                    <span className="text-[10px] opacity-60">({tag.flavorProfile})</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Add Content Modal Stub */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-xs animate-fade-in">
          <div className="bg-white dark:bg-[#1c120c] rounded-3xl max-w-lg w-full p-6 sm:p-8 border border-taupe/20 dark:border-stone-850 shadow-2xl space-y-6">
            <div className="flex items-center justify-between border-b border-taupe/10 dark:border-stone-850 pb-3">
              <h3 className="font-serif text-lg font-bold text-ink dark:text-parchment flex items-center gap-2">
                <FolderPlus size={20} className="text-caramel" />
                <span>Add {activeTab.slice(0, -1)} Entry</span>
              </h3>
              <button onClick={() => setShowAddModal(false)} className="text-gray-400 hover:text-gray-600">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleCreateContent} className="space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-gray-500 mb-1.5">
                  Title / Name
                </label>
                <input
                  type="text"
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  placeholder={`Enter ${activeTab.slice(0, -1)} title...`}
                  className="w-full text-xs sm:text-sm px-4 py-3 rounded-xl bg-gray-50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-none focus:ring-2 focus:ring-caramel/40"
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-gray-500 mb-1.5">
                  Category / Classification
                </label>
                <select
                  value={newCategory}
                  onChange={(e) => setNewCategory(e.target.value)}
                  className="w-full text-xs sm:text-sm px-4 py-3 rounded-xl bg-gray-50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-none cursor-pointer"
                >
                  <option value="Main Dishes">Main Dishes</option>
                  <option value="Knife Skills & Prep">Knife Skills & Prep</option>
                  <option value="Baking & Pastry">Baking & Pastry</option>
                  <option value="Sauces & Stocks">Sauces & Stocks</option>
                  <option value="Italian & Pasta">Italian & Pasta</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-gray-500 mb-1.5">
                  Description Preview
                </label>
                <textarea
                  rows={3}
                  placeholder="Brief description of this content item..."
                  className="w-full text-xs sm:text-sm px-4 py-3 rounded-xl bg-gray-50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-none resize-none"
                />
              </div>

              <div className="flex items-center gap-3 pt-2">
                <Button type="submit" variant="primary" size="md" fullWidth>
                  Publish {activeTab.slice(0, -1)}
                </Button>
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-5 py-3 rounded-xl border border-gray-200 dark:border-stone-800 font-bold text-xs text-gray-600 dark:text-stone-300 hover:bg-gray-100 dark:hover:bg-stone-800 cursor-pointer"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
