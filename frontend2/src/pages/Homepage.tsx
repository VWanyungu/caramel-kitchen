import { Hero } from "../components/Hero";
import { Features } from "../components/Features";
import { SocialShowcase } from "../components/SocialShowcase";
import { PricingPage } from "./PricingPage";

export function HomePage() {
  return (
    <div className="min-h-screen ">
      <div className="lg:px-52">
        <Hero />

        <div className="mt-8">
          <Features />
        </div>

        <div className="mt-8">
          <PricingPage />
        </div>

        <div className="mt-8">
          <SocialShowcase />
        </div>

      </div>
    </div>
  );
}
