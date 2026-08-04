import { z } from 'zod'

const numberOrNull = z.number().nullable()

export function toNullableNumber(value: unknown): number | null {
  if (value === '' || value === null || value === undefined) return null
  const parsed = Number(value)
  return Number.isNaN(parsed) ? null : parsed
}

const ingredientSchema = z.object({
  name: z.string().min(1, 'Enter an ingredient name'),
  quantity: z.string().min(1, 'Enter a quantity'),
  unit: z.string().optional(),
  notes: z.string().optional(),
})

const stepSchema = z.object({
  order: z.number(),
  instruction: z.string().min(1, 'Enter this step'),
  duration_minutes: numberOrNull,
  tip: z.string().optional().nullable(),
})

export const recipeFormSchema = z
  .object({
    title: z.string().min(1, 'Enter a title'),
    description: z.string().optional(),
    dish_category: z.string().optional(),
    course: z.string().optional(),
    primary_method: z.string().min(1, 'Choose a primary cooking method'),
    secondary_method: z.string().optional(),
    difficulty: z.enum(['beginner', 'intermediate', 'advanced']),
    cuisine_origin: z.array(z.string()),
    taste_tags: z
      .array(z.string())
      .min(1, 'Pick at least one taste tag')
      .max(4, 'Pick up to 4 taste tags'),
    dietary_flags: z.array(z.string()),
    allergens: z.string().optional(),
    prep_time_mins: numberOrNull,
    cook_time_mins: numberOrNull,
    serving_size: numberOrNull,
    calories: numberOrNull,
    protein_g: numberOrNull,
    carbs_g: numberOrNull,
    fat_g: numberOrNull,
    ingredients: z.array(ingredientSchema).min(1, 'Add at least one ingredient'),
    steps: z.array(stepSchema).min(1, 'Add at least one step'),
    status: z.enum(['draft', 'scheduled']),
    scheduled_at: z.string().optional(),
  })
  .refine((values) => values.status !== 'scheduled' || Boolean(values.scheduled_at), {
    message: 'Pick a date and time to schedule this recipe',
    path: ['scheduled_at'],
  })

export type RecipeFormValues = z.infer<typeof recipeFormSchema>

export const emptyIngredient = { name: '', quantity: '', unit: '', notes: '' }
export const emptyStep = { order: 1, instruction: '', duration_minutes: null, tip: '' }

export const recipeFormDefaults: RecipeFormValues = {
  title: '',
  description: '',
  dish_category: '',
  course: '',
  primary_method: '',
  secondary_method: '',
  difficulty: 'beginner',
  cuisine_origin: [],
  taste_tags: [],
  dietary_flags: [],
  allergens: '',
  prep_time_mins: null,
  cook_time_mins: null,
  serving_size: null,
  calories: null,
  protein_g: null,
  carbs_g: null,
  fat_g: null,
  ingredients: [emptyIngredient],
  steps: [emptyStep],
  status: 'draft',
  scheduled_at: '',
}
