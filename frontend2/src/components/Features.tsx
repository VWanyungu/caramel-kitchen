import { Link } from "react-router-dom";
import { ClipboardList, Apple, Bookmark, Calendar, ArrowRight } from "lucide-react";

export function Features() {
  const featureItems = [
    {
      id: "shopping-list",
      badge: "Organized Shopping",
      title: "Save Hours with Smart Shopping Lists",
      description: "Consolidate ingredients from your chosen recipes into a single, organized list. Grouped automatically by supermarket aisle to make your shopping trips efficient and stress-free.",
      linkText: "Create a list",
      linkUrl: "/shopping-list",
      icon: ClipboardList,
      bgColorClass: "bg-[#fff8f2] dark:bg-[#1f150f] border-caramel/10 dark:border-caramel/20",
      badgeColorClass: "text-[#c8862b] bg-white dark:bg-[#2b1e15] border-[#f0dfd0]  dark:border-none",
      linkColorClass: "text-[#c8862b] border-[#c8862b]/20 hover:border-[#c8862b]",
      arrowColor: "text-[#c8862b]",
      // Decorative SVG for bottom right
      svgDecor: (
        <svg className="absolute right-0 bottom-0 w-44 h-44 opacity-25 dark:opacity-15 pointer-events-none transition-transform duration-500 group-hover:scale-105" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="50" y="20" width="30" height="30" rx="8" transform="rotate(45 50 20)" fill="url(#orange-grad)" />
          <rect x="75" y="45" width="24" height="24" rx="6" transform="rotate(45 75 45)" fill="url(#orange-grad)" />
          <rect x="25" y="45" width="24" height="24" rx="6" transform="rotate(45 25 45)" fill="url(#orange-grad)" />
          <rect x="50" y="70" width="30" height="30" rx="8" transform="rotate(45 50 70)" fill="url(#orange-grad)" />
          <defs>
            <linearGradient id="orange-grad" x1="50" y1="20" x2="50" y2="100" gradientUnits="userSpaceOnUse">
              <stop stopColor="#e89e3a" />
              <stop offset="1" stopColor="#e8b94a" stopOpacity="0.2" />
            </linearGradient>
          </defs>
        </svg>
      )
    },
    {
      id: "nutrition",
      badge: "Nutritional Insights",
      title: "Know Exactly What You Eat",
      description: "Track calories, macro splits, and allergen flags for every recipe. Serving sizes scale automatically so you can cook exactly what fits your dietary targets.",
      linkText: "Explore healthy options",
      linkUrl: "/browse",
      icon: Apple,
      bgColorClass: "bg-[#f4f8ff] dark:bg-[#0c1424] border-blue-200/40 dark:border-blue-900/30",
      badgeColorClass: "text-blue-600 dark:text-blue-400 bg-white dark:bg-[#121c33] border-blue-100 dark:border-none",
      linkColorClass: "text-blue-600 dark:text-blue-400 border-blue-600/20 dark:border-blue-400/20 hover:border-blue-600 dark:hover:border-blue-400",
      arrowColor: "text-blue-600 dark:text-blue-400",
      svgDecor: (
        <svg className="absolute right-0 bottom-0 w-44 h-44 opacity-25 dark:opacity-15 pointer-events-none transition-transform duration-500 group-hover:scale-105" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
          <circle cx="75" cy="75" r="40" stroke="url(#blue-grad)" strokeWidth="6" />
          <circle cx="75" cy="75" r="28" stroke="url(#blue-grad)" strokeWidth="4" strokeDasharray="4 4" />
          <circle cx="75" cy="75" r="16" fill="url(#blue-grad)" />
          <defs>
            <linearGradient id="blue-grad" x1="35" y1="35" x2="75" y2="115" gradientUnits="userSpaceOnUse">
              <stop stopColor="#3b82f6" />
              <stop offset="1" stopColor="#60a5fa" stopOpacity="0.1" />
            </linearGradient>
          </defs>
        </svg>
      )
    },
    {
      id: "save-recipes",
      badge: "Digital Cookbook",
      title: "Collect Your Favorite Recipes",
      description: "Build your personal library of culinary creations. Save expert chef guides, add your own customizations, tag recipes, and search your collection in seconds.",
      linkText: "Browse recipes",
      linkUrl: "/browse",
      icon: Bookmark,
      bgColorClass: "bg-[#faf6fe] dark:bg-[#140e24] border-purple-200/40 dark:border-purple-900/30",
      badgeColorClass: "text-purple-600 dark:text-purple-400 bg-white dark:bg-[#1b1433] border-purple-100 dark:border-none",
      linkColorClass: "text-purple-600 dark:text-purple-400 border-purple-600/20 dark:border-purple-400/20 hover:border-purple-600 dark:hover:border-purple-400",
      arrowColor: "text-purple-600 dark:text-purple-400",
      svgDecor: (
        <svg className="absolute right-0 bottom-0 w-44 h-44 opacity-25 dark:opacity-15 pointer-events-none transition-transform duration-500 group-hover:scale-105" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M40 90C40 62.3858 62.3858 40 90 40" stroke="url(#purple-grad)" strokeWidth="8" strokeLinecap="round" />
          <path d="M60 90C60 73.4315 73.4315 60 90 60" stroke="url(#purple-grad)" strokeWidth="5" strokeLinecap="round" />
          <path d="M80 90C80 84.4772 84.4772 80 90 80" stroke="url(#purple-grad)" strokeWidth="2" strokeLinecap="round" />
          <defs>
            <linearGradient id="purple-grad" x1="40" y1="40" x2="90" y2="90" gradientUnits="userSpaceOnUse">
              <stop stopColor="#a855f7" />
              <stop offset="1" stopColor="#c084fc" stopOpacity="0.1" />
            </linearGradient>
          </defs>
        </svg>
      )
    },
    {
      id: "meal-plans",
      badge: "Meal Planner",
      title: "Plan Your Week with Precision",
      description: "Draft custom weekly meal plans that adapt to your serving requirements and calorie goals. Balance your diet, coordinate prep times, and make healthy eating simple.",
      linkText: "Start planning",
      linkUrl: "/meal-plans",
      icon: Calendar,
      bgColorClass: "bg-[#f2faf5] dark:bg-[#091510] border-emerald-200/40 dark:border-emerald-900/30",
      badgeColorClass: "text-emerald-600 dark:text-emerald-400 bg-white dark:bg-[#0f2119] border-emerald-100 dark:border-none",
      linkColorClass: "text-emerald-600 dark:text-emerald-400 border-emerald-600/20 dark:border-emerald-400/20 hover:border-emerald-600 dark:hover:border-emerald-400",
      arrowColor: "text-emerald-600 dark:text-emerald-400",
      svgDecor: (
        <svg className="absolute right-0 bottom-0 w-44 h-44 opacity-25 dark:opacity-15 pointer-events-none transition-transform duration-500 group-hover:scale-105" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M50 15L85 50L50 85L15 50Z" stroke="url(#green-grad)" strokeWidth="6" strokeLinejoin="round" />
          <path d="M50 32L68 50L50 68L32 50Z" stroke="url(#green-grad)" strokeWidth="3" strokeLinejoin="round" strokeDasharray="3 3" />
          <circle cx="50" cy="50" r="6" fill="url(#green-grad)" />
          <defs>
            <linearGradient id="green-grad" x1="15" y1="15" x2="85" y2="85" gradientUnits="userSpaceOnUse">
              <stop stopColor="#10b981" />
              <stop offset="1" stopColor="#34d399" stopOpacity="0.1" />
            </linearGradient>
          </defs>
        </svg>
      )
    }
  ];

  return (
    <section className="py-16 px-4 sm:px-6 lg:px-8 font-sans">
      <div className="text-center max-w-3xl mx-auto mb-16 space-y-4">
        <h2 className="font-serif text-3xl sm:text-4xl font-extrabold tracking-tight text-ink animate-fade-in">
          Supercharge Your Culinary Routine
        </h2>
        <p className="text-sm sm:text-base text-gray-500 dark:text-gray-400">
          Everything you need to plan meals, cook smart, track nutrition, and keep your kitchen running seamlessly.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-6xl mx-auto">
        {featureItems.map((item) => {
          const Icon = item.icon;
          return (
            <div
              key={item.id}
              className={`group relative overflow-hidden rounded-3xl border p-8 sm:p-10 flex flex-col justify-between min-h-[300px] sm:min-h-[320px] transition-all duration-300 hover:-translate-y-1 hover:shadow-md ${item.bgColorClass}`}
            >
              {/* Decorative shapes background */}
              {item.svgDecor}

              {/* Card Content */}
              <div className="space-y-6 relative z-10">
                {/* Header Badge */}
                <div className="flex">
                  <div className={`inline-flex items-center gap-1.5 px-3.5 py-1 rounded-full text-xs font-bold border tracking-wide uppercase shadow-2xs ${item.badgeColorClass}`}>
                    <Icon size={12} className="shrink-0" />
                    {item.badge}
                  </div>
                </div>

                {/* Text section */}
                <div className="space-y-3">
                  <h3 className="font-serif text-xl sm:text-2xl font-bold tracking-tight text-ink dark:text-white leading-tight">
                    {item.title}
                  </h3>
                  <p className="text-xs sm:text-sm text-gray-600 dark:text-stone-300 leading-relaxed max-w-[90%]">
                    {item.description}
                  </p>
                </div>
              </div>

              {/* Footer CTA link */}
              <div className="pt-6 relative z-10">
                <Link
                  to={item.linkUrl}
                  className={`inline-flex items-center gap-1 text-xs sm:text-sm font-bold tracking-wide transition-all border-b pb-0.5 ${item.linkColorClass}`}
                >
                  {item.linkText}
                  <ArrowRight
                    size={14}
                    className={`transition-transform duration-200 group-hover:translate-x-1 ${item.arrowColor}`}
                  />
                </Link>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
