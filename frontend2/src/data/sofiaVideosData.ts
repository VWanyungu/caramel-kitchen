export interface SofiaVideo {
  id: string;
  youtubeId: string;
  title: string;
  description: string;
  category: string;
  level: "Beginner" | "Intermediate" | "Advanced";
  duration: string;
  views: string;
  uploadedAt: string;
  channelName: string;
  channelAvatar: string;
  thumbnailUrl: string;
  tags: string[];
}

export const SOFIA_CATEGORIES = [
  "All",
  "Knife Skills & Prep",
  "Baking & Pastry",
  "Sauces & Stocks",
  "Masterclass Series",
  "Italian & Pasta",
  "Quick Hacks",
  "Healthy Cooking",
];

export const SOFIA_VIDEOS: SofiaVideo[] = [
  {
    id: "vid-1",
    youtubeId: "2aEky9xlyO4",
    title: "Essential Knife Skills Every Home Chef Must Master",
    description:
      "Learn the proper grip, slicing techniques, and how to safely chop onions, julienne vegetables, and maintain your chef's knife blade sharpness like a pro.",
    category: "Knife Skills & Prep",
    level: "Beginner",
    duration: "12:45",
    views: "184K views",
    uploadedAt: "2 weeks ago",
    channelName: "Chef Sofia's Kitchen",
    channelAvatar:
      "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&q=80&w=200",
    thumbnailUrl: "https://img.youtube.com/vi/2aEky9xlyO4/hqdefault.jpg",
    tags: ["knife skills", "chopping", "prep", "basics", "chef tip"],
  },
  {
    id: "vid-2",
    youtubeId: "J8Dq9v61b-U",
    title: "Handmade Fresh Egg Pasta from Scratch: Complete Guide",
    description:
      "Master the art of silky, tender fresh pasta dough using only double zero flour and egg yolks. Learn how to knead, roll, cut tagliatelle, and shape ravioli.",
    category: "Italian & Pasta",
    level: "Intermediate",
    duration: "18:10",
    views: "340K views",
    uploadedAt: "1 month ago",
    channelName: "Chef Sofia's Kitchen",
    channelAvatar:
      "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&q=80&w=200",
    thumbnailUrl: "https://img.youtube.com/vi/J8Dq9v61b-U/hqdefault.jpg",
    tags: ["pasta", "italian", "from scratch", "ravioli", "masterclass"],
  },
  {
    id: "vid-3",
    youtubeId: "yW0t89hH57Y",
    title: "French Mother Sauces: The Rich Béchamel & Velouté",
    description:
      "Understand the foundation of classical cooking. Sofia breaks down roux ratios, whisking techniques, and flavoring variations for creamy béchamel and velouté.",
    category: "Sauces & Stocks",
    level: "Intermediate",
    duration: "15:30",
    views: "92K views",
    uploadedAt: "3 weeks ago",
    channelName: "Chef Sofia's Masterclasses",
    channelAvatar:
      "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&q=80&w=200",
    thumbnailUrl: "https://img.youtube.com/vi/yW0t89hH57Y/hqdefault.jpg",
    tags: ["sauce", "french", "roux", "bechamel", "technique"],
  },
  {
    id: "vid-4",
    youtubeId: "L6X36J7R5oA",
    title: "Perfect Golden Croissants: Lamination & Butter Blocks",
    description:
      "Step-by-step masterclass on creating flaky, buttery French croissants. Learn dough hydration, butter temperature control, 3-folds technique, and baking tips.",
    category: "Baking & Pastry",
    level: "Advanced",
    duration: "24:15",
    views: "510K views",
    uploadedAt: "2 months ago",
    channelName: "Chef Sofia's Kitchen",
    channelAvatar:
      "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&q=80&w=200",
    thumbnailUrl: "https://img.youtube.com/vi/L6X36J7R5oA/hqdefault.jpg",
    tags: ["baking", "croissants", "pastry", "french baking", "masterclass"],
  },
  {
    id: "vid-5",
    youtubeId: "w8jS5pB5_08",
    title: "10 Mind-Blowing Kitchen Hacks That Will Save You Hours",
    description:
      "Simple, clever, and practical cooking tricks to speed up prep time, keep herbs fresh for weeks, peel garlic effortlessly, and clean cast iron skillets.",
    category: "Quick Hacks",
    level: "Beginner",
    duration: "09:40",
    views: "620K views",
    uploadedAt: "5 days ago",
    channelName: "Chef Sofia Quick Tips",
    channelAvatar:
      "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&q=80&w=200",
    thumbnailUrl: "https://img.youtube.com/vi/w8jS5pB5_08/hqdefault.jpg",
    tags: ["hacks", "quick tips", "kitchen shortcuts", "meal prep"],
  },
  {
    id: "vid-6",
    youtubeId: "uK5N86_t_4M",
    title: "Restaurant-Quality Pan-Seared Salmon with Crispy Skin",
    description:
      "Never overcook salmon again! Sofia demonstrates skin scoring, pan heating, basting with aromatic butter, and crafting a quick lemon caper pan sauce.",
    category: "Masterclass Series",
    level: "Intermediate",
    duration: "14:05",
    views: "215K views",
    uploadedAt: "1 month ago",
    channelName: "Chef Sofia's Kitchen",
    channelAvatar:
      "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&q=80&w=200",
    thumbnailUrl: "https://img.youtube.com/vi/uK5N86_t_4M/hqdefault.jpg",
    tags: ["seafood", "salmon", "pan searing", "dinner", "masterclass"],
  },
  {
    id: "vid-7",
    youtubeId: "D8e1Y0Kq6x4",
    title: "High-Protein Mediterranean Bowl Meal Prep Guide",
    description:
      "Nutritious, vibrant, and delicious meal prep ideas. Roasted spiced chickpeas, marinated chicken thighs, cucumber tzatziki, and fluffy quinoa.",
    category: "Healthy Cooking",
    level: "Beginner",
    duration: "11:50",
    views: "145K views",
    uploadedAt: "3 weeks ago",
    channelName: "Chef Sofia Quick Tips",
    channelAvatar:
      "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&q=80&w=200",
    thumbnailUrl: "https://img.youtube.com/vi/D8e1Y0Kq6x4/hqdefault.jpg",
    tags: ["healthy", "mediterranean", "meal prep", "high protein", "quinoa"],
  },
  {
    id: "vid-8",
    youtubeId: "3AAdKl1UYZs",
    title: "Ultimate Rich Chocolate Soufflé Masterclass",
    description:
      "Unlock the secrets to airy, towering chocolate soufflés. How to whip egg whites to stiff peaks, fold batter without deflating, and sugar ramekins.",
    category: "Baking & Pastry",
    level: "Advanced",
    duration: "16:20",
    views: "280K views",
    uploadedAt: "2 months ago",
    channelName: "Chef Sofia's Kitchen",
    channelAvatar:
      "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&q=80&w=200",
    thumbnailUrl: "https://img.youtube.com/vi/3AAdKl1UYZs/hqdefault.jpg",
    tags: ["chocolate", "souffle", "desserts", "baking", "pastry"],
  },
];
