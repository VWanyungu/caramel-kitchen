import { zodResolver } from '@hookform/resolvers/zod'
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { Link, useLocation, useNavigate, type Location } from 'react-router-dom'
import { z } from 'zod'
import AuthLayout from '../components/auth/AuthLayout'
import Button from '../components/ui/Button'
import PasswordField from '../components/ui/PasswordField'
import TextField from '../components/ui/TextField'
import { useAppDispatch, useAppSelector } from '../store/hooks'
import { clearAuthError, loginUser } from '../store/authSlice'
import { roleHomePath } from '../routes/roleHome'

const loginSchema = z.object({
  email: z.string().min(1, 'Enter your email address').email('Enter a valid email address'),
  password: z.string().min(1, 'Enter your password'),
})

type LoginFormValues = z.infer<typeof loginSchema>

export default function LoginPage() {
  const dispatch = useAppDispatch()
  const navigate = useNavigate()
  const location = useLocation()
  const { status, error, user } = useAppSelector((state) => state.auth)

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormValues>({ resolver: zodResolver(loginSchema) })

  useEffect(() => {
    dispatch(clearAuthError())
  }, [dispatch])

  useEffect(() => {
    if (!user) return
    const from = (location.state as { from?: Location } | null)?.from
    navigate(from?.pathname ?? roleHomePath(user.role), { replace: true })
  }, [user, navigate, location.state])

  const onSubmit = (values: LoginFormValues) => {
    dispatch(loginUser(values))
  }

  return (
    <AuthLayout
      eyebrow="Welcome back"
      title="Log in to your kitchen"
      subtitle="Pick up your saved recipes, meal plans, and taste profile right where you left off."
      footer={
        <p>
          New to Caramel Kitchen? <Link to="/signup">Create an account</Link>
        </p>
      }
    >
      <form onSubmit={handleSubmit(onSubmit)} noValidate>
        {error && (
          <p className="form-banner-error" role="alert">
            {error}
          </p>
        )}

        <TextField
          label="Email"
          type="email"
          autoComplete="email"
          error={errors.email?.message}
          {...register('email')}
        />
        <PasswordField
          label="Password"
          autoComplete="current-password"
          error={errors.password?.message}
          {...register('password')}
        />

        <Button type="submit" loading={status === 'loading'} style={{ width: '100%' }}>
          Log in
        </Button>
      </form>
    </AuthLayout>
  )
}
