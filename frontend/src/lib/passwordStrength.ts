export type PasswordStrength = 'weak' | 'good' | 'strong'

export function getPasswordStrength(password: string): PasswordStrength {
  if (password.length < 8) return 'weak'

  let score = 0
  if (password.length >= 12) score += 1
  if (/[0-9]/.test(password)) score += 1
  if (/[a-z]/.test(password) && /[A-Z]/.test(password)) score += 1
  if (/[^A-Za-z0-9]/.test(password)) score += 1

  if (score >= 3) return 'strong'
  if (score >= 1) return 'good'
  return 'weak'
}
