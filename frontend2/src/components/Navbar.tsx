import {
  Compass,
  Moon,
  Plus,
  Sparkles,
  ChefHat,
  Sun,
  User,
  ClipboardList,
  Search,
  X,
  Diamond,
  ChevronDown,
  Utensils,
  Menu,
  LogOut,
  LogIn,
  UserPlus, Book, BookOpen
} from "lucide-react";
import { useEffect, useState } from "react";
import {
  Link,
  useLocation,
  useNavigate,
  useSearchParams,
} from "react-router-dom";
import { useAuth } from "../auth/useAuth";
import { usePremiumModal } from "../context/PremiumModalContext";
import { useNavigation } from "../context/NavigationContext";
import { Button } from "./ui";

export function Navbar() {
  const { status, user, isCreator, logout } = useAuth();
  const { openPremiumModal, isPremium } = usePremiumModal();
  const { isMobileMenuOpen, toggleMobileMenu, closeMobileMenu } =
    useNavigation();

  const navigate = useNavigate();
  const { pathname } = useLocation();
  const [searchParams, setSearchParams] = useSearchParams();
  const qParam = searchParams.get("q") || "";

  // Navbar search state
  const [searchVal, setSearchVal] = useState(qParam);
  const [isScrolledPastFilter, setIsScrolledPastFilter] = useState(false);

  // Sync searchVal with URL search param
  useEffect(() => {
    setSearchVal(qParam);
  }, [qParam]);

  // Monitor whether user has scrolled past filter bar on browse page
  useEffect(() => {
    if (pathname !== "/browse") {
      setIsScrolledPastFilter(false);
      return;
    }

    const checkVisibility = () => {
      const el = document.getElementById("browse-filter-bar");
      if (el) {
        const rect = el.getBoundingClientRect();
        // Sticky header height is ~70px. When the bottom of the filter bar passes above it:
        setIsScrolledPastFilter(rect.bottom <= 70);
      } else {
        setIsScrolledPastFilter(false);
      }
    };

    window.addEventListener("scroll", checkVisibility, { passive: true });
    checkVisibility();

    return () => {
      window.removeEventListener("scroll", checkVisibility);
    };
  }, [pathname]);

  const showNavbarSearch = pathname !== "/recipes" || isScrolledPastFilter;

  const handleSearchChange = (val: string) => {
    setSearchVal(val);
    if (pathname === "/browse") {
      setSearchParams((prev) => {
        if (val) {
          prev.set("q", val);
        } else {
          prev.delete("q");
        }
        return prev;
      });
    }
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (pathname !== "/browse") {
      navigate(`/browse?q=${encodeURIComponent(searchVal)}`);
    }
  };

  // Theme state
  const [theme, setTheme] = useState<"light" | "dark">(() => {
    if (typeof window !== "undefined") {
      const savedTheme = localStorage.getItem("theme");
      if (savedTheme === "dark" || savedTheme === "light") {
        return savedTheme;
      }
      return window.matchMedia("(prefers-color-scheme: dark)").matches
        ? "dark"
        : "light";
    }
    return "light";
  });

  useEffect(() => {
    if (theme === "dark") {
      document.documentElement.classList.add("dark");
      localStorage.setItem("theme", "dark");
    } else {
      document.documentElement.classList.remove("dark");
      localStorage.setItem("theme", "light");
    }
  }, [theme]);

  const toggleTheme = () => {
    setTheme((prev) => (prev === "light" ? "dark" : "light"));
  };

  const handleLogout = () => {
    logout();
    closeMobileMenu();
    navigate("/");
  };

  const isAuthenticated = status === "authenticated";

  const isHomeActive = pathname === "/";
  const isDiscoverActive = pathname === "/recipes";
  const isShoppingListActive =
    pathname === "/shopping-list" || pathname === "/cart";
  const isMealPlansActive = pathname === "/meal-plans";
  const isAiActive = pathname === "/ai";
  const isLearnActive = pathname === "/learn" || pathname === "/learn-with-sofia";
  const isCreatorActive = pathname === "/creator";
  const isCollectionsActive = pathname.startsWith("/collections");

  return (
    <>
      <header className="dark:border-taupe/10 bg-white dark:bg-[#120905] sticky top-0 z-30 transition-colors duration-300 border-b border-taupe/10 dark:border-stone-800/60">
        <nav className="mx-auto flex items-center justify-between px-4 sm:px-8 lg:px-16 py-3.5 lg:py-4 gap-3 lg:gap-4">
          {/* Left Side: Hamburger (Mobile) + Logo + Desktop Search */}
          <div className="flex-1 flex justify-start items-center gap-3 lg:gap-4 min-w-0">
            {/* Hamburger Button (Small Screens) */}
            <button
              type="button"
              onClick={toggleMobileMenu}
              className="lg:hidden p-2 -ml-1 text-ink dark:text-parchment hover:bg-gray-100 dark:hover:bg-stone-800/80 rounded-xl transition-colors cursor-pointer focus:outline-none focus:ring-2 focus:ring-caramel/50 shrink-0"
              aria-label="Toggle navigation menu"
              aria-expanded={isMobileMenuOpen}
              aria-controls="mobile-navigation-drawer"
            >
              <Menu size={22} />
            </button>

            {/* Logo */}
            <Link
              to="/"
              className="font-display text-xl sm:text-2xl italic text-ink dark:text-white transition-colors shrink-0 tracking-tight"
            >
              Caramel Kitchen
            </Link>

            {/* Desktop Search Bar */}
            {showNavbarSearch && (
              <form
                onSubmit={handleSearchSubmit}
                className="hidden lg:flex items-center bg-gray-50 dark:bg-stone-900 border border-taupe/15 dark:border-stone-800 rounded-full pl-6 pr-1 py-1 w-80 xl:w-96 gap-1 transition-all duration-200 focus-within:bg-white dark:focus-within:bg-stone-900 focus-within:border-caramel/30"
              >
                <input
                  type="text"
                  placeholder="What are you looking for?"
                  value={searchVal}
                  onChange={(e) => handleSearchChange(e.target.value)}
                  className="w-full text-xs bg-transparent border-none text-ink dark:text-parchment focus:outline-none placeholder:text-gray-400"
                />

                {searchVal && (
                  <button
                    type="button"
                    onClick={() => handleSearchChange("")}
                    className="text-gray-400 hover:text-ink dark:hover:text-white transition-colors cursor-pointer flex items-center pr-1"
                  >
                    <X size={12} />
                  </button>
                )}

                {/* Selector Option */}
                <div className="flex items-center gap-1 shrink-0 text-xs font-semibold text-gray-600 dark:text-gray-300 pr-2 border-r border-gray-200 dark:border-stone-800 select-none">
                  <span>Recipes</span>
                  <ChevronDown size={12} className="text-gray-400" />
                </div>

                {/* Pink Search Button */}
                <button
                  type="submit"
                  className="flex items-center justify-center bg-[#ec4899] hover:bg-[#db2777] text-white p-2 rounded-full cursor-pointer shadow-xs transition-colors shrink-0"
                  aria-label="Search"
                >
                  <Search size={14} />
                </button>
              </form>
            )}
          </div>

          {/* Center Nav Options (Large Screens Only) */}
          <div className="hidden lg:flex items-center gap-1 bg-gray-100/80 dark:bg-[#1d120a] p-1 rounded-full border border-taupe/15 dark:border-stone-800 shadow-xs transition-colors duration-300">
            <Link
              to="/"
              className={`flex items-center gap-2 px-3.5 xl:px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isHomeActive
                ? "bg-white dark:bg-[#120905] text-caramel dark:text-caramel shadow-xs"
                : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
                }`}
            >
              <ChefHat size={15} />
              <span>Home</span>
            </Link>

            <Link
              to="/recipes"
              className={`flex items-center gap-2 px-3.5 xl:px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isDiscoverActive
                ? "bg-white dark:bg-[#120905] text-caramel dark:text-caramel shadow-xs"
                : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
                }`}
            >
              <Compass size={15} />
              <span>Recipes</span>
            </Link>

            <Link
              to="/shopping-list"
              className={`flex items-center gap-2 px-3.5 xl:px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isShoppingListActive
                ? "bg-white dark:bg-[#120905] text-caramel dark:text-caramel shadow-xs"
                : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
                }`}
            >
              <ClipboardList size={15} />
              <span>Shopping List</span>
            </Link>

            <Link
              to="/meal-plans"
              onClick={(e) => {
                if (!isPremium) {
                  e.preventDefault();
                  openPremiumModal({
                    featureName: "Weekly Meal Planner",
                    featureDescription:
                      "Meal planning, macro balancing, and automated schedule generation are available exclusively on Caramel Bronze and Silver plans.",
                  });
                }
              }}
              className={`relative flex items-center gap-2 px-3.5 xl:px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isMealPlansActive
                ? "bg-white dark:bg-[#120905] text-caramel dark:text-caramel shadow-xs"
                : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
                }`}
            >
              <Utensils size={15} />
              <span>Meal Plans</span>
              <Diamond
                size={8}
                className="absolute top-0.5 right-1.5 text-amber-500 fill-amber-500"
              />
            </Link>

            <Link
              to="/collections"
              onClick={(e) => {
                if (!isPremium) {
                  e.preventDefault();
                  openPremiumModal({
                    featureName: "Premium Collections",
                    featureDescription:
                      "Access exclusive, expert-curated recipe and video collections with a Caramel Premium plan.",
                  });
                }
              }}
              className={`relative flex items-center gap-2 px-3.5 xl:px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isCollectionsActive
                ? "bg-white dark:bg-[#120905] text-caramel dark:text-caramel shadow-xs"
                : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
                }`}
            >
              <BookOpen size={15} />
              <span>Collections</span>
              <Diamond
                size={8}
                className="absolute top-0.5 right-1.5 text-amber-500 fill-amber-500"
              />
            </Link>

            <Link
              to="/learn"
              className={`relative flex items-center gap-2 px-3.5 xl:px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isLearnActive
                ? "bg-[#faf6f0] dark:bg-[#1d120a] text-caramel dark:text-amber-400 shadow-xs"
                : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
                }`}
            >
              <Book size={15} />
              <span>Learn with Sofia</span>
            </Link>

            <Link
              to="/ai"
              onClick={(e) => {
                if (!isPremium) {
                  e.preventDefault();
                  openPremiumModal({
                    featureName: "Caramel AI Chef",
                    featureDescription:
                      "Ask questions, swap ingredients, and get customized step-by-step guidance tailored to your kitchen using Caramel AI.",
                  });
                }
              }}
              className={`relative flex items-center gap-2 px-3.5 xl:px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isAiActive
                ? "bg-white dark:bg-[#120905] text-caramel dark:text-caramel shadow-xs"
                : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
                }`}
            >
              <Sparkles size={15} />
              <span>Smart Kitchen</span>
              <Diamond
                size={8}
                className="absolute top-0.5 right-1.5 text-amber-500 fill-amber-500"
              />
            </Link>

            <div className="h-4 w-px bg-gray-300 dark:bg-stone-800 mx-1" />

            <button
              onClick={toggleTheme}
              className="p-1.5 rounded-full text-gray-600 dark:text-gray-300 hover:bg-white dark:hover:bg-[#120905] hover:text-caramel dark:hover:text-caramel hover:shadow-xs transition-all duration-200 cursor-pointer"
              aria-label="Toggle dark/light mode"
            >
              {theme === "dark" ? <Sun size={15} /> : <Moon size={15} />}
            </button>
          </div>

          {/* Right Side Actions (Desktop + Mobile Quick Actions) */}
          <div className="flex justify-end items-center gap-2 sm:gap-3 font-sans text-sm shrink-0">
            {/* Desktop Actions */}
            <div className="hidden lg:flex items-center gap-3">
              {/* Upgrade to Premium CTA */}
              <Link to="/premium">
                <button className="gap-1 bg-amber-500 text-white font-semibold text-xs px-4 py-2.5 rounded-full flex items-center cursor-pointer shadow-xs transition-all duration-150 border border-amber-400/20">
                  <Diamond size={11} className="fill-white" />
                  <span>Go Premium</span>
                </button>
              </Link>

              {isAuthenticated ? (
                <>
                  {isCreator && (
                    <Link to="/creator">
                      <Button
                        variant="dark"
                        size="sm"
                        icon={<Plus size={16} />}
                      >
                        Create New
                      </Button>
                    </Link>
                  )}

                  <Button variant="dark" size="sm" onClick={handleLogout}>
                    Log out
                  </Button>

                  <Link
                    to="/profile"
                    className="relative flex items-center justify-center mx-1 cursor-pointer transition-transform hover:scale-105"
                    title={`${user?.name || "User"} (View Profile)`}
                  >
                    <div className="rounded-full ring-2 ring-emerald-500 ring-offset-2 ring-offset-white dark:ring-offset-[#120905] p-[1px] flex items-center justify-center">
                      {user?.avatar_url ? (
                        <img
                          src={user.avatar_url}
                          alt={user.name}
                          className="h-8 w-8 rounded-full object-cover"
                        />
                      ) : (
                        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-caramel/15 dark:bg-caramel/30 font-sans text-xs font-bold text-caramel dark:text-caramel uppercase">
                          {user?.name ? (
                            user.name.charAt(0)
                          ) : (
                            <User size={16} />
                          )}
                        </div>
                      )}
                    </div>
                    <span className="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full bg-emerald-500 ring-2 ring-white dark:ring-[#120905]" />
                  </Link>
                </>
              ) : (
                <>
                  <Link to="/login">
                    <Button variant="dark" size="sm" className="py-2.5">
                      Log in
                    </Button>
                  </Link>

                  <Link to="/signup">
                    <Button variant="dark" size="sm" className="py-2.5">
                      Sign up
                    </Button>
                  </Link>
                </>
              )}
            </div>

            {/* Mobile-Only Quick Bar (Theme toggle & Profile/Login shortcut) */}
            <div className="flex lg:hidden items-center gap-1.5 sm:gap-2">
              <button
                onClick={toggleTheme}
                className="p-2 rounded-xl text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-stone-800/80 transition-colors cursor-pointer"
                aria-label="Toggle dark/light mode"
              >
                {theme === "dark" ? <Sun size={18} /> : <Moon size={18} />}
              </button>

              {isAuthenticated ? (
                <Link
                  to="/profile"
                  className="relative flex items-center justify-center p-0.5 cursor-pointer"
                  title={`${user?.name || "User"} (View Profile)`}
                >
                  <div className="rounded-full ring-2 ring-emerald-500 ring-offset-2 ring-offset-white dark:ring-offset-[#120905] p-[1px] flex items-center justify-center">
                    {user?.avatar_url ? (
                      <img
                        src={user.avatar_url}
                        alt={user.name}
                        className="h-7 w-7 rounded-full object-cover"
                      />
                    ) : (
                      <div className="flex h-7 w-7 items-center justify-center rounded-full bg-caramel/15 dark:bg-caramel/30 font-sans text-xs font-bold text-caramel dark:text-caramel uppercase">
                        {user?.name ? user.name.charAt(0) : <User size={14} />}
                      </div>
                    )}
                  </div>
                  <span className="absolute bottom-0.5 right-0.5 h-2 w-2 rounded-full bg-emerald-500 ring-1.5 ring-white dark:ring-[#120905]" />
                </Link>
              ) : (
                <Link to="/login">
                  <Button variant="dark" size="sm">
                    Log in
                  </Button>
                </Link>
              )}
            </div>
          </div>
        </nav>
      </header>

      {/* Mobile Slide-in Menu Drawer (Sliding in from the Left) */}
      {/* Backdrop */}
      <div
        className={`fixed inset-0 bg-black/60 backdrop-blur-xs z-40 transition-opacity duration-300 lg:hidden ${isMobileMenuOpen
          ? "opacity-100 pointer-events-auto"
          : "opacity-0 pointer-events-none"
          }`}
        onClick={closeMobileMenu}
        aria-hidden="true"
      />

      {/* Drawer Container */}
      <aside
        id="mobile-navigation-drawer"
        aria-label="Mobile Navigation"
        aria-modal="true"
        role="dialog"
        className={`fixed inset-y-0 left-0 w-80 max-w-[85vw] z-50 bg-white dark:bg-[#150a06] border-r border-taupe/15 dark:border-stone-800 shadow-2xl flex flex-col justify-between overflow-y-auto transition-transform duration-300 ease-in-out lg:hidden ${isMobileMenuOpen ? "translate-x-0" : "-translate-x-full"
          }`}
      >
        <div className="flex flex-col p-5 gap-6">
          {/* Drawer Header */}
          <div className="flex items-center justify-between pb-4 border-b border-taupe/10 dark:border-stone-800">
            <Link
              to="/"
              onClick={closeMobileMenu}
              className="font-display text-2xl italic text-ink dark:text-white transition-colors"
            >
              Caramel Kitchen
            </Link>

            <button
              type="button"
              onClick={closeMobileMenu}
              className="p-2 text-gray-500 hover:text-ink dark:text-gray-400 dark:hover:text-white rounded-xl hover:bg-gray-100 dark:hover:bg-stone-800 transition-colors cursor-pointer focus:outline-none"
              aria-label="Close navigation menu"
            >
              <X size={20} />
            </button>
          </div>

          {/* Drawer Search */}
          <form
            onSubmit={(e) => {
              handleSearchSubmit(e);
              closeMobileMenu();
            }}
            className="flex items-center bg-gray-50 dark:bg-stone-900 border border-taupe/15 dark:border-stone-800 rounded-2xl px-3.5 py-2 gap-2 focus-within:border-caramel/40 focus-within:bg-white dark:focus-within:bg-stone-900 transition-all shadow-xs"
          >
            <input
              type="text"
              placeholder="Search recipes..."
              value={searchVal}
              onChange={(e) => handleSearchChange(e.target.value)}
              className="w-full text-sm bg-transparent border-none text-ink dark:text-parchment focus:outline-none placeholder:text-gray-400"
            />

            {searchVal && (
              <button
                type="button"
                onClick={() => handleSearchChange("")}
                className="text-gray-400 hover:text-ink dark:hover:text-white transition-colors cursor-pointer"
              >
                <X size={14} />
              </button>
            )}

            <button
              type="submit"
              className="flex items-center justify-center bg-[#ec4899] hover:bg-[#db2777] text-white p-1.5 rounded-xl cursor-pointer shadow-xs transition-colors shrink-0"
              aria-label="Search"
            >
              <Search size={14} />
            </button>
          </form>

          {/* Navigation Items */}
          <nav className="flex flex-col gap-1.5">
            <p className="text-[11px] font-bold uppercase tracking-wider text-gray-400 dark:text-stone-500 px-3 pb-1">
              Menu
            </p>

            <Link
              to="/"
              onClick={closeMobileMenu}
              className={`flex items-center gap-3.5 px-3.5 py-3 rounded-2xl font-medium text-sm transition-all duration-150 ${isHomeActive
                ? "bg-caramel/10 dark:bg-caramel/20 text-caramel dark:text-caramel font-semibold shadow-xs"
                : "text-gray-700 dark:text-gray-200 hover:bg-gray-100/70 dark:hover:bg-stone-800/60"
                }`}
            >
              <ChefHat
                size={18}
                className={
                  isHomeActive ? "text-caramel" : "text-gray-400 dark:text-stone-400"
                }
              />
              <span>Home</span>
            </Link>

            <Link
              to="/browse"
              onClick={closeMobileMenu}
              className={`flex items-center gap-3.5 px-3.5 py-3 rounded-2xl font-medium text-sm transition-all duration-150 ${isDiscoverActive
                ? "bg-caramel/10 dark:bg-caramel/20 text-caramel dark:text-caramel font-semibold shadow-xs"
                : "text-gray-700 dark:text-gray-200 hover:bg-gray-100/70 dark:hover:bg-stone-800/60"
                }`}
            >
              <Compass
                size={18}
                className={
                  isDiscoverActive
                    ? "text-caramel"
                    : "text-gray-400 dark:text-stone-400"
                }
              />
              <span>Discover Recipes</span>
            </Link>

            <Link
              to="/shopping-list"
              onClick={closeMobileMenu}
              className={`flex items-center gap-3.5 px-3.5 py-3 rounded-2xl font-medium text-sm transition-all duration-150 ${isShoppingListActive
                ? "bg-caramel/10 dark:bg-caramel/20 text-caramel dark:text-caramel font-semibold shadow-xs"
                : "text-gray-700 dark:text-gray-200 hover:bg-gray-100/70 dark:hover:bg-stone-800/60"
                }`}
            >
              <ClipboardList
                size={18}
                className={
                  isShoppingListActive
                    ? "text-caramel"
                    : "text-gray-400 dark:text-stone-400"
                }
              />
              <span>Shopping List</span>
            </Link>

            <Link
              to="/meal-plans"
              onClick={(e) => {
                closeMobileMenu();
                if (!isPremium) {
                  e.preventDefault();
                  openPremiumModal({
                    featureName: "Weekly Meal Planner",
                    featureDescription:
                      "Meal planning, macro balancing, and automated schedule generation are available exclusively on Caramel Bronze and Silver plans.",
                  });
                }
              }}
              className={`flex items-center justify-between px-3.5 py-3 rounded-2xl font-medium text-sm transition-all duration-150 ${isMealPlansActive
                ? "bg-caramel/10 dark:bg-caramel/20 text-caramel dark:text-caramel font-semibold shadow-xs"
                : "text-gray-700 dark:text-gray-200 hover:bg-gray-100/70 dark:hover:bg-stone-800/60"
                }`}
            >
              <div className="flex items-center gap-3.5">
                <Utensils
                  size={18}
                  className={
                    isMealPlansActive
                      ? "text-caramel"
                      : "text-gray-400 dark:text-stone-400"
                  }
                />
                <span>Weekly Meal Plans</span>
              </div>
            </Link>

            <Link
              to="/learn"
              onClick={() => closeMobileMenu()}
              className={`flex items-center justify-between px-3.5 py-3 rounded-2xl font-medium text-sm transition-all duration-150 ${isLearnActive
                ? "bg-caramel/10 dark:bg-caramel/20 text-caramel dark:text-amber-400 font-semibold shadow-xs"
                : "text-gray-700 dark:text-gray-200 hover:bg-gray-100/70 dark:hover:bg-stone-800/60"
                }`}
            >
              <div className="flex items-center gap-3.5">
                <Book
                  size={18}
                  className={
                    isLearnActive
                      ? "text-caramel"
                      : "text-gray-400 dark:text-stone-400"
                  }
                />
                <span>Learn with Sofia</span>
              </div>
            </Link>

            <Link
              to="/ai"
              onClick={(e) => {
                closeMobileMenu();
                if (!isPremium) {
                  e.preventDefault();
                  openPremiumModal({
                    featureName: "Caramel AI Chef",
                    featureDescription:
                      "Ask questions, swap ingredients, and get customized step-by-step guidance tailored to your kitchen using Caramel AI.",
                  });
                }
              }}
              className={`flex items-center justify-between px-3.5 py-3 rounded-2xl font-medium text-sm transition-all duration-150 ${isAiActive
                ? "bg-caramel/10 dark:bg-caramel/20 text-caramel dark:text-caramel font-semibold shadow-xs"
                : "text-gray-700 dark:text-gray-200 hover:bg-gray-100/70 dark:hover:bg-stone-800/60"
                }`}
            >
              <div className="flex items-center gap-3.5">
                <Sparkles
                  size={18}
                  className={
                    isAiActive
                      ? "text-caramel"
                      : "text-gray-400 dark:text-stone-400"
                  }
                />
                <span>Caramel AI Chef</span>
              </div>
              <span className="flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-500/15 text-amber-600 dark:text-amber-400 border border-amber-500/20">
                <Diamond size={10} className="fill-amber-500" />
                PRO
              </span>
            </Link>

            {isAuthenticated && isCreator && (
              <Link
                to="/creator"
                onClick={closeMobileMenu}
                className={`flex items-center gap-3.5 px-3.5 py-3 rounded-2xl font-medium text-sm transition-all duration-150 ${isCreatorActive
                  ? "bg-caramel/10 dark:bg-caramel/20 text-caramel dark:text-caramel font-semibold shadow-xs"
                  : "text-gray-700 dark:text-gray-200 hover:bg-gray-100/70 dark:hover:bg-stone-800/60"
                  }`}
              >
                <Plus
                  size={18}
                  className={
                    isCreatorActive
                      ? "text-caramel"
                      : "text-gray-400 dark:text-stone-400"
                  }
                />
                <span>Creator Studio</span>
              </Link>
            )}
          </nav>

          {/* Premium Upgrade Banner in Drawer */}
          {!isPremium && (
            <div className="p-4 rounded-2xl bg-gradient-to-br from-amber-500/10 via-orange-500/10 to-transparent border border-amber-500/20 flex flex-col gap-2.5">
              <div className="flex items-center gap-2 text-amber-600 dark:text-amber-400 font-semibold text-xs">
                <Diamond size={14} className="fill-amber-500" />
                <span>Caramel Premium</span>
              </div>
              <p className="text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
                Unlock AI cooking assistance, custom weekly meal plans, and macro tracking.
              </p>
              <Link
                to="/premium"
                onClick={closeMobileMenu}
                className="mt-1 flex items-center justify-center gap-1.5 py-2 px-3 rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 text-white font-semibold text-xs shadow-xs hover:from-amber-600 hover:to-orange-600 transition-all text-center"
              >
                <Diamond size={12} className="fill-white" />
                <span>Explore Plans</span>
              </Link>
            </div>
          )}
        </div>

        {/* Drawer Bottom Section: Auth & Theme */}
        <div className="p-5 border-t border-taupe/10 dark:border-stone-800 bg-gray-50/50 dark:bg-[#120905]/50 flex flex-col gap-4">
          {isAuthenticated ? (
            <div className="flex flex-col gap-3">
              {/* Profile Card */}
              <Link
                to="/profile"
                onClick={closeMobileMenu}
                className="flex items-center gap-3 p-2.5 rounded-2xl hover:bg-white dark:hover:bg-stone-800/70 transition-colors border border-transparent hover:border-taupe/10 dark:hover:border-stone-800"
              >
                <div className="rounded-full ring-2 ring-emerald-500 ring-offset-2 ring-offset-white dark:ring-offset-[#150a06] p-[1px] flex items-center justify-center shrink-0">
                  {user?.avatar_url ? (
                    <img
                      src={user.avatar_url}
                      alt={user.name}
                      className="h-10 w-10 rounded-full object-cover"
                    />
                  ) : (
                    <div className="flex h-10 w-10 items-center justify-center rounded-full bg-caramel/15 dark:bg-caramel/30 font-sans text-sm font-bold text-caramel uppercase">
                      {user?.name ? user.name.charAt(0) : <User size={18} />}
                    </div>
                  )}
                </div>

                <div className="flex flex-col min-w-0">
                  <span className="text-sm font-bold text-ink dark:text-white truncate">
                    {user?.name || "Account Profile"}
                  </span>
                  <span className="text-xs text-gray-500 dark:text-gray-400 truncate">
                    {user?.email || "View profile"}
                  </span>
                </div>
              </Link>

              {/* Log out Button */}
              <button
                type="button"
                onClick={handleLogout}
                className="flex items-center justify-center gap-2 w-full py-2.5 px-4 rounded-xl border border-taupe/20 dark:border-stone-800 text-gray-700 dark:text-gray-300 hover:text-red-600 dark:hover:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/20 text-xs font-semibold transition-colors cursor-pointer"
              >
                <LogOut size={15} />
                <span>Log out</span>
              </button>
            </div>
          ) : (
            <div className="flex flex-col gap-2">
              <Link
                to="/login"
                onClick={closeMobileMenu}
                className="flex items-center justify-center gap-2 w-full py-2.5 px-4 rounded-xl bg-ink dark:bg-stone-800 text-white font-semibold text-xs transition-colors hover:bg-ink/90 dark:hover:bg-stone-700 shadow-xs"
              >
                <LogIn size={15} />
                <span>Log in</span>
              </Link>

              <Link
                to="/signup"
                onClick={closeMobileMenu}
                className="flex items-center justify-center gap-2 w-full py-2.5 px-4 rounded-xl border border-taupe/20 dark:border-stone-800 text-ink dark:text-white font-semibold text-xs transition-colors hover:bg-white dark:hover:bg-stone-850"
              >
                <UserPlus size={15} />
                <span>Create Account</span>
              </Link>
            </div>
          )}

          {/* Theme Toggle in Drawer */}
          <div className="flex items-center justify-between pt-3 border-t border-taupe/10 dark:border-stone-800 text-xs text-gray-600 dark:text-gray-400">
            <span>Theme Mode</span>
            <button
              type="button"
              onClick={toggleTheme}
              className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-white dark:bg-stone-800 border border-taupe/15 dark:border-stone-700 text-ink dark:text-white font-medium text-xs shadow-2xs hover:border-caramel/40 transition-all cursor-pointer"
            >
              {theme === "dark" ? (
                <>
                  <Sun size={13} className="text-amber-400" />
                  <span>Light Mode</span>
                </>
              ) : (
                <>
                  <Moon size={13} className="text-stone-700" />
                  <span>Dark Mode</span>
                </>
              )}
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
