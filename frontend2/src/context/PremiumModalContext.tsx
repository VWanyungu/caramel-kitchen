import { createContext, useContext, useState, type ReactNode } from "react";
import { PremiumModal } from "../components/PremiumModal";
import { useAuth } from "../auth/useAuth";

interface PremiumModalOptions {
  featureName?: string;
  featureDescription?: string;
}

interface PremiumModalContextType {
  openPremiumModal: (options?: PremiumModalOptions) => void;
  closePremiumModal: () => void;
  isPremium: boolean;
}

const PremiumModalContext = createContext<PremiumModalContextType | undefined>(undefined);

export function PremiumModalProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [modalOptions, setModalOptions] = useState<PremiumModalOptions>({});

  // Check if current user has an active premium/paid subscription
  const isPremium = Boolean(
    user?.subscription_tier &&
    user.subscription_tier !== "free" &&
    user.subscription_tier !== ""
  );

  const openPremiumModal = (options?: PremiumModalOptions) => {
    setModalOptions(options || {});
    setIsOpen(true);
  };

  const closePremiumModal = () => {
    setIsOpen(false);
  };

  return (
    <PremiumModalContext.Provider
      value={{
        openPremiumModal,
        closePremiumModal,
        isPremium,
      }}
    >
      {children}
      <PremiumModal
        open={isOpen}
        onClose={closePremiumModal}
        featureName={modalOptions.featureName}
        featureDescription={modalOptions.featureDescription}
      />
    </PremiumModalContext.Provider>
  );
}

export function usePremiumModal() {
  const context = useContext(PremiumModalContext);
  if (!context) {
    throw new Error("usePremiumModal must be used within a PremiumModalProvider");
  }
  return context;
}
