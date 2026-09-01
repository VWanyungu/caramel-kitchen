import {
  BadgeCheck,
  Calendar,
  Camera,
  Check,
  CreditCard,
  Download,
  Eye,
  Heart,
  KeyRound,
  Link2,
  Lock,
  Mail,
  Plus,
  Receipt,
  Save,
  Settings,
  Trash2,
  User,
  Utensils,
  Diamond,
  AlertTriangle,
} from "lucide-react";
import { useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../auth/useAuth";
import { RecipeCard } from "../components/RecipeCard";
import { PLACEHOLDER_RECIPES } from "../features/browse/placeholderRecipes";
import { Button } from "../components/ui";

type ProfileTab = "recipes" | "meal_plans" | "billing" | "settings";

interface MealPlanSummary {
  id: string;
  title: string;
  dateCreated: string;
  daysCount: number;
  totalCalories: number;
  tags: string[];
  recipesCount: number;
  thumbnail: string;
}

const SAMPLE_MEAL_PLANS: MealPlanSummary[] = [
  {
    id: "mp-1",
    title: "High Protein & Balanced Week",
    dateCreated: "Aug 28, 2026",
    daysCount: 7,
    totalCalories: 2150,
    tags: ["High Protein", "Meal Prep", "Low Carb"],
    recipesCount: 14,
    thumbnail: "/hero-3.jpg",
  },
  {
    id: "mp-2",
    title: "Quick 30-Minute Dinners",
    dateCreated: "Aug 15, 2026",
    daysCount: 5,
    totalCalories: 1850,
    tags: ["Quick & Easy", "Family Style"],
    recipesCount: 10,
    thumbnail: "/hero-2.jpg",
  },
];

const BILLING_HISTORY = [
  {
    id: "inv-2026-08",
    date: "Aug 1, 2026",
    description: "Caramel Silver Plan - Monthly",
    amount: "490 Ksh",
    status: "Paid",
  },
  {
    id: "inv-2026-07",
    date: "Jul 1, 2026",
    description: "Caramel Silver Plan - Monthly",
    amount: "490 Ksh",
    status: "Paid",
  },
  {
    id: "inv-2026-06",
    date: "Jun 1, 2026",
    description: "Caramel Silver Plan - Monthly",
    amount: "490 Ksh",
    status: "Paid",
  },
];

export function ProfilePage() {
  const { user } = useAuth();

  const [activeTab, setActiveTab] = useState<ProfileTab>("recipes");
  const [toastMsg, setToastMsg] = useState<string | null>(null);

  // Profile Form State
  const [name, setName] = useState(user?.name || "Marc Underwood");
  const [email, setEmail] = useState(user?.email || "brentunderwood@caramelkitchen.app");
  const [handle, setHandle] = useState("@brentunderwood");
  const [bio, setBio] = useState(
    "Cerro Gordo Ghost Town. Passionate home cook bringing heritage recipes, woodfired sourdough, and seasonal flavors back to life."
  );
  const [avatarUrl, setAvatarUrl] = useState(
    user?.avatar_url ||
      "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&h=300&q=80"
  );
  const [coverUrl, setCoverUrl] = useState(
    "https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1600&q=80"
  );

  // Password change state
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  // Payment state
  const [paymentMethod, setPaymentMethod] = useState({
    type: "Visa",
    last4: "4242",
    expiry: "08/28",
  });
  const [isEditingPayment, setIsEditingPayment] = useState(false);
  const [subscriptionActive, setSubscriptionActive] = useState(true);
  const [showCancelModal, setShowCancelModal] = useState(false);

  // Saved recipes state
  const [savedRecipes, setSavedRecipes] = useState(
    PLACEHOLDER_RECIPES.slice(0, 4)
  );

  const triggerToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => {
      setToastMsg((prev) => (prev === msg ? null : prev));
    }, 3500);
  };

  const handleSaveProfile = (e: React.FormEvent) => {
    e.preventDefault();
    triggerToast("Profile information updated successfully!");
  };

  const handleSavePassword = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPassword || newPassword !== confirmPassword) {
      triggerToast("Passwords do not match. Please try again.");
      return;
    }
    setCurrentPassword("");
    setNewPassword("");
    setConfirmPassword("");
    triggerToast("Password changed successfully!");
  };

  const handleRemoveSavedRecipe = (recipeId: string, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setSavedRecipes((prev) => prev.filter((r) => r.id !== recipeId));
    triggerToast("Recipe removed from saved collection.");
  };

  const handleCancelSubscription = () => {
    setSubscriptionActive(false);
    setShowCancelModal(false);
    triggerToast("Subscription cancelled. You will retain access until end of billing cycle.");
  };

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-[#120905] text-ink dark:text-parchment pb-24 font-sans transition-colors duration-300">
      {/* Toast Notification */}
      {toastMsg && (
        <div className="fixed top-6 right-6 z-50 bg-[#1d120a] dark:bg-parchment text-white dark:text-ink px-4 py-3 rounded-2xl shadow-xl border border-taupe/20 flex items-center gap-3 animate-fade-in transition-all duration-300">
          <div className="p-1.5 bg-caramel/20 text-caramel rounded-full flex items-center justify-center">
            <Check size={16} />
          </div>
          <span className="text-xs sm:text-sm font-semibold">{toastMsg}</span>
        </div>
      )}

      {/* Main Container */}
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 pt-6">
        
        {/* Profile Card / Header Header */}
        <div className="bg-white dark:bg-[#1d120a] rounded-3xl border border-taupe/10 dark:border-stone-850 overflow-hidden shadow-xs">
          
          {/* Panoramic Cover Image */}
          <div className="relative h-56 sm:h-72 w-full overflow-hidden bg-gray-200 dark:bg-stone-800">
            <img
              src={coverUrl}
              alt="Profile Cover"
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent pointer-events-none" />

            {/* Change cover button */}
            <button
              onClick={() => {
                const nextUrl = prompt("Enter cover image URL:", coverUrl);
                if (nextUrl) setCoverUrl(nextUrl);
              }}
              className="absolute top-4 right-4 bg-black/40 hover:bg-black/60 text-white text-xs font-semibold px-3.5 py-2 rounded-full backdrop-blur-md transition-all flex items-center gap-1.5 cursor-pointer"
            >
              <Camera size={14} />
              <span className="hidden sm:inline">Change Cover</span>
            </button>
          </div>

          {/* Profile Details Bar */}
          <div className="px-6 sm:px-10 pb-8 relative">
            
            {/* Top row: Avatar & Action Buttons */}
            <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-6 -mt-16 sm:-mt-20 mb-6">
              
              {/* Avatar */}
              <div className="relative group self-center sm:self-start">
                <img
                  src={avatarUrl}
                  alt={name}
                  className="h-28 w-28 sm:h-36 sm:w-36 rounded-full object-cover ring-4 ring-white dark:ring-[#1d120a] shadow-xl bg-white"
                />
                <button
                  onClick={() => {
                    const nextAvatar = prompt("Enter avatar image URL:", avatarUrl);
                    if (nextAvatar) setAvatarUrl(nextAvatar);
                  }}
                  title="Change avatar photo"
                  className="absolute bottom-1 right-1 p-2 rounded-full bg-caramel hover:bg-caramel/90 text-white shadow-md transition-transform hover:scale-105 cursor-pointer"
                >
                  <Camera size={15} />
                </button>
              </div>

              {/* Right Side Followers & Actions */}
              <div className="flex flex-col sm:flex-row items-center gap-4 sm:gap-6 self-center sm:self-end">
                
                {/* Followers Cluster */}
                <div className="flex items-center gap-3">
                  <div className="flex -space-x-2 overflow-hidden">
                    <img
                      className="inline-block h-7 w-7 rounded-full ring-2 ring-white dark:ring-[#1d120a]"
                      src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=60&h=60&q=80"
                      alt="Follower 1"
                    />
                    <img
                      className="inline-block h-7 w-7 rounded-full ring-2 ring-white dark:ring-[#1d120a]"
                      src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=60&h=60&q=80"
                      alt="Follower 2"
                    />
                    <img
                      className="inline-block h-7 w-7 rounded-full ring-2 ring-white dark:ring-[#1d120a]"
                      src="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=60&h=60&q=80"
                      alt="Follower 3"
                    />
                  </div>
                  <div className="text-xs font-semibold text-gray-500 dark:text-gray-400">
                    <span className="font-bold text-ink dark:text-white">1.4k</span> followers
                  </div>
                </div>

                {/* Main Action Buttons */}
                <div className="flex items-center gap-2.5">
                  <button
                    onClick={() => setActiveTab("settings")}
                    className="px-5 py-2.5 rounded-full border border-gray-200 dark:border-stone-800 text-xs font-bold hover:bg-gray-100 dark:hover:bg-stone-850 text-ink dark:text-white transition-colors cursor-pointer"
                  >
                    Edit Profile
                  </button>

                  <Link to="/premium">
                    <button className="px-5 py-2.5 rounded-full bg-caramel hover:bg-caramel/90 text-white text-xs font-bold transition-all shadow-xs flex items-center gap-1.5 cursor-pointer">
                      <Diamond size={13} className="fill-white" />
                      <span>{subscriptionActive ? "Silver Plan" : "Upgrade"}</span>
                    </button>
                  </Link>
                </div>

              </div>

            </div>

            {/* Profile Bio & Handle Details */}
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <h1 className="font-serif text-2xl sm:text-3xl font-bold tracking-tight text-ink dark:text-parchment">
                  {name}
                </h1>
                <BadgeCheck size={20} className="text-amber-500 fill-amber-500/20" />
              </div>

              <p className="text-xs font-semibold text-gray-400">
                {handle} • {email}
              </p>

              {/* Social Channels Strip */}
              <div className="flex items-center gap-3 text-gray-400 dark:text-gray-500 pt-1">
                {/* Custom SVG Socials */}
                <a href="https://youtube.com" target="_blank" rel="noopener noreferrer" className="hover:text-caramel transition-colors">
                  <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M23.498 6.163a3.003 3.003 0 0 0-2.11-2.11C19.517 3.545 12 3.545 12 3.545s-7.517 0-9.388.508a3.003 3.003 0 0 0-2.11 2.11C0 8.033 0 12 0 12s0 3.967.502 5.837a3.003 3.003 0 0 0 2.11 2.11c1.871.508 9.388.508 9.388.508s7.517 0 9.388-.508a3.003 3.003 0 0 0 2.11-2.11C24 15.967 24 12 24 12s0-3.967-.502-5.837zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></svg>
                </a>
                <a href="https://instagram.com" target="_blank" rel="noopener noreferrer" className="hover:text-caramel transition-colors">
                  <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.051.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 1 0 0 12.324 6.162 6.162 0 0 0 0-12.324zM12 16a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm6.406-11.845a1.44 1.44 0 1 0 0 2.881 1.44 1.44 0 0 0 0-2.881z"/></svg>
                </a>
                <a href="https://tiktok.com" target="_blank" rel="noopener noreferrer" className="hover:text-caramel transition-colors">
                  <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24"><path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.02 1.63 4.14.99 1.11 2.37 1.77 3.86 1.95v3.91a8.775 8.775 0 0 1-5.11-1.68c-.16-.12-.3-.26-.45-.4v6.81a7.275 7.275 0 0 1-1.44 4.38 7.375 7.375 0 0 1-5.83 2.89 7.375 7.375 0 0 1-5.83-2.89 7.275 7.275 0 0 1-1.44-4.38 7.31 7.31 0 0 1 3.25-6.12 7.23 7.23 0 0 1 6.42-.56v4.06c-.84-.46-1.85-.5-2.73-.08a3.259 3.259 0 0 0-1.86 2.7c-.12.98.24 1.97.94 2.66.7.69 1.69 1.02 2.67.87 1-.15 1.83-.87 2.11-1.85.08-.29.11-.6.11-.9V.02Z"/></svg>
                </a>
                <a href="https://x.com" target="_blank" rel="noopener noreferrer" className="hover:text-caramel transition-colors">
                  <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>
                </a>
                <a href="#" className="hover:text-caramel transition-colors"><Link2 size={15} /></a>
              </div>

              <p className="text-xs sm:text-sm text-gray-600 dark:text-gray-300 max-w-3xl leading-relaxed">
                {bio}
              </p>

              {/* Tags / Categories badges */}
              <div className="flex flex-wrap gap-2 pt-2">
                {["Artisanal Caramel", "Sourdough", "Family Meals", "Meal Prep", "Seasonal"].map((tag) => (
                  <span
                    key={tag}
                    className="px-3 py-1 rounded-full bg-[#fdf5eb] dark:bg-[#251910] text-caramel border border-caramel/20 text-[11px] font-semibold"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            </div>

          </div>

          {/* Tab Navigation Menu */}
          <div className="px-6 sm:px-10 border-t border-gray-100 dark:border-stone-850 flex items-center gap-8 overflow-x-auto text-xs sm:text-sm font-bold">
            <button
              onClick={() => setActiveTab("recipes")}
              className={`py-4 border-b-2 transition-all duration-200 cursor-pointer flex items-center gap-2 whitespace-nowrap ${
                activeTab === "recipes"
                  ? "border-caramel text-caramel"
                  : "border-transparent text-gray-500 hover:text-ink dark:hover:text-parchment"
              }`}
            >
              <Heart size={16} />
              <span>Saved Recipes ({savedRecipes.length})</span>
            </button>

            <button
              onClick={() => setActiveTab("meal_plans")}
              className={`py-4 border-b-2 transition-all duration-200 cursor-pointer flex items-center gap-2 whitespace-nowrap ${
                activeTab === "meal_plans"
                  ? "border-caramel text-caramel"
                  : "border-transparent text-gray-500 hover:text-ink dark:hover:text-parchment"
              }`}
            >
              <Calendar size={16} />
              <span>Saved Meal Plans ({SAMPLE_MEAL_PLANS.length})</span>
            </button>

            <button
              onClick={() => setActiveTab("billing")}
              className={`py-4 border-b-2 transition-all duration-200 cursor-pointer flex items-center gap-2 whitespace-nowrap ${
                activeTab === "billing"
                  ? "border-caramel text-caramel"
                  : "border-transparent text-gray-500 hover:text-ink dark:hover:text-parchment"
              }`}
            >
              <CreditCard size={16} />
              <span>Billing & Subscription</span>
            </button>

            <button
              onClick={() => setActiveTab("settings")}
              className={`py-4 border-b-2 transition-all duration-200 cursor-pointer flex items-center gap-2 whitespace-nowrap ${
                activeTab === "settings"
                  ? "border-caramel text-caramel"
                  : "border-transparent text-gray-500 hover:text-ink dark:hover:text-parchment"
              }`}
            >
              <Settings size={16} />
              <span>Account Settings</span>
            </button>
          </div>

        </div>

        {/* Tab 1: Saved Recipes */}
        {activeTab === "recipes" && (
          <div className="mt-8 space-y-6 animate-fade-in">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="font-serif text-xl sm:text-2xl font-bold text-ink dark:text-parchment">
                  Saved Recipes
                </h2>
                <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400">
                  Quick access to all the recipes you've bookmarked to cook.
                </p>
              </div>

              <Link to="/browse">
                <Button variant="outline" size="sm" icon={<Plus size={14} />}>
                  Explore More
                </Button>
              </Link>
            </div>

            {savedRecipes.length === 0 ? (
              <div className="bg-white dark:bg-[#1d120a] rounded-3xl p-12 text-center border border-taupe/10 dark:border-stone-850 space-y-4">
                <Heart size={40} className="mx-auto text-gray-300 dark:text-stone-700" />
                <h3 className="font-serif text-lg font-bold">No saved recipes yet</h3>
                <p className="text-xs text-gray-500 max-w-sm mx-auto">
                  Browse our collection of curated dishes and bookmark your favorites.
                </p>
                <Link to="/browse">
                  <Button variant="primary" size="md">Browse Recipes</Button>
                </Link>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-6">
                {savedRecipes.map((recipe) => (
                  <div key={recipe.id} className="relative group">
                    <RecipeCard recipe={recipe} />
                    <button
                      onClick={(e) => handleRemoveSavedRecipe(recipe.id, e)}
                      title="Remove from saved"
                      className="absolute top-2 left-2 z-20 p-2 rounded-full bg-black/60 hover:bg-red-600 text-white shadow-md transition-colors cursor-pointer"
                    >
                      <Trash2 size={13} />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Tab 2: Saved Meal Plans */}
        {activeTab === "meal_plans" && (
          <div className="mt-8 space-y-6 animate-fade-in">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="font-serif text-xl sm:text-2xl font-bold text-ink dark:text-parchment">
                  Saved Meal Plans
                </h2>
                <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400">
                  Custom calendar schedules tailored to your nutrition targets.
                </p>
              </div>

              <Link to="/meal-plans">
                <Button variant="primary" size="sm" icon={<Plus size={14} />}>
                  Create Plan
                </Button>
              </Link>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {SAMPLE_MEAL_PLANS.map((plan) => (
                <div
                  key={plan.id}
                  className="bg-white dark:bg-[#1d120a] rounded-3xl p-6 border border-taupe/10 dark:border-stone-850 shadow-xs flex flex-col justify-between space-y-6 hover:shadow-md transition-all duration-300"
                >
                  <div className="space-y-4">
                    <div className="flex items-start justify-between gap-4">
                      <div>
                        <span className="text-[10px] font-bold uppercase tracking-wider text-caramel bg-caramel/10 px-2.5 py-1 rounded-full">
                          {plan.daysCount} Days Schedule
                        </span>
                        <h3 className="font-serif text-xl font-bold text-ink dark:text-white mt-2">
                          {plan.title}
                        </h3>
                        <p className="text-xs text-gray-400 mt-1">Created on {plan.dateCreated}</p>
                      </div>

                      <div className="w-16 h-16 rounded-2xl overflow-hidden bg-gray-100 shrink-0">
                        <img src={plan.thumbnail} alt={plan.title} className="w-full h-full object-cover" />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-3 py-2 text-xs">
                      <div className="bg-gray-50 dark:bg-[#120905] p-3 rounded-xl">
                        <span className="text-gray-400 block text-[10px] uppercase font-bold">Daily Calories</span>
                        <span className="font-bold text-ink dark:text-white text-sm">{plan.totalCalories} kcal</span>
                      </div>
                      <div className="bg-gray-50 dark:bg-[#120905] p-3 rounded-xl">
                        <span className="text-gray-400 block text-[10px] uppercase font-bold">Included Recipes</span>
                        <span className="font-bold text-ink dark:text-white text-sm">{plan.recipesCount} dishes</span>
                      </div>
                    </div>

                    <div className="flex flex-wrap gap-1.5">
                      {plan.tags.map((t) => (
                        <span key={t} className="text-[10px] font-semibold text-gray-600 dark:text-stone-300 bg-gray-100 dark:bg-stone-800 px-2.5 py-0.5 rounded-full">
                          {t}
                        </span>
                      ))}
                    </div>
                  </div>

                  <div className="flex items-center gap-3 pt-2">
                    <Link to="/meal-plans" className="flex-1">
                      <Button variant="outline" size="sm" fullWidth icon={<Eye size={14} />}>
                        View Schedule
                      </Button>
                    </Link>
                    <Link to="/shopping-list" className="flex-1">
                      <Button variant="primary" size="sm" fullWidth icon={<Utensils size={14} />}>
                        Cook Meals
                      </Button>
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Tab 3: Billing & Subscription */}
        {activeTab === "billing" && (
          <div className="mt-8 space-y-8 animate-fade-in max-w-4xl mx-auto">
            
            {/* Header */}
            <div>
              <h2 className="font-serif text-xl sm:text-2xl font-bold text-ink dark:text-parchment">
                Billing & Membership
              </h2>
              <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400">
                Manage your subscription tier, payment methods, and invoices.
              </p>
            </div>

            {/* Current Plan Overview Card */}
            <div className="bg-white dark:bg-[#1d120a] rounded-3xl p-6 sm:p-8 border border-caramel/20 dark:border-stone-850 shadow-xs space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-gray-100 dark:border-stone-850">
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="font-serif text-xl font-bold text-ink dark:text-white">
                      Silver Membership
                    </span>
                    <span className={`text-[10px] font-extrabold uppercase px-2.5 py-0.5 rounded-full ${
                      subscriptionActive
                        ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20"
                        : "bg-gray-100 text-gray-500"
                    }`}>
                      {subscriptionActive ? "Active" : "Cancelled"}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500 dark:text-gray-400">
                    Billed monthly at <strong>490 Ksh / month</strong>. Renews on <strong>September 1, 2026</strong>.
                  </p>
                </div>

                <div className="flex items-center gap-3">
                  <Link to="/premium">
                    <Button variant="primary" size="sm">
                      Change Plan
                    </Button>
                  </Link>
                  {subscriptionActive && (
                    <button
                      onClick={() => setShowCancelModal(true)}
                      className="px-4 py-2 rounded-full border border-red-200 dark:border-red-900/40 text-red-600 hover:bg-red-50 dark:hover:bg-red-950/20 text-xs font-bold transition-colors cursor-pointer"
                    >
                      Stop Subscription
                    </button>
                  )}
                </div>
              </div>

              {/* Payment Method Section */}
              <div className="space-y-4">
                <h3 className="font-serif text-base font-bold text-ink dark:text-white flex items-center gap-2">
                  <CreditCard size={18} className="text-caramel" />
                  <span>Payment Method</span>
                </h3>

                {!isEditingPayment ? (
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-4 rounded-2xl bg-gray-50/70 dark:bg-[#120905] border border-gray-200/60 dark:border-stone-800">
                    <div className="flex items-center gap-3">
                      <div className="p-2.5 bg-blue-500/10 text-blue-600 rounded-xl font-bold text-xs">
                        {paymentMethod.type}
                      </div>
                      <div>
                        <p className="text-xs sm:text-sm font-bold text-ink dark:text-white">
                          •••• •••• •••• {paymentMethod.last4}
                        </p>
                        <p className="text-[11px] text-gray-400">Expires {paymentMethod.expiry}</p>
                      </div>
                    </div>

                    <button
                      onClick={() => setIsEditingPayment(true)}
                      className="text-xs font-bold text-caramel hover:underline cursor-pointer"
                    >
                      Change Payment Method
                    </button>
                  </div>
                ) : (
                  <div className="p-5 rounded-2xl bg-gray-50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 space-y-4">
                    <h4 className="text-xs font-bold uppercase tracking-wider text-ink dark:text-parchment">
                      Update Payment Details
                    </h4>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-[11px] font-bold text-gray-400 mb-1">Card Number</label>
                        <input
                          type="text"
                          placeholder="4242 •••• •••• ••••"
                          className="w-full text-xs px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#1d120a] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-hidden focus:border-caramel/40"
                        />
                      </div>
                      <div className="grid grid-cols-2 gap-2">
                        <div>
                          <label className="block text-[11px] font-bold text-gray-400 mb-1">Expires</label>
                          <input
                            type="text"
                            placeholder="MM/YY"
                            className="w-full text-xs px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#1d120a] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-hidden focus:border-caramel/40"
                          />
                        </div>
                        <div>
                          <label className="block text-[11px] font-bold text-gray-400 mb-1">CVC</label>
                          <input
                            type="text"
                            placeholder="123"
                            className="w-full text-xs px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#1d120a] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-hidden focus:border-caramel/40"
                          />
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3 pt-2">
                      <button
                        onClick={() => {
                          setIsEditingPayment(false);
                          triggerToast("Payment method updated successfully!");
                        }}
                        className="px-5 py-2 rounded-full bg-caramel text-white text-xs font-bold hover:bg-caramel/90 transition-colors cursor-pointer"
                      >
                        Save Card
                      </button>
                      <button
                        onClick={() => setIsEditingPayment(false)}
                        className="px-4 py-2 rounded-full text-xs font-semibold text-gray-500 hover:text-ink dark:hover:text-white cursor-pointer"
                      >
                        Cancel
                      </button>
                    </div>
                  </div>
                )}
              </div>

            </div>

            {/* Past Invoices / Payment History */}
            <div className="bg-white dark:bg-[#1d120a] rounded-3xl p-6 sm:p-8 border border-taupe/10 dark:border-stone-850 shadow-xs space-y-6">
              <h3 className="font-serif text-lg font-bold text-ink dark:text-white flex items-center gap-2">
                <Receipt size={18} className="text-caramel" />
                <span>Payment History</span>
              </h3>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="border-b border-gray-100 dark:border-stone-850 text-gray-400 font-bold uppercase tracking-wider text-[10px]">
                      <th className="pb-3">Date</th>
                      <th className="pb-3">Description</th>
                      <th className="pb-3">Amount</th>
                      <th className="pb-3">Status</th>
                      <th className="pb-3 text-right">Invoice</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-stone-850/60 font-medium">
                    {BILLING_HISTORY.map((invoice) => (
                      <tr key={invoice.id} className="hover:bg-gray-50/50 dark:hover:bg-[#120905]/40 transition-colors">
                        <td className="py-3.5 text-gray-500 dark:text-gray-400">{invoice.date}</td>
                        <td className="py-3.5 font-bold text-ink dark:text-white">{invoice.description}</td>
                        <td className="py-3.5">{invoice.amount}</td>
                        <td className="py-3.5">
                          <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 text-[10px] font-bold">
                            {invoice.status}
                          </span>
                        </td>
                        <td className="py-3.5 text-right">
                          <button
                            onClick={() => triggerToast(`Downloaded invoice ${invoice.id}`)}
                            title="Download PDF"
                            className="p-1.5 text-gray-400 hover:text-caramel rounded-lg transition-colors cursor-pointer"
                          >
                            <Download size={15} />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

          </div>
        )}

        {/* Tab 4: Account Settings (Edit User Info) */}
        {activeTab === "settings" && (
          <div className="mt-8 space-y-8 animate-fade-in max-w-3xl mx-auto">
            
            {/* Header */}
            <div>
              <h2 className="font-serif text-xl sm:text-2xl font-bold text-ink dark:text-parchment">
                Account Settings
              </h2>
              <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400">
                Update your personal information, profile photo, and login security.
              </p>
            </div>

            {/* Profile Info Form */}
            <form onSubmit={handleSaveProfile} className="bg-white dark:bg-[#1d120a] rounded-3xl p-6 sm:p-8 border border-taupe/10 dark:border-stone-850 shadow-xs space-y-6">
              <h3 className="font-serif text-lg font-bold text-ink dark:text-white flex items-center gap-2 border-b border-gray-100 dark:border-stone-850 pb-3">
                <User size={18} className="text-caramel" />
                <span>Personal Information</span>
              </h3>

              <div className="space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-gray-500 mb-1.5">
                      Full Name
                    </label>
                    <input
                      type="text"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      className="w-full text-xs sm:text-sm px-4 py-3 rounded-xl bg-gray-50/50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-hidden focus:border-caramel/40"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-gray-500 mb-1.5">
                      Username Handle
                    </label>
                    <input
                      type="text"
                      value={handle}
                      onChange={(e) => setHandle(e.target.value)}
                      className="w-full text-xs sm:text-sm px-4 py-3 rounded-xl bg-gray-50/50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-hidden focus:border-caramel/40"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-gray-500 mb-1.5">
                    Email Address
                  </label>
                  <div className="relative">
                    <input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="w-full text-xs sm:text-sm pl-10 pr-4 py-3 rounded-xl bg-gray-50/50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-hidden focus:border-caramel/40"
                    />
                    <Mail size={16} className="absolute left-3.5 top-3.5 text-gray-400 pointer-events-none" />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-gray-500 mb-1.5">
                    About / Bio
                  </label>
                  <textarea
                    rows={3}
                    value={bio}
                    onChange={(e) => setBio(e.target.value)}
                    className="w-full text-xs sm:text-sm px-4 py-3 rounded-xl bg-gray-50/50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-hidden focus:border-caramel/40 resize-none leading-relaxed"
                  />
                </div>
              </div>

              <div className="pt-2">
                <Button type="submit" variant="primary" size="md" icon={<Save size={15} />}>
                  Save Profile Changes
                </Button>
              </div>
            </form>

            {/* Password & Security Form */}
            <form onSubmit={handleSavePassword} className="bg-white dark:bg-[#1d120a] rounded-3xl p-6 sm:p-8 border border-taupe/10 dark:border-stone-850 shadow-xs space-y-6">
              <h3 className="font-serif text-lg font-bold text-ink dark:text-white flex items-center gap-2 border-b border-gray-100 dark:border-stone-850 pb-3">
                <KeyRound size={18} className="text-caramel" />
                <span>Change Password</span>
              </h3>

              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-gray-500 mb-1.5">
                    Current Password
                  </label>
                  <input
                    type="password"
                    value={currentPassword}
                    onChange={(e) => setCurrentPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full text-xs sm:text-sm px-4 py-3 rounded-xl bg-gray-50/50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-hidden focus:border-caramel/40"
                  />
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-gray-500 mb-1.5">
                      New Password
                    </label>
                    <input
                      type="password"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      placeholder="••••••••"
                      className="w-full text-xs sm:text-sm px-4 py-3 rounded-xl bg-gray-50/50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-hidden focus:border-caramel/40"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-gray-500 mb-1.5">
                      Confirm New Password
                    </label>
                    <input
                      type="password"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      placeholder="••••••••"
                      className="w-full text-xs sm:text-sm px-4 py-3 rounded-xl bg-gray-50/50 dark:bg-[#120905] border border-gray-200 dark:border-stone-800 text-ink dark:text-parchment focus:outline-hidden focus:border-caramel/40"
                    />
                  </div>
                </div>
              </div>

              <div className="pt-2">
                <Button type="submit" variant="primary" size="md" icon={<Lock size={15} />}>
                  Update Password
                </Button>
              </div>
            </form>

          </div>
        )}

      </div>

      {/* Cancel Subscription Confirmation Dialog */}
      {showCancelModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-xs p-4 animate-fade-in">
          <div className="relative w-full max-w-md bg-white dark:bg-[#1d120a] rounded-3xl p-6 sm:p-8 shadow-2xl border border-gray-100 dark:border-stone-850 space-y-6">
            <div className="flex items-center gap-3 text-red-600 dark:text-red-400">
              <div className="p-2.5 bg-red-100 dark:bg-red-950/40 rounded-2xl">
                <AlertTriangle size={24} />
              </div>
              <h3 className="font-serif text-xl font-bold">Cancel Subscription?</h3>
            </div>

            <p className="text-xs sm:text-sm text-gray-600 dark:text-gray-300 leading-relaxed">
              Are you sure you want to cancel your Caramel Silver membership? You will lose access to Pro chef guides, weekly AI meal plan generation, and unlimited custom grocery lists at the end of this billing cycle.
            </p>

            <div className="flex items-center gap-3 pt-2">
              <button
                onClick={handleCancelSubscription}
                className="flex-1 py-3 rounded-full bg-red-600 hover:bg-red-700 text-white font-bold text-xs transition-colors cursor-pointer"
              >
                Yes, Stop Subscription
              </button>
              <button
                onClick={() => setShowCancelModal(false)}
                className="flex-1 py-3 rounded-full border border-gray-200 dark:border-stone-800 font-bold text-xs text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-stone-800 transition-colors cursor-pointer"
              >
                Keep My Plan
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
