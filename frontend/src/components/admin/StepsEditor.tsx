import { useFieldArray, type Control, type FieldErrors, type UseFormRegister } from 'react-hook-form'
import Button from '../ui/Button'
import { toNullableNumber, type RecipeFormValues } from '../../lib/recipeFormSchema'
import './recipe-form-rows.css'

interface StepsEditorProps {
  control: Control<RecipeFormValues>
  register: UseFormRegister<RecipeFormValues>
  errors: FieldErrors<RecipeFormValues>
}

export default function StepsEditor({ control, register, errors }: StepsEditorProps) {
  const { fields, append, remove } = useFieldArray({ control, name: 'steps' })

  return (
    <div className="row-editor">
      {fields.map((field, index) => (
        <div className="row-editor-row row-editor-row-step" key={field.id}>
          <span className="row-editor-step-number">{index + 1}</span>
          <textarea
            className="field-input field-textarea row-editor-input row-editor-input-name"
            placeholder={`Step ${index + 1} instructions`}
            aria-label={`Step ${index + 1} instructions`}
            rows={2}
            {...register(`steps.${index}.instruction` as const)}
          />
          <input
            type="number"
            min={0}
            className="field-input row-editor-input row-editor-input-small"
            placeholder="Mins"
            aria-label={`Step ${index + 1} duration in minutes`}
            {...register(`steps.${index}.duration_minutes` as const, { setValueAs: toNullableNumber })}
          />
          <button
            type="button"
            className="row-editor-remove"
            aria-label={`Remove step ${index + 1}`}
            onClick={() => remove(index)}
            disabled={fields.length === 1}
          >
            ×
          </button>
        </div>
      ))}
      {errors.steps?.message && (
        <p className="field-error" role="alert">
          {errors.steps.message as string}
        </p>
      )}
      <Button
        type="button"
        variant="ghost"
        onClick={() => append({ order: fields.length + 1, instruction: '', duration_minutes: null })}
      >
        Add step
      </Button>
    </div>
  )
}
