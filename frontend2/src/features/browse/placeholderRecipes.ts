import type { RecipeCard } from './types'

// TEST-ONLY fallback data, shown when the backend returns zero recipes
// (e.g. an empty/unseeded dev database) so the grid layout can still be
// reviewed. Never used when the API genuinely errors or is unreachable.
export const PLACEHOLDER_RECIPES: RecipeCard[] = [
  {
    id: 'placeholder-1',
    slug: 'salted-caramel-tart',
    title: 'Salted Caramel Tart',
    thumbnail_url: '/category_coastal.jpg',
    dish_category: 'baked_goods',
    course: 'dessert',
    primary_method: 'baking',
    difficulty: 'intermediate',
    total_time_mins: 75,
    taste_tags: ['sweet', 'rich'],
    dietary_flags: ['vegetarian'],
    calories: 420,
    avg_rating: 4.7,
    rating_count: 128,
    cuisine_origin: ['French'],
    is_special: true,
    // ADDITIONAL DATA FOR SINGLE RECIPE VIEW:
    video_url: 'https://www.youtube.com/watch?v=vVj4xS5GgQ4',
    prep_time_mins: 20,
    cook_time_mins: 55,
    serving_size: 8,
    macros: {
      protein_g: 4,
      carbs_g: 48,
      fat_g: 22,
      fibre_g: 2
    },
    ingredients: [
      { name: "Puff pastry sheet", quantity: 1, unit: "whole" },
      { name: "Granulated sugar", quantity: 1, unit: "cup" },
      { name: "Heavy cream", quantity: 0.75, unit: "cup" },
      { name: "Unsalted butter", quantity: 6, unit: "tbsp" },
      { name: "Sea salt flakes", quantity: 1, unit: "tsp" }
    ],
    steps: [
      {
        order: 1,
        instruction: "Roll out the pastry dough and fit it into a tart tin. Prick the bottom with a fork and chill.",
        tips: ["Chilling the pastry prevents it from shrinking when baked."],
        images: [{ src: "/step-1.jpg", alt: "Roll and chill pastry dough" }]
      },
      {
        order: 2,
        instruction: "Bake the tart shell until golden brown. Let it cool completely before filling.",
        tips: ["Use pie weights to keep the pastry flat."],
        images: [{ src: "/step-2.jpg", alt: "Bake tart shell" }]
      },
      {
        order: 3,
        instruction: "Caramelize the sugar in a saucepan, then slowly stir in the heavy cream and butter. Pour into the tart shell and sprinkle with sea salt.",
        tips: ["Be extremely careful as caramel gets very hot!", "Allow the caramel to set for at least 4 hours."],
        images: [{ src: "/step-3.jpg", alt: "Pour hot caramel into shell" }]
      }
    ]
  },
  {
    id: 'placeholder-2',
    slug: 'spicy-caramel-chicken',
    title: 'Spicy Caramel Chicken',
    thumbnail_url: '/category_coastal.jpg',
    dish_category: 'rice_dishes',
    course: 'main',
    primary_method: 'braising',
    difficulty: 'beginner',
    total_time_mins: 45,
    taste_tags: ['spicy', 'savory'],
    dietary_flags: ['gluten_free'],
    calories: 560,
    avg_rating: 4.5,
    rating_count: 94,
    cuisine_origin: ['Thai'],
    // ADDITIONAL DATA FOR SINGLE RECIPE VIEW:
    video_url: 'https://www.youtube.com/watch?v=yvkD5vV_a2Y',
    prep_time_mins: 15,
    cook_time_mins: 30,
    serving_size: 4,
    macros: {
      protein_g: 35,
      carbs_g: 15,
      fat_g: 18,
      fibre_g: 1
    },
    ingredients: [
      { name: "Chicken thighs, cubed", quantity: 500, unit: "g" },
      { name: "Sugar", quantity: 0.5, unit: "cup" },
      { name: "Fish sauce", quantity: 3, unit: "tbsp" },
      { name: "Garlic, minced", quantity: 3, unit: "cloves" },
      { name: "Thai bird's eye chilies", quantity: 2, unit: "whole" },
      { name: "Ginger, julienned", quantity: 1, unit: "tbsp" }
    ],
    steps: [
      {
        order: 1,
        instruction: "Sauté minced garlic, julienned ginger, and sliced chilies in oil until fragrant.",
        tips: ["Ensure your kitchen is well ventilated when cooking hot chilies!"],
        images: [{ src: "/step-1.jpg", alt: "Sauté aromatics" }]
      },
      {
        order: 2,
        instruction: "Add chicken cubes and cook until browned on all sides.",
        tips: ["Do not crowd the pan to get a nice sear on the chicken."],
        images: [{ src: "/step-2.jpg", alt: "Sear chicken" }]
      },
      {
        order: 3,
        instruction: "Pour in caramel sauce (dissolved sugar in fish sauce) and simmer until chicken is fully cooked and sauce is thick.",
        tips: ["Serve hot with steamed jasmine rice to balance the sweet and spicy flavors."],
        images: [{ src: "/step-3.jpg", alt: "Simmer in caramel sauce" }]
      }
    ]
  },
  {
    id: 'placeholder-3',
    slug: 'brown-butter-caramel-cookies',
    title: 'Brown Butter Caramel Cookies',
    thumbnail_url: '/category_coastal.jpg',
    dish_category: 'baked_goods',
    course: 'dessert',
    primary_method: 'baking',
    difficulty: 'beginner',
    total_time_mins: 40,
    taste_tags: ['sweet', 'buttery'],
    dietary_flags: ['vegetarian'],
    calories: 210,
    avg_rating: 4.9,
    rating_count: 302,
    cuisine_origin: ['American'],
    is_special: true,
    // ADDITIONAL DATA FOR SINGLE RECIPE VIEW:
    video_url: 'https://www.youtube.com/watch?v=ZfKn0I493xM',
    prep_time_mins: 15,
    cook_time_mins: 25,
    serving_size: 12,
    macros: {
      protein_g: 3,
      carbs_g: 28,
      fat_g: 11,
      fibre_g: 1
    },
    ingredients: [
      { name: "Unsalted butter", quantity: 1, unit: "cup" },
      { name: "Brown sugar", quantity: 1, unit: "cup" },
      { name: "Granulated sugar", quantity: 0.5, unit: "cup" },
      { name: "Eggs", quantity: 2, unit: "whole" },
      { name: "All-purpose flour", quantity: 2.25, unit: "cups" },
      { name: "Caramel candies, chopped", quantity: 0.75, unit: "cup" }
    ],
    steps: [
      {
        order: 1,
        instruction: "Melt butter in a saucepan over medium heat until it turns amber brown and smells nutty.",
        tips: ["Watch the butter closely as it can burn very quickly once it starts to brown.", "Let the brown butter cool to room temperature before using."],
        images: [{ src: "/step-1.jpg", alt: "Brown the butter" }]
      },
      {
        order: 2,
        instruction: "Cream the brown butter and sugars together, then beat in eggs one at a time. Fold in dry ingredients and fold in caramel pieces.",
        tips: ["Chill the dough for at least 30 minutes to prevent the cookies from spreading too thin."],
        images: [{ src: "/step-2.jpg", alt: "Mix dough and fold in caramel" }]
      },
      {
        order: 3,
        instruction: "Scoop onto a baking sheet and bake at 350°F (175°C) for 10-12 minutes.",
        tips: ["Sprinkle a touch of flaky sea salt on top immediately after baking for a gourmet finish."],
        images: [{ src: "/step-3.jpg", alt: "Bake cookies until edges are golden" }]
      }
    ]
  },
  {
    id: 'placeholder-coastal-1',
    slug: 'swahili-mahamri',
    title: 'Swahili Mahamri',
    thumbnail_url: '/category_coastal.jpg',
    dish_category: 'breakfast',
    course: 'starter',
    primary_method: 'frying',
    difficulty: 'intermediate',
    total_time_mins: 45,
    taste_tags: ['sweet', 'spiced'],
    dietary_flags: ['vegetarian'],
    calories: 280,
    avg_rating: 4.8,
    rating_count: 142,
    cuisine_origin: ['coastal'],
    is_special: true,
  },
  {
    id: 'placeholder-central-1',
    slug: 'kenyan-githeri',
    title: 'Kenyan Githeri',
    thumbnail_url: '/category_central.jpg',
    dish_category: 'soups_stews',
    course: 'main',
    primary_method: 'boiling',
    difficulty: 'beginner',
    total_time_mins: 60,
    taste_tags: ['savory', 'hearty'],
    dietary_flags: ['vegan', 'gluten_free'],
    calories: 340,
    avg_rating: 4.6,
    rating_count: 89,
    cuisine_origin: ['central'],
  },
  {
    id: 'placeholder-western-1',
    slug: 'millet-uji-groundnuts',
    title: 'Millet Uji with Groundnuts',
    thumbnail_url: '/category_western.jpg',
    dish_category: 'breakfast',
    course: 'breakfast',
    primary_method: 'simmering',
    difficulty: 'beginner',
    total_time_mins: 20,
    taste_tags: ['sweet', 'nutty'],
    dietary_flags: ['vegan', 'gluten_free'],
    calories: 220,
    avg_rating: 4.7,
    rating_count: 73,
    cuisine_origin: ['western'],
  },
  {
    id: 'placeholder-nyanza-1',
    slug: 'fried-tilapia-ugali',
    title: 'Fried Tilapia with Ugali & Greens',
    thumbnail_url: '/category_nyanza.jpg',
    dish_category: 'fish_seafood',
    course: 'main',
    primary_method: 'frying',
    difficulty: 'intermediate',
    total_time_mins: 35,
    taste_tags: ['savory', 'spicy'],
    dietary_flags: ['gluten_free'],
    calories: 520,
    avg_rating: 4.9,
    rating_count: 215,
    cuisine_origin: ['nyanza'],
  },
  {
    id: 'placeholder-rift-1',
    slug: 'mursik-with-ugali',
    title: 'Mursik with Brown Ugali',
    thumbnail_url: '/category_nyanza.jpg',
    dish_category: 'breakfast',
    course: 'main',
    primary_method: 'fermenting',
    difficulty: 'intermediate',
    total_time_mins: 15,
    taste_tags: ['sour', 'rich'],
    dietary_flags: ['vegetarian', 'gluten_free'],
    calories: 310,
    avg_rating: 4.5,
    rating_count: 54,
    cuisine_origin: ['rift_valley'],
  },
]
