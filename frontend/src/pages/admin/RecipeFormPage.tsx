import { zodResolver } from '@hookform/resolvers/zod'
import { useEffect, useState } from 'react'
import { useForm, useWatch } from 'react-hook-form'
import { useNavigate, useParams } from 'react-router-dom'
import ChipToggleGroup from '../../components/ui/ChipToggleGroup'
import IngredientsEditor from '../../components/admin/IngredientsEditor'
import StepsEditor from '../../components/admin/StepsEditor'
import VideoUploader from '../../components/admin/VideoUploader'
import Button from '../../components/ui/Button'
import Select from '../../components/ui/Select'
import Textarea from '../../components/ui/Textarea'
import TextField from '../../components/ui/TextField'
import { createRecipe, getRecipe, updateRecipe } from '../../lib/adminRecipesApi'
import { extractErrorMessage } from '../../lib/api'
import {
  recipeFormDefaults,
  recipeFormSchema,
  toNullableNumber,
  type RecipeFormValues,
} from '../../lib/recipeFormSchema'
import {
  COOKING_METHODS,
  COURSES,
  CUISINE_ORIGINS,
  DIETARY_FLAGS,
  DIFFICULTIES,
  DISH_CATEGORIES,
  TASTE_TAGS,
  humanize,
} from '../../lib/recipeTaxonomy'
import './recipe-form.css'

interface RecipeFormPageProps {
  mode: 'create' | 'edit'
}

export default function RecipeFormPage({ mode }: RecipeFormPageProps) {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [loadingRecipe, setLoadingRecipe] = useState(mode === 'edit')
  const [submitError, setSubmitError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const {
    register,
    control,
    handleSubmit,
    setValue,
    reset,
    formState: { errors },
  } = useForm<RecipeFormValues>({
    resolver: zodResolver(recipeFormSchema),
    defaultValues: recipeFormDefaults,
  })

  const status = useWatch({ control, name: 'status' })
  const tasteTags = useWatch({ control, name: 'taste_tags' })
  const dietaryFlags = useWatch({ control, name: 'dietary_flags' })
  const cuisineOrigin = useWatch({ control, name: 'cuisine_origin' })

  useEffect(() => {
    if (mode !== 'edit' || !id) return
    let cancelled = false
    getRecipe(id)
      .then((recipe) => {
        if (cancelled) return
        reset({
          ...recipeFormDefaults,
          title: recipe.title,
          description: recipe.description ?? '',
          dish_category: recipe.dish_category ?? '',
          course: recipe.course ?? '',
          primary_method: recipe.primary_method,
          secondary_method: recipe.secondary_method ?? '',
          difficulty: recipe.difficulty,
          cuisine_origin: recipe.cuisine_origin ?? [],
          taste_tags: recipe.taste_tags ?? [],
          dietary_flags: recipe.dietary_flags ?? [],
          allergens: (recipe.allergens ?? []).join(', '),
          prep_time_mins: recipe.prep_time_mins,
          cook_time_mins: recipe.cook_time_mins,
          calories: recipe.calories,
          status: recipe.status === 'live' || recipe.status === 'archived' ? 'draft' : recipe.status,
          scheduled_at: recipe.scheduled_at ?? '',
        })
      })
      .catch((err) => setSubmitError(extractErrorMessage(err, 'Could not load this recipe.')))
      .finally(() => {
        if (!cancelled) setLoadingRecipe(false)
      })
    return () => {
      cancelled = true
    }
  }, [mode, id, reset])

  async function onSubmit(values: RecipeFormValues) {
    setSubmitError(null)
    setSubmitting(true)
    try {
      const payload = {
        title: values.title,
        description: values.description || null,
        dish_category: values.dish_category || null,
        course: values.course || null,
        primary_method: values.primary_method,
        secondary_method: values.secondary_method || null,
        difficulty: values.difficulty,
        cuisine_origin: values.cuisine_origin,
        taste_tags: values.taste_tags,
        dietary_flags: values.dietary_flags,
        allergens: values.allergens
          ? values.allergens.split(',').map((item) => item.trim()).filter(Boolean)
          : [],
        prep_time_mins: values.prep_time_mins,
        cook_time_mins: values.cook_time_mins,
        serving_size: values.serving_size,
        calories: values.calories,
        macros: {
          protein_g: values.protein_g,
          carbs_g: values.carbs_g,
          fat_g: values.fat_g,
        },
        ingredients: values.ingredients,
        steps: values.steps.map((step, index) => ({ ...step, order: index + 1 })),
        status: values.status,
        scheduled_at: values.status === 'scheduled' ? values.scheduled_at : null,
      }

      if (mode === 'edit' && id) {
        await updateRecipe(id, payload)
      } else {
        await createRecipe(payload)
      }
      navigate('/admin/recipes')
    } catch (err) {
      setSubmitError(extractErrorMessage(err, 'Could not save this recipe.'))
    } finally {
      setSubmitting(false)
    }
  }

  if (loadingRecipe) {
    return <p className="recipe-form-loading">Loading recipe…</p>
  }

  return (
    <div className="recipe-form-page">
      <p className="eyebrow">{mode === 'edit' ? 'Edit recipe' : 'New recipe'}</p>
      <h1 className="recipe-form-title">{mode === 'edit' ? 'Update recipe' : 'Create a recipe'}</h1>

      {submitError && (
        <p className="form-banner-error" role="alert">
          {submitError}
        </p>
      )}

      <form onSubmit={handleSubmit(onSubmit)} noValidate>
        <section className="recipe-form-section">
          <h2 className="recipe-form-section-title">Basics</h2>
          <TextField label="Title" error={errors.title?.message} {...register('title')} />
          <Textarea label="Description" error={errors.description?.message} {...register('description')} />

          <div className="recipe-form-grid">
            <Select label="Dish category" {...register('dish_category')}>
              <option value="">Select a category</option>
              {DISH_CATEGORIES.map((option) => (
                <option key={option} value={option}>
                  {humanize(option)}
                </option>
              ))}
            </Select>
            <Select label="Course" {...register('course')}>
              <option value="">Select a course</option>
              {COURSES.map((option) => (
                <option key={option} value={option}>
                  {humanize(option)}
                </option>
              ))}
            </Select>
          </div>

          <div className="recipe-form-grid">
            <Select
              label="Primary cooking method"
              error={errors.primary_method?.message}
              {...register('primary_method')}
            >
              <option value="">Select a method</option>
              {COOKING_METHODS.map((option) => (
                <option key={option} value={option}>
                  {humanize(option)}
                </option>
              ))}
            </Select>
            <Select label="Secondary cooking method" {...register('secondary_method')}>
              <option value="">None</option>
              {COOKING_METHODS.map((option) => (
                <option key={option} value={option}>
                  {humanize(option)}
                </option>
              ))}
            </Select>
          </div>

          <Select label="Difficulty" {...register('difficulty')}>
            {DIFFICULTIES.map((option) => (
              <option key={option} value={option}>
                {humanize(option)}
              </option>
            ))}
          </Select>
        </section>

        <section className="recipe-form-section">
          <h2 className="recipe-form-section-title">Ingredients</h2>
          <IngredientsEditor control={control} register={register} errors={errors} />
        </section>

        <section className="recipe-form-section">
          <h2 className="recipe-form-section-title">Steps</h2>
          <StepsEditor control={control} register={register} errors={errors} />
        </section>

        <section className="recipe-form-section">
          <h2 className="recipe-form-section-title">Tagging</h2>
          <ChipToggleGroup
            label="Taste tags"
            hint="pick 1–4"
            options={TASTE_TAGS}
            value={tasteTags}
            max={4}
            error={errors.taste_tags?.message}
            onChange={(next) => setValue('taste_tags', next, { shouldValidate: true })}
          />
          <ChipToggleGroup
            label="Dietary flags"
            options={DIETARY_FLAGS}
            value={dietaryFlags}
            onChange={(next) => setValue('dietary_flags', next, { shouldValidate: true })}
          />
          <ChipToggleGroup
            label="Cuisine origin"
            options={CUISINE_ORIGINS}
            value={cuisineOrigin}
            onChange={(next) => setValue('cuisine_origin', next, { shouldValidate: true })}
          />
          <TextField
            label="Allergens"
            placeholder="e.g. peanuts, shellfish"
            {...register('allergens')}
          />
        </section>

        <section className="recipe-form-section">
          <h2 className="recipe-form-section-title">Timing &amp; nutrition</h2>
          <div className="recipe-form-grid recipe-form-grid-4">
            <TextField
              label="Prep (mins)"
              type="number"
              min={0}
              {...register('prep_time_mins', { setValueAs: toNullableNumber })}
            />
            <TextField
              label="Cook (mins)"
              type="number"
              min={0}
              {...register('cook_time_mins', { setValueAs: toNullableNumber })}
            />
            <TextField
              label="Servings"
              type="number"
              min={1}
              {...register('serving_size', { setValueAs: toNullableNumber })}
            />
            <TextField
              label="Calories"
              type="number"
              min={0}
              {...register('calories', { setValueAs: toNullableNumber })}
            />
          </div>
          <div className="recipe-form-grid recipe-form-grid-4">
            <TextField
              label="Protein (g)"
              type="number"
              min={0}
              {...register('protein_g', { setValueAs: toNullableNumber })}
            />
            <TextField
              label="Carbs (g)"
              type="number"
              min={0}
              {...register('carbs_g', { setValueAs: toNullableNumber })}
            />
            <TextField label="Fat (g)" type="number" min={0} {...register('fat_g', { setValueAs: toNullableNumber })} />
          </div>
        </section>

        <section className="recipe-form-section">
          <h2 className="recipe-form-section-title">Publishing</h2>
          <Select label="Save as" {...register('status')}>
            <option value="draft">Draft</option>
            <option value="scheduled">Scheduled</option>
          </Select>
          {status === 'scheduled' && (
            <TextField
              label="Scheduled for"
              type="datetime-local"
              error={errors.scheduled_at?.message}
              {...register('scheduled_at')}
            />
          )}

          {mode === 'edit' && id ? (
            <VideoUploader onUploaded={() => {}} />
          ) : (
            <p className="recipe-form-video-hint">Save this recipe first, then attach a video from the edit screen.</p>
          )}
          <p className="recipe-form-video-hint">
            Going live requires a video and at least one taste tag — use the Publish action from
            the recipes table once you're ready.
          </p>
        </section>

        <div className="recipe-form-actions">
          <Button type="button" variant="ghost" onClick={() => navigate('/admin/recipes')}>
            Cancel
          </Button>
          <Button type="submit" loading={submitting}>
            {mode === 'edit' ? 'Save changes' : 'Save recipe'}
          </Button>
        </div>
      </form>
    </div>
  )
}
