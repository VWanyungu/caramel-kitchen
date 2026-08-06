import type { FilterPreset, RecipeFilters } from '../types/browse'

const PRESETS_KEY = 'caramel.filterPresets'

export function listPresets(): FilterPreset[] {
  const raw = localStorage.getItem(PRESETS_KEY)
  if (!raw) return []
  try {
    return JSON.parse(raw) as FilterPreset[]
  } catch {
    return []
  }
}

export function savePreset(name: string, filters: RecipeFilters): FilterPreset {
  const preset: FilterPreset = {
    id: crypto.randomUUID(),
    name,
    filters,
    createdAt: new Date().toISOString(),
  }
  const presets = [...listPresets(), preset]
  localStorage.setItem(PRESETS_KEY, JSON.stringify(presets))
  return preset
}

export function deletePreset(id: string): void {
  const presets = listPresets().filter((preset) => preset.id !== id)
  localStorage.setItem(PRESETS_KEY, JSON.stringify(presets))
}
