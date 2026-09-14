import {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
  type ReactNode,
} from "react";
import { useLocation } from "react-router-dom";

interface NavigationContextType {
  /** True when the screen size is mobile/tablet (< 1024px) */
  isMobile: boolean;
  /** True when the mobile slide-in menu drawer is open */
  isMobileMenuOpen: boolean;
  /** Open the mobile navigation drawer */
  openMobileMenu: () => void;
  /** Close the mobile navigation drawer */
  closeMobileMenu: () => void;
  /** Toggle the mobile navigation drawer open/closed */
  toggleMobileMenu: () => void;
  /** Direct setter for mobile menu open state */
  setIsMobileMenuOpen: (open: boolean | ((prev: boolean) => boolean)) => void;
}

const NavigationContext = createContext<NavigationContextType | undefined>(
  undefined
);

const MOBILE_BREAKPOINT = 1024; // matches lg breakpoint (1024px)

export function NavigationProvider({ children }: { children: ReactNode }) {
  const { pathname } = useLocation();

  // Screen size state
  const [isMobile, setIsMobile] = useState<boolean>(() => {
    if (typeof window !== "undefined") {
      return window.innerWidth < MOBILE_BREAKPOINT;
    }
    return false;
  });

  // Drawer state
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // Monitor viewport resize
  useEffect(() => {
    if (typeof window === "undefined") return;

    const mediaQuery = window.matchMedia(`(max-width: ${MOBILE_BREAKPOINT - 1}px)`);

    const handleResize = () => {
      const mobile = mediaQuery.matches;
      setIsMobile(mobile);
      if (!mobile) {
        // If resized to desktop, ensure mobile menu closes
        setIsMobileMenuOpen(false);
      }
    };

    handleResize();

    mediaQuery.addEventListener("change", handleResize);
    return () => mediaQuery.removeEventListener("change", handleResize);
  }, []);

  // Close mobile menu on route change
  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [pathname]);

  // Handle ESC key to close mobile menu
  useEffect(() => {
    if (!isMobileMenuOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setIsMobileMenuOpen(false);
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isMobileMenuOpen]);

  // Lock body scroll when mobile menu is open
  useEffect(() => {
    if (isMobileMenuOpen) {
      const originalOverflow = document.body.style.overflow;
      document.body.style.overflow = "hidden";
      return () => {
        document.body.style.overflow = originalOverflow;
      };
    }
  }, [isMobileMenuOpen]);

  const openMobileMenu = useCallback(() => {
    setIsMobileMenuOpen(true);
  }, []);

  const closeMobileMenu = useCallback(() => {
    setIsMobileMenuOpen(false);
  }, []);

  const toggleMobileMenu = useCallback(() => {
    setIsMobileMenuOpen((prev) => !prev);
  }, []);

  return (
    <NavigationContext.Provider
      value={{
        isMobile,
        isMobileMenuOpen,
        openMobileMenu,
        closeMobileMenu,
        toggleMobileMenu,
        setIsMobileMenuOpen,
      }}
    >
      {children}
    </NavigationContext.Provider>
  );
}

/**
 * Hook to access navigation and mobile menu state across any component.
 */
export function useNavigation() {
  const context = useContext(NavigationContext);
  if (!context) {
    throw new Error("useNavigation must be used within a NavigationProvider");
  }
  return context;
}

/**
 * Convenience hook to check if the app is currently rendered in mobile mode.
 */
export function useIsMobile() {
  const { isMobile } = useNavigation();
  return isMobile;
}
