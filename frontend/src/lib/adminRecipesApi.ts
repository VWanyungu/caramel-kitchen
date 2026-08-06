import axios from 'axios'
import { api } from './api'
import type { AdminRecipe, RecipeStatus } from '../types/recipe'

export async function listRecipes(status?: RecipeStatus | 'all'): Promise<AdminRecipe[]> {
  const params = status && status !== 'all' ? { status } : undefined
  const { data } = await api.get<{ data: AdminRecipe[] }>('/admin/recipes', { params })
  return data.data
}

export async function getRecipe(id: string): Promise<AdminRecipe> {
  const { data } = await api.get<{ data: AdminRecipe }>(`/admin/recipes/${id}`)
  return data.data
}

export async function createRecipe(payload: Record<string, unknown>): Promise<AdminRecipe> {
  const { data } = await api.post<{ data: AdminRecipe }>('/admin/recipes', payload)
  return data.data
}

export async function updateRecipe(id: string, payload: Record<string, unknown>): Promise<AdminRecipe> {
  const { data } = await api.put<{ data: AdminRecipe }>(`/admin/recipes/${id}`, payload)
  return data.data
}

export async function publishRecipe(id: string): Promise<AdminRecipe> {
  const { data } = await api.post<{ data: AdminRecipe }>(`/admin/recipes/${id}/publish`)
  return data.data
}

export async function archiveRecipe(id: string): Promise<AdminRecipe> {
  const { data } = await api.post<{ data: AdminRecipe }>(`/admin/recipes/${id}/archive`)
  return data.data
}

export async function deleteRecipe(id: string): Promise<void> {
  await api.delete(`/admin/recipes/${id}`)
}

interface PresignedUrlResponse {
  upload_url?: string
  url?: string
  video_key?: string
  key?: string
}

export async function uploadRecipeVideo(
  file: File,
  onProgress?: (percent: number) => void,
): Promise<{ videoKey: string | null }> {
  const { data } = await api.post<{ data: PresignedUrlResponse } | PresignedUrlResponse>(
    '/admin/videos/presigned-url',
    { filename: file.name, content_type: file.type, size_bytes: file.size },
  )
  const body = 'data' in data && data.data ? data.data : (data as PresignedUrlResponse)
  const uploadUrl = body.upload_url ?? body.url
  const videoKey = body.video_key ?? body.key ?? null

  if (!uploadUrl) throw new Error('No upload URL returned by the server.')

  await axios.put(uploadUrl, file, {
    headers: { 'Content-Type': file.type },
    onUploadProgress: (event) => {
      if (!onProgress || !event.total) return
      onProgress(Math.round((event.loaded / event.total) * 100))
    },
  })

  return { videoKey }
}
