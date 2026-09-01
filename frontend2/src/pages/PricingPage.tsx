import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Check, Diamond } from "lucide-react";
import { Button } from "../components/ui";

type PlanBilling = "monthly" | "annual";

export function PricingPage() {
  const [billing, setBilling] = useState<PlanBilling>("monthly");
  const navigate = useNavigate();

  // Pricing values (in Ksh)
  const prices = {
    silver: billing === "monthly" ? 490 : 390,
    bronze: billing === "monthly" ? 990 : 790,
  };

  const handleSelectPlan = (planName: string) => {
    // Navigate to signup/payment or trigger success toast
    navigate("/signup", { state: { plan: planName } });
  };

  return (
    <div className="min-h-screen text-ink py-8 px-6 sm:px-8 lg:px-24 transition-colors duration-300 font-sans">
      <div className="mx-auto max-w-7xl">
        {/* Header Section */}
        <div className="text-center space-y-4 max-w-3xl mx-auto mb-12">
          <h1 className="font-serif text-3xl sm:text-4xl font-extrabold tracking-tight text-ink">
            We’ve got a plan that’s perfect for you
          </h1>
          <p className="text-sm sm:text-base text-gray-500 dark:text-gray-400">
            Choose the right subscription to level up your culinary skills and
            organize your kitchen.
          </p>
        </div>

        {/* Billing Cycle Toggle */}
        <div className="flex justify-center mb-16">
          <div className="bg-gray-100 dark:bg-[#1d120a] p-1 rounded-full border border-taupe/15 dark:border-stone-800 flex items-center shadow-xs">
            <button
              onClick={() => setBilling("monthly")}
              className={`px-6 py-2 rounded-full text-xs font-bold tracking-wide transition-all duration-200 cursor-pointer ${billing === "monthly"
                  ? "bg-white dark:bg-[#120905] text-ink shadow-xs"
                  : "text-gray-500 dark:text-gray-400 hover:text-ink"
                }`}
            >
              Monthly billing
            </button>
            <button
              onClick={() => setBilling("annual")}
              className={`px-6 py-2 rounded-full text-xs font-bold tracking-wide transition-all duration-200 cursor-pointer ${billing === "annual"
                  ? "bg-white dark:bg-[#120905] text-ink shadow-xs"
                  : "text-gray-500 dark:text-gray-400 hover:text-ink"
                }`}
            >
              Annual billing
            </button>
          </div>
        </div>

        {/* Pricing Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 lg:gap-10 max-w-6xl mx-auto items-stretch">
          {/* Card 1: Free Plan */}
          <div className="bg-white dark:bg-[#1d120a]/40 border border-taupe/10 dark:border-stone hover:border-caramel/30 rounded-3xl p-8 flex flex-col justify-between transition-colors duration-300 shadow-2xs hover:shadow-xs">
            <div className="space-y-6">
              <div>
                <h3 className="font-serif text-xl font-bold text-ink">
                  Free plan
                </h3>
                <div className="mt-4 flex items-baseline gap-1">
                  <span className="text-5xl font-extrabold tracking-tight text-ink font-mono">
                    0
                  </span>
                  <span className="text-sm font-semibold text-gray-400">
                    Ksh
                  </span>
                  <span className="text-xs text-gray-400 ml-1">/ month</span>
                </div>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-3 min-h-[32px]">
                  Explore standard recipes and basic cooking tools.
                </p>
              </div>

              <div className="space-y-2.5">
                <Button
                  variant="dark"
                  fullWidth
                  onClick={() => handleSelectPlan("free")}
                  className="py-2.5 rounded-full"
                >
                  Get started
                </Button>
                <button
                  onClick={() => navigate("/")}
                  className="w-full text-xs text-gray-500 hover:text-ink dark:text-gray-400 dark:hover:text-white font-semibold py-2.5 border border-gray-200 dark:border-stone-850 hover:border-gray-300 dark:hover:border-stone-800 rounded-full transition-all cursor-pointer"
                >
                  Continue for free
                </button>
              </div>

              <hr className="border-taupe/10 dark:border-stone-850/50" />

              <div className="space-y-4">
                <p className="text-[10px] font-bold uppercase tracking-wider text-gray-400">
                  Features
                </p>
                <ul className="space-y-3 text-xs text-gray-600 dark:text-gray-300">
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Access standard recipe guides</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Create and manage active shopping list</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Save one customized list locally</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Filter recipes by category</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          {/* Card 2: Silver Plan (Premium Content) */}
          <div className="bg-[#1d120a] dark:bg-[#150c06] border border-caramel/30 rounded-3xl p-8 flex flex-col justify-between relative transform md:-translate-y-4 md:scale-103 shadow-lg z-10 transition-transform duration-300">
            <span className="absolute top-4 right-4 bg-caramel text-white text-[9px] font-bold px-2.5 py-1 rounded-full uppercase tracking-wider">
              Popular
            </span>

            <div className="space-y-6">
              <div>
                <div className="flex items-center gap-1.5">
                  <h3 className="font-serif text-xl font-bold text-white">
                    Silver plan
                  </h3>
                  <Diamond size={12} className="text-caramel fill-caramel" />
                </div>
                <div className="mt-4 flex items-baseline gap-1">
                  <span className="text-5xl font-extrabold tracking-tight text-white font-mono">
                    {prices.silver}
                  </span>
                  <span className="text-sm font-semibold text-gray-400">
                    Ksh
                  </span>
                  <span className="text-xs text-gray-400 ml-1">/ month</span>
                </div>
                <p className="text-xs text-gray-400 mt-3 min-h-[32px]">
                  Billed{" "}
                  {billing === "annual" ? "annually (save 20%)" : "monthly"}.
                  Unlock premium culinary creations.
                </p>
              </div>

              <div className="space-y-2.5">
                <button
                  onClick={() => handleSelectPlan("silver")}
                  className="w-full text-xs bg-caramel hover:bg-caramel/90 text-white font-bold py-2.5 rounded-full shadow-xs cursor-pointer transition-colors"
                >
                  Get started
                </button>
                <button
                  onClick={() => navigate("/browse")}
                  className="w-full text-xs text-white/80 hover:text-white font-semibold py-2.5 border border-white/10 hover:border-white/20 rounded-full transition-all cursor-pointer"
                >
                  Explore premium content
                </button>
              </div>

              <hr className="border-white/10" />

              <div className="space-y-4">
                <p className="text-[10px] font-bold uppercase tracking-wider text-gray-400">
                  Everything in Free plan plus...
                </p>
                <ul className="space-y-3 text-xs text-gray-300">
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Access all premium creator recipes</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Unlock advanced filter controls</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Save unlimited custom shopping lists</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Ad-free cooking page interface</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Priority community access</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          {/* Card 3: Bronze Plan (Premium Content + Tools) */}
          <div className="bg-white dark:bg-[#1d120a]/40 border border-taupe/10 dark:border-stone hover:border-caramel/30 rounded-3xl p-8 flex flex-col justify-between transition-colors duration-300 shadow-2xs hover:shadow-xs">
            <div className="space-y-6">
              <div>
                <h3 className="font-serif text-xl font-bold text-ink">
                  Bronze plan
                </h3>
                <div className="mt-4 flex items-baseline gap-1">
                  <span className="text-5xl font-extrabold tracking-tight text-ink font-mono">
                    {prices.bronze}
                  </span>
                  <span className="text-sm font-semibold text-gray-400">
                    Ksh
                  </span>
                  <span className="text-xs text-gray-400 ml-1">/ month</span>
                </div>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-3 min-h-[32px]">
                  Billed{" "}
                  {billing === "annual" ? "annually (save 20%)" : "monthly"}.
                  Total control over planners and AI tools.
                </p>
              </div>

              <div className="space-y-2.5">
                <Button
                  variant="dark"
                  fullWidth
                  onClick={() => handleSelectPlan("bronze")}
                  className="py-2.5 rounded-full"
                >
                  Get started
                </Button>
                <button
                  onClick={() => navigate("/ai")}
                  className="w-full text-xs text-gray-500 hover:text-ink dark:text-gray-400 dark:hover:text-white font-semibold py-2.5 border border-gray-200 dark:border-stone-850 hover:border-gray-300 dark:hover:border-stone-800 rounded-full transition-all cursor-pointer"
                >
                  Test AI Assistant
                </button>
              </div>

              <hr className="border-taupe/10 dark:border-stone-850/50" />

              <div className="space-y-4">
                <p className="text-[10px] font-bold uppercase tracking-wider text-gray-400">
                  Everything in Silver plan plus...
                </p>
                <ul className="space-y-3 text-xs text-gray-600 dark:text-gray-300">
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Custom meal plans & calendar planner</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Full integration with AI Kitchen Assistant</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Real-time nutritional tracking reports</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>Offline access to shopping lists</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check
                      size={14}
                      className="text-emerald-500 mt-0.5 shrink-0"
                    />
                    <span>24/7 dedicated support desk</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
