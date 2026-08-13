import { Outlet, Route, Routes } from "react-router-dom";
import { RoleRoute } from "./auth/RoleRoute";
import { Navbar } from "./features/browse/Navbar";
import { BrowsePage } from "./features/browse/BrowsePage";
import { CreatorDashboardPage } from "./pages/CreatorDashboardPage";
import { LoginPage } from "./pages/LoginPage";
import { NotFoundPage } from "./pages/NotFoundPage";
import { RecipeDetailPage } from "./pages/RecipeDetailPage";
import { SignupPage } from "./pages/SignupPage";
import { Footer } from "./components/Footer";

function AppShell() {
  return (
    <div className="min-h-screen bg-white">
      <Navbar />
      <Outlet />
      <Footer />
    </div>
  );
}

function App() {
  return (
    <Routes>
      <Route path="/" element={<BrowsePage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/signup" element={<SignupPage />} />

      <Route element={<AppShell />}>
        <Route path="/recipes/:id" element={<RecipeDetailPage />} />
        <Route path="/recipe" element={<RecipeDetailPage />} />
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
