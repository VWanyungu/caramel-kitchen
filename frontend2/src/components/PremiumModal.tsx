import { X, Diamond, Check, Sparkles, ArrowRight } from "lucide-react";
import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "./ui";

export interface PremiumModalProps {
  open: boolean;
  onClose: () => void;
  featureName?: string;
  featureDescription?: string;
}

export function PremiumModal({
  open,
  onClose,
  featureName = "Premium Feature",
  featureDescription = "This feature is exclusively available to Caramel Silver and Bronze plan members.",
}: PremiumModalProps) {
  const navigate = useNavigate();

  useEffect(() => {
    if (!open) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, onClose]);

  if (!open) return null;

  const handleUpgradeClick = () => {
    onClose();
    navigate("/premium");
  };

  const perks = [
    "Unlimited access to exclusive Pro & creator recipes",
    "Personalized weekly meal plan builder with calorie targeting",
    "Caramel AI cooking assistant & smart substitutions",
    "Save unlimited custom shopping lists & local pantry sync",
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 backdrop-blur-xs p-0 sm:items-center sm:p-6 transition-all duration-300">
      {/* Backdrop */}
      <button
        type="button"
        aria-label="Close modal"
        onClick={onClose}
        className="absolute inset-0 cursor-default"
      />

      {/* Modal Dialog */}
      <div
        role="dialog"
        aria-modal="true"
        aria-label={featureName}
        className="relative z-10 max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-t-3xl bg-white dark:bg-[#1d120a] p-6 sm:p-8 shadow-2xl border border-gray-100 dark:border-stone-850 sm:rounded-3xl transition-all duration-300 font-sans"
      >
        {/* Header with Title & Close Button */}
        <div className="mb-6 flex items-center justify-between border-b border-gray-100 dark:border-stone-800 pb-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-amber-500/10 dark:bg-amber-500/20 text-amber-500 rounded-xl flex items-center justify-center">
              <Diamond className="h-5 w-5 fill-amber-500" />
            </div>
            <div>
              <span className="text-[10px] font-bold uppercase tracking-wider text-amber-600 dark:text-amber-400">
                Unlock with Premium
              </span>
              <h2 className="font-serif text-xl sm:text-2xl text-ink dark:text-parchment font-bold leading-tight">
                {featureName}
              </h2>
            </div>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={onClose}
            aria-label="Close"
            className="p-2! rounded-full text-gray-400 hover:text-ink dark:hover:text-parchment hover:bg-gray-100 dark:hover:bg-stone-800"
          >
            <X className="h-5 w-5" />
          </Button>
        </div>

        {/* Modal Content */}
        <div className="space-y-6">
          {/* Feature Description */}
          <p className="text-sm text-gray-600 dark:text-gray-300 leading-relaxed">
            {featureDescription}
          </p>

          {/* Perks Container */}
          <div className="bg-amber-50/60 dark:bg-[#150c06] border border-amber-200/50 dark:border-amber-900/30 rounded-2xl p-5 space-y-3">
            <div className="flex items-center gap-1.5 text-xs font-bold text-amber-800 dark:text-amber-400 uppercase tracking-wide">
              <Sparkles size={14} className="text-amber-500" />
              <span>What's included in Caramel Premium:</span>
            </div>
            <ul className="space-y-2.5 text-xs text-gray-700 dark:text-stone-300">
              {perks.map((perk) => (
                <li key={perk} className="flex items-start gap-2.5">
                  <div className="p-0.5 bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 rounded-full mt-0.5 shrink-0">
                    <Check size={12} strokeWidth={3} />
                  </div>
                  <span>{perk}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* Action Buttons */}
          <div className="space-y-3 pt-2">
            <Button
              variant="primary"
              fullWidth
              size="lg"
              onClick={handleUpgradeClick}
              icon={<ArrowRight size={16} />}
              iconPosition="right"
              className="py-3.5! font-bold text-sm bg-gradient-to-r from-amber-500 to-caramel hover:from-amber-600 hover:to-caramel/90 shadow-md hover:shadow-lg text-white"
            >
              View Plans & Pricing
            </Button>
            <button
              type="button"
              onClick={onClose}
              className="w-full text-xs text-gray-500 hover:text-ink dark:text-gray-400 dark:hover:text-white font-semibold py-2.5 border border-gray-200 dark:border-stone-800 hover:border-gray-300 dark:hover:border-stone-700 rounded-full transition-all cursor-pointer"
            >
              Maybe later
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
