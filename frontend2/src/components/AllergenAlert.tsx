import { Info } from "lucide-react";

interface AllergenAlertProps {
  allergens?: string[];
  title?: string;
  message?: string;
  className?: string;
}

export function AllergenAlert({
  allergens,
  title,
  message,
  className = "",
}: AllergenAlertProps) {
  const computedTitle =
    title ||
    (allergens && allergens.length > 0
      ? `Allergen Advisory: Contains ${allergens.map((a) => a.replace("_", " ")).join(", ")}`
      : "Allergen Advisory");

  const computedMessage =
    message ||
    (allergens && allergens.length > 0
      ? "Please verify all ingredients and cross-contamination warnings before cooking or serving."
      : "This recipe may contain common allergens such as dairy, gluten, nuts, or soy. Review ingredient details before preparation.");

  return (
    <div
      className={`flex items-start gap-3.5 rounded-2xl border border-sky-100 dark:border-sky-900/40 bg-[#f4faff] dark:bg-[#0c1929]/70 px-5 py-4 text-left shadow-2xs font-sans transition-all duration-300 ${className}`}
    >
      {/* Blue circled Info icon */}
      <div className="flex h-6 w-6 shrink-0 items-center justify-center text-sky-500 mt-0.5">
        <Info className="h-5 w-5 stroke-[2.2]" />
      </div>

      <div className="space-y-0.5">
        <h4 className="text-sm font-semibold tracking-tight text-ink dark:text-white">
          {computedTitle}
        </h4>
        <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400 leading-relaxed">
          {computedMessage}
        </p>
      </div>
    </div>
  );
}
