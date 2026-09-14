import type { Collection } from "./types";
import { PLACEHOLDER_RECIPES } from "../../features/browse/placeholderRecipes";

export const MOCK_COLLECTIONS: Collection[] = [
  {
    id: "col-1",
    name: "Summer Grilling Essentials",
    slug: "summer-grilling-essentials",
    description: "The best recipes for your summer cookouts, from burgers to grilled veggies.",
    cover_image_url: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&q=80&w=800",
    is_public: true,
    is_curated: true,
    is_premium: false,
    is_seasonal: true,
    season_name: "Summer",
    start_date: "2024-06-01",
    end_date: "2024-08-31",
    save_count: 1240,
    items: [
      {
        id: "item-1",
        item_type: "recipe",
        position: 1,
        recipe: PLACEHOLDER_RECIPES[1], // Spicy Caramel Chicken
      },
      {
        id: "item-2",
        item_type: "video",
        position: 2,
        video: {
          id: "vid-1",
          title: "How to Grill the Perfect Steak",
          description: "Master the art of grilling steaks with our expert tips.",
          thumbnail_url: "https://images.unsplash.com/photo-1558030006-450675393462?auto=format&fit=crop&q=80&w=800",
          duration_mins: 12,
        }
      }
    ]
  },
  {
    id: "col-2",
    name: "Mastering Pastry",
    slug: "mastering-pastry",
    description: "Step-by-step videos and recipes to perfect your baking skills.",
    cover_image_url: "https://images.unsplash.com/photo-1517686469429-8bdb88b9f907?auto=format&fit=crop&q=80&w=800",
    is_public: true,
    is_curated: true,
    is_premium: true,
    is_seasonal: false,
    save_count: 890,
    items: [
      {
        id: "item-3",
        item_type: "recipe",
        position: 1,
        recipe: PLACEHOLDER_RECIPES[0], // Salted Caramel Tart
      },
      {
        id: "item-4",
        item_type: "recipe",
        position: 2,
        recipe: PLACEHOLDER_RECIPES[2], // Brown Butter Caramel Cookies
      }
    ]
  },
  {
    id: "col-3",
    name: "Cozy Winter Stews",
    slug: "cozy-winter-stews",
    description: "Warm up with these hearty and comforting winter stews.",
    cover_image_url: "https://images.unsplash.com/photo-1548943487-a2e4e43b4859?auto=format&fit=crop&q=80&w=800",
    is_public: true,
    is_curated: true,
    is_premium: false,
    is_seasonal: true,
    season_name: "Winter",
    start_date: "2024-12-01",
    end_date: "2025-02-28",
    save_count: 450,
    items: [
      {
        id: "item-5",
        item_type: "recipe",
        position: 1,
        recipe: PLACEHOLDER_RECIPES[4], // Kenyan Githeri
      }
    ]
  },
  {
    id: "col-4",
    name: "Healthy Weeknight Dinners",
    slug: "healthy-weeknight-dinners",
    description: "Quick, healthy, and delicious dinners for busy weeknights.",
    cover_image_url: "https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&q=80&w=800",
    is_public: true,
    is_curated: false,
    is_premium: false,
    is_seasonal: false,
    save_count: 2100,
    items: [
      {
        id: "item-6",
        item_type: "recipe",
        position: 1,
        recipe: PLACEHOLDER_RECIPES[6], // Fried Tilapia
      }
    ]
  }
];
