import { useFieldArray, type Control, type FieldErrors, type UseFormRegister } from 'react-hook-form'
import Button from '../ui/Button'
import type { RecipeFormValues } from '../../lib/recipeFormSchema'
import './recipe-form-rows.css'

interface IngredientsEditorProps {
  control: Control<RecipeFormValues>
  register: UseFormRegister<RecipeFormValues>
  errors: FieldErrors<RecipeFormValues>
}

export default function IngredientsEditor({ control, register, errors }: IngredientsEditorProps) {
  const { fields, append, remove } = useFieldArray({ control, name: 'ingredients' })

  return (
    <div className="row-editor">
      {fields.map((field, index) => (
        <div className="row-editor-row" key={field.id}>
          <input
            className="field-input row-editor-input row-editor-input-name"
            placeholder="Ingredient name"
            aria-label={`Ingredient ${index + 1} name`}
            {...register(`ingredients.${index}.name` as const)}
          />
          <input
            className="field-input row-editor-input row-editor-input-small"
            placeholder="Qty"
            aria-label={`Ingredient ${index + 1} quantity`}
            {...register(`ingredients.${index}.quantity` as const)}
          />
          <input
            className="field-input row-editor-input row-editor-input-small"
            placeholder="Unit"
            aria-label={`Ingredient ${index + 1} unit`}
            {...register(`ingredients.${index}.unit` as const)}
          />
          <button
            type="button"
            className="row-editor-remove"
            aria-label={`Remove ingredient ${index + 1}`}
            onClick={() => remove(index)}
            disabled={fields.length === 1}
          >
            ×
          </button>
        </div>
      ))}
      {errors.ingredients?.message && (
        <p className="field-error" role="alert">
          {errors.ingredients.message as string}
        </p>
      )}
      <Button
        type="button"
        variant="ghost"
        onClick={() => append({ name: '', quantity: '', unit: '', notes: '' })}
      >
        Add ingredient
      </Button>
    </div>
  )
}
