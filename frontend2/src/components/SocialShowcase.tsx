export function SocialShowcase() {
  const socialChannels = [
    {
      name: "YouTube",
      handle: "@CaramelKitchen",
      description: "Step-by-step masterclasses, recipe breakdowns, and kitchen tours.",
      cta: "Subscribe on YouTube",
      url: "https://youtube.com",
      accentClass: "hover:bg-[#ff0000]/5 hover:border-[#ff0000]/30 dark:hover:bg-[#ff0000]/10",
      ctaBgClass: "bg-[#ff0000] text-white hover:bg-[#cc0000]",
      icon: (
        <div className="w-12 h-12 bg-[#ff0000]/10 rounded-2xl flex items-center justify-center text-[#ff0000] shrink-0">
          <svg className="w-6 h-6 fill-current" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M23.498 6.163a3.003 3.003 0 0 0-2.11-2.11C19.517 3.545 12 3.545 12 3.545s-7.517 0-9.388.508a3.003 3.003 0 0 0-2.11 2.11C0 8.033 0 12 0 12s0 3.967.502 5.837a3.003 3.003 0 0 0 2.11 2.11c1.871.508 9.388.508 9.388.508s7.517 0 9.388-.508a3.003 3.003 0 0 0 2.11-2.11C24 15.967 24 12 24 12s0-3.967-.502-5.837zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
          </svg>
        </div>
      )
    },
    {
      name: "Instagram",
      handle: "@caramel_kitchen",
      description: "Daily cooking inspiration, aesthetic plating, and quick reels.",
      cta: "Follow on Instagram",
      url: "https://instagram.com",
      accentClass: "hover:bg-gradient-to-tr hover:from-yellow-500/5 hover:via-pink-500/5 hover:to-purple-500/5 hover:border-pink-500/30 dark:hover:from-yellow-500/10 dark:hover:via-pink-500/10 dark:hover:to-purple-500/10",
      ctaBgClass: "bg-gradient-to-r from-yellow-500 via-pink-500 to-purple-600 text-white hover:opacity-90",
      icon: (
        <div className="w-12 h-12 bg-gradient-to-tr from-yellow-500/10 via-pink-500/10 to-purple-500/10 rounded-2xl flex items-center justify-center text-pink-600 shrink-0">
          <svg className="w-6 h-6 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <rect x="2" y="2" width="20" height="20" rx="5" ry="5" />
            <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z" />
            <line x1="17.5" y1="6.5" x2="17.51" y2="6.5" />
          </svg>
        </div>
      )
    },
    {
      name: "TikTok",
      handle: "@caramelkitchen",
      description: "Quick cooking hacks, viral kitchen trends, and behind-the-scenes fun.",
      cta: "Follow on TikTok",
      url: "https://tiktok.com",
      accentClass: "hover:bg-[#000000]/5 dark:hover:bg-[#ffffff]/5 hover:border-stone-400/40 dark:hover:border-stone-700/60",
      ctaBgClass: "bg-stone-900 text-white dark:bg-white dark:text-black hover:bg-stone-800 dark:hover:bg-stone-100",
      icon: (
        <div className="w-12 h-12 bg-stone-100 dark:bg-stone-800 rounded-2xl flex items-center justify-center text-stone-900 dark:text-white shrink-0 relative">
          {/* TikTok custom SVG logo */}
          <svg className="w-6 h-6 fill-current" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.02 1.63 4.14.99 1.11 2.37 1.77 3.86 1.95v3.91a8.775 8.775 0 0 1-5.11-1.68c-.16-.12-.3-.26-.45-.4v6.81a7.275 7.275 0 0 1-1.44 4.38 7.375 7.375 0 0 1-5.83 2.89 7.375 7.375 0 0 1-5.83-2.89 7.275 7.275 0 0 1-1.44-4.38 7.31 7.31 0 0 1 3.25-6.12 7.23 7.23 0 0 1 6.42-.56v4.06c-.84-.46-1.85-.5-2.73-.08a3.259 3.259 0 0 0-1.86 2.7c-.12.98.24 1.97.94 2.66.7.69 1.69 1.02 2.67.87 1-.15 1.83-.87 2.11-1.85.08-.29.11-.6.11-.9V.02Z" />
          </svg>
        </div>
      )
    }
  ];

  return (
    <section className="py-2 px-4 sm:px-6 lg:px-8 font-sans">
      <div className="bg-white dark:bg-[#1d120a]/30 border border-taupe/10 dark:border-caramel/30 rounded-3xl p-8 sm:p-12 relative overflow-hidden transition-all duration-300 shadow-2xs">

        {/* Abstract Background Accents */}
        <div className="absolute top-0 right-0 w-64 h-64 bg-caramel/5 rounded-full filter blur-3xl pointer-events-none -mr-20 -mt-20" />
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-caramel/5 rounded-full filter blur-3xl pointer-events-none -ml-20 -mb-20" />

        <div className="relative z-10 space-y-12">
          {/* Header */}
          <div className="max-w-2xl text-left space-y-4">
            <h2 className="font-serif text-3xl sm:text-4xl font-extrabold tracking-tight text-ink">
              Join Our Culinary Community
            </h2>
            <p className="text-sm sm:text-base text-gray-500 dark:text-gray-400">
              Get your daily dose of cooking inspiration. Follow us for quick chef hacks, community recipe challenges, and live interactive cook-alongs.
            </p>
          </div>

          {/* Social Columns Grid */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {socialChannels.map((channel) => (
              <a
                key={channel.name}
                href={channel.url}
                target="_blank"
                rel="noopener noreferrer"
                className={`group flex flex-col justify-between p-6 bg-gray-50/50 dark:bg-[#120905]/40 border border-taupe/5 dark:border-caramel/20 rounded-2xl transition-all duration-300 ${channel.accentClass}`}
              >
                <div className="space-y-4">
                  <div className="flex items-center gap-4">
                    {channel.icon}
                    <div>
                      <h3 className="font-serif text-lg font-bold text-ink dark:text-white leading-tight">
                        {channel.name}
                      </h3>
                      <p className="text-xs text-gray-400 font-semibold mt-0.5">
                        {channel.handle}
                      </p>
                    </div>
                  </div>
                  {/* <p className="text-xs sm:text-sm text-gray-600 dark:text-stone-300 leading-relaxed min-h-[48px]">
                    {channel.description}
                  </p> */}
                </div>

                <div className="mt-6">
                  <span className={`inline-flex w-full items-center justify-center px-4 py-2.5 rounded-full text-xs font-bold tracking-wide transition-all shadow-xs cursor-pointer ${channel.ctaBgClass}`}>
                    {channel.cta}
                  </span>
                </div>
              </a>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
