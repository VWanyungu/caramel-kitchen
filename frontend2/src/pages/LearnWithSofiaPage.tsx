import React, { useState, useEffect } from "react";
import {
  Search,
  Bookmark,
  BookmarkCheck,
  Play,
  X,
  Sparkles,
  BookOpen,
  Eye,
  Clock,
  CheckCircle2,
  SlidersHorizontal,
} from "lucide-react";
import {
  SOFIA_CATEGORIES,
  SOFIA_VIDEOS,
  type SofiaVideo,
} from "../data/sofiaVideosData";
import {
  getSavedVideoIds,
  toggleSaveVideo,
  subscribeToSavedVideos,
} from "../lib/savedVideosStorage";

export function LearnWithSofiaPage() {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [selectedLevel, setSelectedLevel] = useState<string>("All");
  const [sortBy, setSortBy] = useState<"popular" | "newest">("popular");
  const [savedVideoIds, setSavedVideoIds] = useState<string[]>([]);
  const [activeVideoModal, setActiveVideoModal] = useState<SofiaVideo | null>(
    null,
  );
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  useEffect(() => {
    setSavedVideoIds(getSavedVideoIds());
    const unsubscribe = subscribeToSavedVideos(() => {
      setSavedVideoIds(getSavedVideoIds());
    });
    return unsubscribe;
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => {
      setToastMessage((prev) => (prev === msg ? null : prev));
    }, 3000);
  };

  const handleToggleSave = (video: SofiaVideo, e?: React.MouseEvent) => {
    if (e) {
      e.stopPropagation();
    }
    const isNowSaved = toggleSaveVideo(video.id);
    if (isNowSaved) {
      showToast(`Saved "${video.title}" to your profile!`);
    } else {
      showToast(`Removed "${video.title}" from saved videos.`);
    }
  };

  // Filtering and sorting videos
  const filteredVideos = SOFIA_VIDEOS.filter((video) => {
    const matchesSearch =
      video.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      video.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      video.tags.some((tag) =>
        tag.toLowerCase().includes(searchQuery.toLowerCase()),
      );

    const matchesCategory =
      selectedCategory === "All" || video.category === selectedCategory;

    const matchesLevel =
      selectedLevel === "All" || video.level === selectedLevel;

    return matchesSearch && matchesCategory && matchesLevel;
  }).sort((a, b) => {
    if (sortBy === "popular") {
      return parseInt(b.views) - parseInt(a.views);
    }
    return b.id.localeCompare(a.id);
  });

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-[#120905] text-ink dark:text-parchment pb-20 transition-colors duration-300">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 bg-caramel text-white px-5 py-3 rounded-2xl shadow-xl animate-fade-in border border-amber-300/20">
          <CheckCircle2 size={18} />
          <span className="text-sm font-medium">{toastMessage}</span>
        </div>
      )}

      {/* Hero Header */}
      <div className="relative overflow-hidden bg-gradient-to-b from-amber-500/10 via-caramel/5 to-transparent pt-10 pb-8 px-4 sm:px-8 border-b border-taupe/10 dark:border-stone-850">
        <div className="max-w-7xl mx-auto text-center sm:text-left flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="space-y-3 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-caramel/15 text-caramel dark:text-amber-400 text-xs font-bold tracking-wide border border-caramel/20">
              <Sparkles size={14} />
              <span>Chef Sofia Masterclasses</span>
            </div>
            <h1 className="font-serif text-3xl sm:text-5xl font-bold tracking-tight text-ink dark:text-parchment">
              Learn with Sofia
            </h1>
            <p className="text-sm sm:text-base text-gray-600 dark:text-stone-300 leading-relaxed">
              Enhance your culinary expertise with video tutorials, technique breakdowns, and secret kitchen tips directly from Chef Sofia.
            </p>
          </div>

          <div className="flex items-center gap-4 bg-white dark:bg-[#1d120a] p-4 sm:p-5 rounded-3xl border border-taupe/15 dark:border-stone-800 shadow-sm shrink-0">
            <img
              src="https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&q=80&w=200"
              alt="Chef Sofia"
              className="w-14 h-14 rounded-full object-cover ring-2 ring-caramel/40"
            />
            <div>
              <div className="font-bold text-sm text-ink dark:text-parchment flex items-center gap-1.5">
                <span>Chef Sofia</span>
                <CheckCircle2 size={14} className="text-caramel fill-caramel/20" />
              </div>
              <p className="text-xs text-gray-500 dark:text-stone-400">Head Culinary Director</p>
              <span className="text-[11px] font-medium text-caramel dark:text-amber-400">
                {SOFIA_VIDEOS.length} Masterclass Videos Available
              </span>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-8 mt-8 space-y-6">
        {/* Search & Filter Controls */}
        <div className="space-y-4">
          <div className="flex flex-col md:flex-row items-center gap-3">
            {/* Search Input Bar */}
            <div className="relative flex-1 w-full">
              <Search
                size={18}
                className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 dark:text-stone-400 pointer-events-none"
              />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search videos by title, technique, or tag..."
                className="w-full pl-11 pr-10 py-3 rounded-2xl bg-white dark:bg-[#1c120c] border border-gray-200 dark:border-stone-800 text-sm text-ink dark:text-parchment focus:outline-none focus:ring-2 focus:ring-caramel/50 shadow-xs transition-colors"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery("")}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-stone-200"
                >
                  <X size={16} />
                </button>
              )}
            </div>

            {/* Level Filter pills */}
            <div className="flex items-center gap-1.5 w-full md:w-auto overflow-x-auto pb-1 md:pb-0 scrollbar-none">
              <span className="text-xs font-semibold text-gray-500 dark:text-stone-400 shrink-0 mr-1 flex items-center gap-1">
                <SlidersHorizontal size={13} /> Level:
              </span>
              {["All", "Beginner", "Intermediate", "Advanced"].map((level) => (
                <button
                  key={level}
                  onClick={() => setSelectedLevel(level)}
                  className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-colors cursor-pointer ${
                    selectedLevel === level
                      ? "bg-caramel text-white shadow-xs"
                      : "bg-white dark:bg-[#1c120c] text-gray-600 dark:text-stone-300 border border-gray-200 dark:border-stone-800 hover:bg-gray-100 dark:hover:bg-stone-800"
                  }`}
                >
                  {level}
                </button>
              ))}

              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as "popular" | "newest")}
                className="ml-2 px-3 py-1.5 rounded-full text-xs font-medium bg-white dark:bg-[#1c120c] text-gray-600 dark:text-stone-300 border border-gray-200 dark:border-stone-800 focus:outline-none focus:ring-1 focus:ring-caramel/50 cursor-pointer"
              >
                <option value="popular">Most Popular</option>
                <option value="newest">Newest First</option>
              </select>
            </div>
          </div>

          {/* Category Horizontal Scroll Bar */}
          <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none">
            {SOFIA_CATEGORIES.map((category) => {
              const isActive = selectedCategory === category;
              return (
                <button
                  key={category}
                  onClick={() => setSelectedCategory(category)}
                  className={`px-4 py-2 rounded-2xl text-xs font-semibold whitespace-nowrap transition-all duration-200 cursor-pointer ${
                    isActive
                      ? "bg-ink dark:bg-parchment text-white dark:text-ink shadow-md"
                      : "bg-white dark:bg-[#1c120c] text-gray-700 dark:text-stone-300 border border-gray-200 dark:border-stone-850 hover:bg-gray-100 dark:hover:bg-stone-800"
                  }`}
                >
                  {category}
                </button>
              );
            })}
          </div>
        </div>

        {/* Video Count & Header Bar */}
        <div className="flex items-center justify-between text-xs text-gray-500 dark:text-stone-400 border-b border-taupe/10 dark:border-stone-850 pb-3">
          <span>
            Showing <strong className="text-ink dark:text-parchment">{filteredVideos.length}</strong> videos
          </span>
          {savedVideoIds.length > 0 && (
            <span className="text-caramel dark:text-amber-400 font-medium">
              ★ {savedVideoIds.length} video{savedVideoIds.length > 1 ? "s" : ""} saved to your profile
            </span>
          )}
        </div>

        {/* Video Grid */}
        {filteredVideos.length === 0 ? (
          <div className="bg-white dark:bg-[#1c120c] rounded-3xl p-12 text-center border border-taupe/10 dark:border-stone-800 space-y-4 my-8">
            <BookOpen size={48} className="mx-auto text-gray-300 dark:text-stone-700" />
            <h3 className="font-serif text-lg font-bold text-ink dark:text-parchment">
              No cooking videos found
            </h3>
            <p className="text-xs text-gray-500 dark:text-stone-400 max-w-sm mx-auto">
              We couldn't find any videos matching "{searchQuery}". Try searching for another technique or clear your filters.
            </p>
            <button
              onClick={() => {
                setSearchQuery("");
                setSelectedCategory("All");
                setSelectedLevel("All");
              }}
              className="px-4 py-2 rounded-xl bg-caramel text-white text-xs font-semibold shadow-md hover:bg-caramel-dark transition-colors cursor-pointer"
            >
              Reset Filters
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredVideos.map((video) => {
              const isSaved = savedVideoIds.includes(video.id);

              return (
                <div
                  key={video.id}
                  onClick={() => setActiveVideoModal(video)}
                  className="group bg-white dark:bg-[#1c120c] rounded-3xl overflow-hidden border border-taupe/10 dark:border-stone-850 hover:border-caramel/40 dark:hover:border-caramel/40 shadow-xs hover:shadow-xl transition-all duration-300 flex flex-col cursor-pointer"
                >
                  {/* Thumbnail Container */}
                  <div className="relative aspect-video w-full overflow-hidden bg-black/10">
                    <img
                      src={video.thumbnailUrl}
                      alt={video.title}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />

                    {/* Play button overlay on hover */}
                    <div className="absolute inset-0 bg-black/30 group-hover:bg-black/50 transition-colors flex items-center justify-center">
                      <div className="w-12 h-12 rounded-full bg-caramel/90 text-white flex items-center justify-center shadow-lg transform group-hover:scale-110 transition-transform">
                        <Play size={22} className="ml-1 fill-white" />
                      </div>
                    </div>

                    {/* Duration badge */}
                    <div className="absolute bottom-2.5 right-2.5 px-2 py-0.5 rounded-md bg-black/80 text-white text-[11px] font-medium tracking-wide flex items-center gap-1">
                      <Clock size={11} />
                      <span>{video.duration}</span>
                    </div>

                    {/* Category Pill */}
                    <div className="absolute top-2.5 left-2.5 px-2.5 py-1 rounded-full bg-black/60 backdrop-blur-md text-white text-[10px] font-semibold uppercase tracking-wider">
                      {video.category}
                    </div>

                    {/* Bookmark / Save Button */}
                    <button
                      onClick={(e) => handleToggleSave(video, e)}
                      title={isSaved ? "Saved" : "Save video"}
                      className={`absolute top-2.5 right-2.5 p-2 rounded-full backdrop-blur-md transition-all cursor-pointer shadow-md ${
                        isSaved
                          ? "bg-caramel text-white scale-105"
                          : "bg-black/50 hover:bg-caramel text-white"
                      }`}
                    >
                      {isSaved ? <BookmarkCheck size={16} className="fill-white" /> : <Bookmark size={16} />}
                    </button>
                  </div>

                  {/* Video Meta Content */}
                  <div className="p-4 flex-1 flex flex-col justify-between space-y-3">
                    <div className="space-y-2">
                      <div className="flex items-center gap-2">
                        <img
                          src={video.channelAvatar}
                          alt={video.channelName}
                          className="w-6 h-6 rounded-full object-cover border border-amber-500/20"
                        />
                        <span className="text-xs text-gray-500 dark:text-stone-400 font-medium">
                          {video.channelName}
                        </span>
                      </div>
                      <h3 className="font-serif text-sm font-bold text-ink dark:text-parchment line-clamp-2 leading-snug group-hover:text-caramel transition-colors">
                        {video.title}
                      </h3>
                      <p className="text-xs text-gray-500 dark:text-stone-400 line-clamp-2 leading-relaxed">
                        {video.description}
                      </p>
                    </div>

                    <div className="pt-2 border-t border-taupe/10 dark:border-stone-850 flex items-center justify-between text-[11px] text-gray-400 dark:text-stone-500">
                      <span className="flex items-center gap-1">
                        <Eye size={12} /> {video.views}
                      </span>
                      <span>{video.uploadedAt}</span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Embedded YouTube Player Modal */}
      {activeVideoModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
          <div className="bg-white dark:bg-[#1c120c] rounded-3xl max-w-4xl w-full max-h-[90vh] overflow-y-auto border border-taupe/20 dark:border-stone-800 shadow-2xl relative flex flex-col">
            {/* Modal Header */}
            <div className="p-4 sm:p-5 flex items-center justify-between border-b border-taupe/10 dark:border-stone-850 sticky top-0 bg-white/95 dark:bg-[#1c120c]/95 backdrop-blur-md z-10">
              <div className="flex items-center gap-3">
                <img
                  src={activeVideoModal.channelAvatar}
                  alt={activeVideoModal.channelName}
                  className="w-8 h-8 rounded-full object-cover ring-2 ring-caramel/30"
                />
                <div>
                  <h3 className="font-bold text-sm sm:text-base text-ink dark:text-parchment line-clamp-1">
                    {activeVideoModal.title}
                  </h3>
                  <p className="text-xs text-gray-500 dark:text-stone-400">
                    {activeVideoModal.channelName} • {activeVideoModal.category}
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => handleToggleSave(activeVideoModal)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer ${
                    savedVideoIds.includes(activeVideoModal.id)
                      ? "bg-caramel text-white"
                      : "bg-gray-100 dark:bg-stone-800 text-gray-700 dark:text-stone-300 hover:bg-caramel hover:text-white"
                  }`}
                >
                  {savedVideoIds.includes(activeVideoModal.id) ? (
                    <>
                      <BookmarkCheck size={14} className="fill-white" />
                      <span>Saved</span>
                    </>
                  ) : (
                    <>
                      <Bookmark size={14} />
                      <span>Save Video</span>
                    </>
                  )}
                </button>
                <button
                  onClick={() => setActiveVideoModal(null)}
                  className="p-2 rounded-full hover:bg-gray-100 dark:hover:bg-stone-800 text-gray-500 dark:text-stone-400 transition-colors cursor-pointer"
                >
                  <X size={20} />
                </button>
              </div>
            </div>

            {/* YouTube Embedded Video Player Container */}
            <div className="relative aspect-video w-full bg-black">
              <iframe
                src={`https://www.youtube.com/embed/${activeVideoModal.youtubeId}?autoplay=1`}
                title={activeVideoModal.title}
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen
                className="w-full h-full border-0"
              />
            </div>

            {/* Video Details & Meta Info */}
            <div className="p-6 space-y-4">
              <div className="flex flex-wrap items-center justify-between gap-4 border-b border-taupe/10 dark:border-stone-850 pb-4">
                <div>
                  <h2 className="font-serif text-lg font-bold text-ink dark:text-parchment">
                    {activeVideoModal.title}
                  </h2>
                  <div className="flex items-center gap-3 text-xs text-gray-500 dark:text-stone-400 mt-1">
                    <span>{activeVideoModal.views}</span>
                    <span>•</span>
                    <span>{activeVideoModal.uploadedAt}</span>
                    <span>•</span>
                    <span className="px-2 py-0.5 rounded-md bg-amber-500/10 text-amber-600 dark:text-amber-400 font-semibold">
                      {activeVideoModal.level}
                    </span>
                  </div>
                </div>
              </div>

              {/* Description */}
              <div className="space-y-2">
                <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400 dark:text-stone-500">
                  About this tutorial
                </h4>
                <p className="text-sm text-gray-700 dark:text-stone-300 leading-relaxed whitespace-pre-line">
                  {activeVideoModal.description}
                </p>
              </div>

              {/* Tags */}
              <div className="flex flex-wrap gap-2 pt-2">
                {activeVideoModal.tags.map((tag) => (
                  <span
                    key={tag}
                    className="px-2.5 py-1 rounded-lg bg-gray-100 dark:bg-stone-800/80 text-xs text-gray-600 dark:text-stone-400"
                  >
                    #{tag}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
