// Taste tags and dietary flags are enforced server-side (Recipe changeset).
// The rest are the canonical product taxonomy from the design doc; the backend
// accepts any string for these, but the form constrains to keep the catalogue consistent.

export const TASTE_TAGS = ['sour', 'sweet', 'tangy', 'spicy', 'savory', 'bitter', 'umami', 'mild'] as const

export const TASTE_TAG_DESCRIPTIONS: Record<(typeof TASTE_TAGS)[number], string> = {
  sour: 'Citrus, vinegar-based, fermented',
  sweet: 'Honey, sugar, caramel, fruit',
  tangy: 'Sour + sweet, tamarind, yoghurt',
  spicy: 'Chilli, pepper, heat-forward',
  savory: 'Salty, herb-forward, meaty',
  bitter: 'Dark greens, coffee, cocoa',
  umami: 'Deep, rich, broth-like',
  mild: 'Gentle, soft, easy palate',
}

export const DIETARY_FLAGS = [
  'vegetarian',
  'vegan',
  'gluten_free',
  'dairy_free',
  'low_fat',
  'low_carb',
  'keto',
  'high_protein',
  'low_sodium',
  'diabetic_friendly',
  'nut_free',
  'halal',
  'kosher',
  'paleo',
  'whole30',
] as const

export const DISH_CATEGORIES = [
  'egg_dishes',
  'rice_dishes',
  'soups_stews',
  'meat_dishes',
  'fish_seafood',
  'salads',
  'stews_curries',
  'pasta_noodles',
  'breakfast',
  'baked_goods',
  'drinks_juices',
  'snacks',
  'vegetarian',
] as const

export const COURSES = [
  'pre_starter',
  'starter',
  'soup',
  'salad',
  'main',
  'dessert',
  'after_meal',
] as const

export const COOKING_METHODS = [
  'boiling',
  'frying',
  'roasting',
  'grilling',
  'baking',
  'steaming',
  'braising',
  'slow_cooking',
  'pressure_cook',
  'air_frying',
  'raw_no_cook',
  'fermented',
  'sauteing',
  'smoking',
  'no_heat_chill',
  'blanching',
] as const

export const CUISINE_ORIGINS = [
  'african',
  'west_african',
  'east_african',
  'asian',
  'mediterranean',
  'middle_eastern',
  'italian',
  'indian',
  'american',
  'caribbean',
  'latin_american',
  'european',
] as const

export const DIFFICULTIES = ['beginner', 'intermediate', 'advanced'] as const

export const RECIPE_STATUSES = ['draft', 'scheduled', 'live', 'archived'] as const

export function humanize(value: string): string {
  return value
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
}
