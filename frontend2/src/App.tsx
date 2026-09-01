import { Outlet, Route, Routes } from "react-router-dom";
import { RoleRoute } from "./auth/RoleRoute";
import { Navbar } from "./components/Navbar";
import { BrowsePage } from "./pages/BrowsePage";
import { CreatorDashboardPage } from "./pages/CreatorDashboardPage";
import { LoginPage } from "./pages/LoginPage";
import { NotFoundPage } from "./pages/NotFoundPage";
import { RecipeDetailPage } from "./pages/RecipeDetailPage";
import { SignupPage } from "./pages/SignupPage";
import { ShoppingListPage } from "./pages/ShoppingListPage";
import { ProfilePage } from "./pages/ProfilePage";
import { Footer } from "./components/Footer";
import { HomePage } from "./pages/Homepage";
import { PricingPage } from "./pages/PricingPage";

function AppShell() {
  return (
    <div className="min-h-screen bg-white dark:bg-[#120905] transition-colors duration-300">
      <Navbar />
      <Outlet />
      <Footer />
    </div>
  );
}

function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/signup" element={<SignupPage />} />

      <Route element={<AppShell />}>
        <Route path="/" element={<HomePage />} />
        <Route path="/browse" element={<BrowsePage />} />
        <Route path="/recipes/:id" element={<RecipeDetailPage />} />
        <Route path="/recipe" element={<RecipeDetailPage />} />
        <Route path="/shopping-list" element={<ShoppingListPage />} />
        <Route path="/cart" element={<ShoppingListPage />} />
        <Route path="/profile" element={<ProfilePage />} />
        <Route path="/premium" element={<PricingPage />} />
        <Route
          path="/creator"
          element={
            <RoleRoute>
              <CreatorDashboardPage />
            </RoleRoute>
          }
        />
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}

export default App;
