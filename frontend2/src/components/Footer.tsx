import { Link } from "react-router-dom";

export const Footer = () => {
  const currentYear = new Date().getFullYear();

  const socialLinks = [
    {
      name: "X (Twitter)",
      url: "https://x.com",
      icon: (
        <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
        </svg>
      )
    },
    {
      name: "Discord",
      url: "https://discord.com",
      icon: (
        <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.46-.63.874-1.295 1.226-1.994.021-.041.001-.09-.041-.106a13.094 13.094 0 0 1-1.873-.894.077.077 0 0 1-.008-.128c.126-.093.252-.19.372-.287a.075.075 0 0 1 .077-.011c3.92 1.793 8.18 1.793 12.061 0a.073.073 0 0 1 .078.009c.12.099.246.195.373.289a.075.075 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.894.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.156-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.156 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.156-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.156 2.418z" />
        </svg>
      )
    },
    {
      name: "LinkedIn",
      url: "https://linkedin.com",
      icon: (
        <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0z" />
        </svg>
      )
    },
    {
      name: "Instagram",
      url: "https://instagram.com",
      icon: (
        <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.051.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 1 0 0 12.324 6.162 6.162 0 0 0 0-12.324zM12 16a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm6.406-11.845a1.44 1.44 0 1 0 0 2.881 1.44 1.44 0 0 0 0-2.881z" />
        </svg>
      )
    },
    {
      name: "YouTube",
      url: "https://youtube.com",
      icon: (
        <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path d="M23.498 6.163a3.003 3.003 0 0 0-2.11-2.11C19.517 3.545 12 3.545 12 3.545s-7.517 0-9.388.508a3.003 3.003 0 0 0-2.11 2.11C0 8.033 0 12 0 12s0 3.967.502 5.837a3.003 3.003 0 0 0 2.11 2.11c1.871.508 9.388.508 9.388.508s7.517 0 9.388-.508a3.003 3.003 0 0 0 2.11-2.11C24 15.967 24 12 24 12s0-3.967-.502-5.837zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
        </svg>
      )
    }
  ];

  const linkColumns = [
    {
      title: "Recipes",
      links: [
        { label: "Browse Library", to: "/browse" },
        { label: "Trending Dishes", to: "/browse?sort=trending" },
        { label: "Special Diets", to: "/browse?tab=categories" },
        { label: "Category Explorer", to: "/browse?tab=categories" }
      ]
    },
    {
      title: "Planner",
      links: [
        { label: "Meal Plan Builder", to: "/meal-plans" },
        { label: "Shopping Lists", to: "/shopping-list" },
        { label: "Nutritional Guide", to: "/browse" },
        { label: "My Collections", to: "/profile" }
      ]
    },
    {
      title: "Creators",
      links: [
        { label: "Dashboard", to: "/creator" },
        { label: "Partner Program", to: "/creator" },
        { label: "Chef Spotlights", to: "/browse" },
        { label: "Submit Recipes", to: "/creator" }
      ]
    },
    {
      title: "Company",
      links: [
        { label: "About Caramel", to: "#" },
        { label: "Careers", to: "#" },
        { label: "Logos and Media", to: "#" },
        { label: "Changelog", to: "#" },
        { label: "Feature Requests", to: "#" }
      ]
    },
    {
      title: "Support",
      links: [
        { label: "Support Docs", to: "#" },
        { label: "Contact Us", to: "#" },
        { label: "Join Discord", to: "https://discord.com" },
        { label: "Community Forum", to: "#" }
      ]
    }
  ];

  return (
    <footer className="mt-24 border-t border-taupe/15 dark:border-stone-850/60 bg-white dark:bg-[#120905] pt-16 pb-8 font-sans transition-colors duration-300">
      <div className="mx-auto max-w-7xl px-6 sm:px-8 lg:px-12 space-y-12">

        {/* Main Columns Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-7 gap-10">

          {/* Logo & Brand Details (Left Column) */}
          <div className="lg:col-span-2 space-y-6 flex flex-col items-start">
            <Link to="/" className="font-display text-2xl sm:text-3xl italic text-ink transition-colors shrink-0">
              Caramel Kitchen
            </Link>

            <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400 leading-relaxed max-w-[280px]">
              Unleash your inner chef with customized meal plans, smart shopping lists, and detailed nutritional tracking.
            </p>

            {/* Social Icons row */}
            <div className="flex items-center gap-4 text-gray-400 dark:text-gray-500">
              {socialLinks.map((social) => (
                <a
                  key={social.name}
                  href={social.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-caramel dark:hover:text-caramel transition-colors duration-200"
                  aria-label={social.name}
                >
                  {social.icon}
                </a>
              ))}
            </div>

            {/* Pulse Operational status badge */}
            <div className="pt-2">
              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full border border-emerald-500/10 dark:border-emerald-500/20 bg-emerald-50/50 dark:bg-emerald-950/10 text-[11px] font-semibold text-emerald-700 dark:text-emerald-400 shadow-3xs">
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                </span>
                All systems operational
              </div>
            </div>
          </div>

          {/* Right Links Columns */}
          <div className="lg:col-span-5 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-8">
            {linkColumns.map((col) => (
              <div key={col.title} className="space-y-4">
                <h4 className="text-xs font-bold uppercase tracking-wider text-ink">
                  {col.title}
                </h4>
                <ul className="space-y-2.5">
                  {col.links.map((link) => (
                    <li key={link.label}>
                      {link.to.startsWith("http") || link.to === "#" ? (
                        <a
                          href={link.to}
                          className="text-xs text-gray-500 dark:text-gray-400 hover:text-caramel dark:hover:text-caramel transition-colors duration-200"
                        >
                          {link.label}
                        </a>
                      ) : (
                        <Link
                          to={link.to}
                          className="text-xs text-gray-500 dark:text-gray-400 hover:text-caramel dark:hover:text-caramel transition-colors duration-200"
                        >
                          {link.label}
                        </Link>
                      )}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>

        </div>

        {/* Divider */}
        <hr className="border-taupe/10 dark:border-stone-850/50" />

        {/* Bottom Credits Bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-6 pt-4 text-xs text-gray-400 dark:text-gray-500">
          <p>
            © {currentYear} Caramel Kitchen. All rights reserved.
          </p>
          <div className="flex items-center gap-6 font-semibold text-gray-500 dark:text-gray-400">
            <a href="#" className="hover:text-caramel dark:hover:text-caramel transition-colors duration-200">
              Privacy Policy
            </a>
            <a href="#" className="hover:text-caramel dark:hover:text-caramel transition-colors duration-200">
              Terms of Service
            </a>
            <a href="#" className="hover:text-caramel dark:hover:text-caramel transition-colors duration-200">
              Code of Conduct
            </a>
          </div>
        </div>

      </div>
    </footer>
  );
};
