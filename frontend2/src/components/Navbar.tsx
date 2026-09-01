import { Compass, Moon, Plus, ShoppingBag, Sparkles, ChefHat, Sun, User, ClipboardList, Search, X, Diamond, ChevronDown, Utensils } from "lucide-react";
import { useEffect, useState } from "react";
import { Link, useLocation, useNavigate, useSearchParams } from "react-router-dom";
import { useAuth } from "../auth/useAuth";
import { usePremiumModal } from "../context/PremiumModalContext";
import { Button } from "./ui";

export function Navbar() {
  const { status, user, isCreator, logout } = useAuth();
  const { openPremiumModal, isPremium } = usePremiumModal();
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

  const showNavbarSearch = pathname !== "/browse" || isScrolledPastFilter;

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
  const [theme, setTheme] = useState<'light' | 'dark'>(() => {
    if (typeof window !== "undefined") {
      const savedTheme = localStorage.getItem("theme");
      if (savedTheme === "dark" || savedTheme === "light") {
        return savedTheme;
      }
      return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
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
    navigate("/");
  };

  const isAuthenticated = status === "authenticated";

  const isHomeActive = pathname === "/";
  const isDiscoverActive = pathname === "/browse";
  const isShoppingListActive = pathname === "/shopping-list" || pathname === "/cart";
  const isMealPlansActive = pathname === "/meal-plans";
  const isAiActive = pathname === "/ai";
  // const isProfileActive = pathname === "/profile";

  return (
    <header className="dark:border-taupe/10 bg-white dark:bg-[#120905] sticky top-0 z-29 transition-colors duration-300">
      <nav className="mx-auto flex items-center justify-between px-8 lg:px-16 py-4 gap-4">
        {/* Left Side Logo */}
        <div className="flex-1 flex justify-start items-center gap-4">
          <Link to="/" className="font-display text-2xl italic text-ink dark:text-white transition-colors shrink-0">
            Caramel Kitchen
          </Link>

          {/* Navbar Search Bar */}
          {showNavbarSearch && (
            <form
              onSubmit={handleSearchSubmit}
              className="hidden lg:flex items-center bg-gray-50 dark:bg-stone-900 border border-taupe/15 dark:border-stone-800 rounded-full pl-6 pr-1 py-1 w-96 gap-1 transition-all duration-200 focus-within:bg-white dark:focus-within:bg-stone-900 focus-within:border-caramel/30"
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

        {/* Center Nav Options (Discover, Cart, Profile, Mode Toggle) */}
        <div className="flex items-center gap-1 bg-gray-100/80 dark:bg-[#1d120a] p-1 rounded-full border border-taupe/15 dark:border-stone-800 shadow-xs transition-colors duration-300">
          <Link
            to="/"
            className={`flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isHomeActive
              ? "bg-white dark:bg-[#120905] text-caramel dark:text-caramel shadow-xs"
              : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
              }`}
          >
            <ChefHat size={15} />
            <span className="hidden md:inline">Home</span>
          </Link>

          <Link
            to="/browse"
            className={`flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isDiscoverActive
              ? "bg-white dark:bg-[#120905] text-caramel dark:text-caramel shadow-xs"
              : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
              }`}
          >
            <Compass size={15} />
            <span className="hidden md:inline">Discover</span>
          </Link>

          <Link
            to="/shopping-list"
            className={`flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isShoppingListActive
              ? "bg-white dark:bg-[#120905] text-caramel dark:text-caramel shadow-xs"
              : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
              }`}
          >
            <ClipboardList size={15} />
            <span className="hidden md:inline">Shopping List</span>
          </Link>

          <Link
            to="/meal-plans"
            onClick={(e) => {
              if (!isPremium) {
                e.preventDefault();
                openPremiumModal({
                  featureName: "Weekly Meal Planner",
                  featureDescription: "Meal planning, macro balancing, and automated schedule generation are available exclusively on Caramel Bronze and Silver plans.",
                });
              }
            }}
            className={`relative flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isMealPlansActive
              ? "bg-white dark:bg-[#120905] text-caramel dark:text-caramel shadow-xs"
              : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
              }`}
          >
            <Utensils size={15} />
            <span className="hidden md:inline">Meal Plans</span>
            <Diamond size={8} className="absolute top-0.5 right-1.5 text-amber-500 fill-amber-500" />
          </Link>

          <Link
            to="/ai"
            onClick={(e) => {
              if (!isPremium) {
                e.preventDefault();
                openPremiumModal({
                  featureName: "Caramel AI Chef",
                  featureDescription: "Ask questions, swap ingredients, and get customized step-by-step guidance tailored to your kitchen using Caramel AI.",
                });
              }
            }}
            className={`relative flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide transition-all duration-200 ${isAiActive
              ? "bg-white dark:bg-[#120905] text-caramel dark:text-caramel shadow-xs"
              : "text-gray-600 dark:text-gray-300 hover:text-ink dark:hover:text-caramel"
              }`}
          >
            <Sparkles size={15} />
            <span className="hidden md:inline">AI</span>
            <Diamond size={8} className="absolute top-0.5 right-1.5 text-amber-500 fill-amber-500" />
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

        {/* Right Side Actions */}
        <div className="flex-1 flex justify-end items-center gap-3 font-sans text-sm">
          {/* Upgrade to Premium CTA */}
          <Link to="/premium" className="hidden sm:inline-block">
            <button className="bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-600 hover:to-orange-600 text-white font-semibold text-xs px-4 py-1.5 rounded-full flex items-center gap-1.5 cursor-pointer shadow-xs transition-all duration-150 border border-amber-400/20">
              <Diamond size={11} className="fill-white" />
              <span>Go Premium</span>
            </button>
          </Link>

          {isAuthenticated ? (
            <>
              {isCreator && (
                <Link to="/creator" className="hidden sm:inline-block">
                  <Button variant="dark" size="sm" icon={<Plus size={16} />}>
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
                      {user?.name ? user.name.charAt(0) : <User size={16} />}
                    </div>
                  )}
                </div>
                <span className="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full bg-emerald-500 ring-2 ring-white dark:ring-[#120905]" />
              </Link>
            </>
          ) : (
            <>
              <Link to="/login">
                <Button variant="dark" size="sm">
                  Log in
                </Button>
              </Link>

              <Link to="/signup">
                <Button variant="dark" size="sm">
                  Sign up
                </Button>
              </Link>
            </>
          )}
        </div>
      </nav>
    </header>
  );
}
