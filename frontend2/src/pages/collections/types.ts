import type { RecipeCard } from "../../features/browse/types";

export interface VideoCard {
  id: string;
  title: string;
  description: string;
  thumbnail_url: string;
  duration_mins: number;
}

export interface CollectionItem {
  id: string;
  item_type: "recipe" | "video";
  position: number;
  notes?: string;
  recipe?: RecipeCard;
  video?: VideoCard;
}

export interface Collection {
  id: string;
  name: string;
  slug: string;
  description: string;
  cover_image_url: string;
  is_public: boolean;
  is_curated: boolean;
  is_premium: boolean;
  is_seasonal: boolean;
  season_name?: string;
  start_date?: string;
  end_date?: string;
  save_count: number;
  items?: CollectionItem[];
}
