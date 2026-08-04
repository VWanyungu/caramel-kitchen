import type { Role } from '../types/auth'

export function roleHomePath(role: Role): string {
  return role === 'admin' ? '/admin' : '/home'
}
