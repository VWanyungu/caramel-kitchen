import { zodResolver } from '@hookform/resolvers/zod'
import { useEffect } from 'react'
import { useForm, useWatch } from 'react-hook-form'
import { Link, useNavigate } from 'react-router-dom'
import { z } from 'zod'
import AuthLayout from '../components/auth/AuthLayout'
import Button from '../components/ui/Button'
import PasswordField from '../components/ui/PasswordField'
import TastePill from '../components/ui/TastePill'
import TextField from '../components/ui/TextField'
import { getPasswordStrength } from '../lib/passwordStrength'
import { clearAuthError, registerUser } from '../store/authSlice'
import { useAppDispatch, useAppSelector } from '../store/hooks'
import { roleHomePath } from '../routes/roleHome'

const signupSchema = z
  .object({
    name: z.string().min(1, 'Enter your name'),
    email: z.string().min(1, 'Enter your email address').email('Enter a valid email address'),
    password: z
      .string()
      .min(8, 'Use at least 8 characters')
      .max(72, 'Use 72 characters or fewer')
      .regex(/[0-9]/, 'Include at least one number'),
    password_confirmation: z.string().min(1, 'Confirm your password'),
  })
  .refine((values) => values.password === values.password_confirmation, {
    message: 'Passwords do not match',
    path: ['password_confirmation'],
  })

type SignupFormValues = z.infer<typeof signupSchema>

export default function SignupPage() {
  const dispatch = useAppDispatch()
  const navigate = useNavigate()
  const { status, error, user } = useAppSelector((state) => state.auth)

  const {
    register,
    handleSubmit,
    control,
    formState: { errors },
  } = useForm<SignupFormValues>({ resolver: zodResolver(signupSchema), defaultValues: { password: '' } })

  const password = useWatch({ control, name: 'password' })
  const strength = password ? getPasswordStrength(password) : null

  useEffect(() => {
    dispatch(clearAuthError())
  }, [dispatch])

  useEffect(() => {
    if (user) navigate(roleHomePath(user.role), { replace: true })
  }, [user, navigate])

  const onSubmit = (values: SignupFormValues) => {
    dispatch(registerUser(values))
  }

  return (
    <AuthLayout
      eyebrow="Get started"
      title="Set up your kitchen"
      subtitle="Tell us a little about you — you'll pick your taste profile and goals once you're in."
      footer={
        <p>
          Already have an account? <Link to="/login">Log in</Link>
        </p>
      }
    >
      <form onSubmit={handleSubmit(onSubmit)} noValidate>
        {error && (
          <p className="auth-form-error" role="alert">
            {error}
          </p>
        )}

        <TextField label="Name" autoComplete="name" error={errors.name?.message} {...register('name')} />
        <TextField
          label="Email"
          type="email"
          autoComplete="email"
          error={errors.email?.message}
          {...register('email')}
        />
        <PasswordField
          label="Password"
          autoComplete="new-password"
          error={errors.password?.message}
          {...register('password')}
        />

        {password && (
          <div className="strength-row" aria-live="polite">
            <TastePill label="Weak" tone="spicy" active={strength === 'weak'} />
            <TastePill label="Good" tone="sweet" active={strength === 'good'} />
            <TastePill label="Strong" tone="savory" active={strength === 'strong'} />
          </div>
        )}

        <PasswordField
          label="Confirm password"
          autoComplete="new-password"
          error={errors.password_confirmation?.message}
          {...register('password_confirmation')}
        />

        <Button type="submit" loading={status === 'loading'} style={{ width: '100%' }}>
          Create account
        </Button>
      </form>
    </AuthLayout>
  )
}
