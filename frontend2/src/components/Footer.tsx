import { Link } from "react-router-dom";

export const Footer = () => {
  return (
    <footer className="mt-20 border-t border-taupe/20 bg-white py-10 font-sans text-sm text-gray-500">
      <div className="mx-auto max-w-7xl px-8 flex flex-col sm:flex-row items-center justify-between gap-6">
        <Link to="/" className="font-display text-2xl italic text-ink">
          Caramel Kitchen
        </Link>

        <div className="flex items-center gap-6 text-xs font-semibold text-gray-600">
          <a href="#" className="hover:text-ink transition-colors">
            About
          </a>
          <a href="#" className="hover:text-ink transition-colors">
            Privacy
          </a>
          <a href="#" className="hover:text-ink transition-colors">
            Contact
          </a>
        </div>

        <p className="text-xs text-gray-400">
          © {new Date().getFullYear()} Caramel Kitchen. All rights reserved.
        </p>
      </div>
    </footer>
  );
};
