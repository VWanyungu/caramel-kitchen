defmodule CaramelKitchen.Mailer do
  use Swoosh.Mailer, otp_app: :caramel_kitchen
end

defmodule CaramelKitchen.Emails do
  @moduledoc """
  All transactional email templates for Caramel Kitchen.
  Uses Swoosh for delivery — adapter configured per environment
  (Mailgun in prod, Local adapter in dev, Test adapter in test).
  """
  import Swoosh.Email

  @from_email "hello@caramelkitchen.app"
  @from_name  "Caramel Kitchen"
  @app_url    Application.compile_env(:caramel_kitchen, :app_url, "https://caramelkitchen.app")

  # ── Email Verification ────────────────────────────────────────

  def verify_email(user, token) do
    link = "#{@app_url}/auth/verify-email/#{token}"

    new()
    |> to({user.name, user.email})
    |> from({@from_name, @from_email})
    |> subject("Verify your Caramel Kitchen email")
    |> html_body("""
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:32px">
      <h1 style="color:#C97B2F;font-size:28px;margin-bottom:4px">Caramel Kitchen</h1>
      <p style="color:#666;margin-bottom:32px;font-style:italic">A warm digital kitchen</p>

      <h2 style="color:#1A1A1A">Welcome, #{user.name}! 👋</h2>
      <p style="color:#444;line-height:1.6">
        You're almost ready to discover personalised recipes, build meal plans,
        and cook with AI-powered guidance. Just verify your email to get started.
      </p>

      <a href="#{link}"
         style="display:inline-block;background:#C97B2F;color:#fff;padding:14px 28px;
                border-radius:8px;text-decoration:none;font-weight:bold;margin:24px 0">
        Verify My Email
      </a>

      <p style="color:#999;font-size:13px">
        Link expires in 24 hours. If you didn't create an account, ignore this email.
      </p>

      <hr style="border:none;border-top:1px solid #eee;margin:32px 0"/>
      <p style="color:#bbb;font-size:12px">© #{Date.utc_today().year} Caramel Kitchen</p>
    </div>
    """)
    |> text_body("""
    Welcome to Caramel Kitchen, #{user.name}!

    Verify your email: #{link}

    Link expires in 24 hours.
    """)
  end

  # ── Password Reset ────────────────────────────────────────────

  def password_reset(user, token) do
    link = "#{@app_url}/auth/reset-password/#{token}"

    new()
    |> to({user.name, user.email})
    |> from({@from_name, @from_email})
    |> subject("Reset your Caramel Kitchen password")
    |> html_body("""
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:32px">
      <h1 style="color:#C97B2F;font-size:28px">Caramel Kitchen</h1>

      <h2 style="color:#1A1A1A">Reset your password</h2>
      <p style="color:#444;line-height:1.6">
        We received a request to reset your password. Click the button below.
        This link expires in 1 hour.
      </p>

      <a href="#{link}"
         style="display:inline-block;background:#1A1A1A;color:#fff;padding:14px 28px;
                border-radius:8px;text-decoration:none;font-weight:bold;margin:24px 0">
        Reset Password
      </a>

      <p style="color:#999;font-size:13px">
        If you didn't request this, your account is safe — just ignore this email.
      </p>
    </div>
    """)
    |> text_body("Reset your Caramel Kitchen password: #{link}\n\nExpires in 1 hour.")
  end

  # ── Welcome (post-verification) ───────────────────────────────

  def welcome(user) do
    new()
    |> to({user.name, user.email})
    |> from({@from_name, @from_email})
    |> subject("Your kitchen is ready 🍳")
    |> html_body("""
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:32px">
      <h1 style="color:#C97B2F;font-size:28px">Caramel Kitchen</h1>

      <h2 style="color:#1A1A1A">Your kitchen is ready, #{user.name}!</h2>
      <p style="color:#444;line-height:1.6">
        Start by completing your taste survey — it takes 30 seconds and unlocks
        a fully personalised recipe feed just for you.
      </p>

      <a href="#{@app_url}/taste/survey"
         style="display:inline-block;background:#C97B2F;color:#fff;padding:14px 28px;
                border-radius:8px;text-decoration:none;font-weight:bold;margin:24px 0">
        Take My Taste Survey →
      </a>

      <div style="background:#FFF8E1;border-left:4px solid #C97B2F;padding:16px;border-radius:4px;margin:24px 0">
        <strong>What's waiting for you:</strong>
        <ul style="margin:8px 0;padding-left:20px;color:#444">
          <li>Recipes ranked by your personal taste profile</li>
          <li>AI assistant that knows what you like to eat</li>
          <li>Goal-driven meal plans (gym, weight loss, keto, and more)</li>
          <li>Voice cooking mode — hands-free step-by-step guidance</li>
        </ul>
      </div>
    </div>
    """)
    |> text_body("Your Caramel Kitchen is ready! Start your taste survey: #{@app_url}/taste/survey")
  end

  # ── Meal Plan Reminder ────────────────────────────────────────

  def meal_plan_reminder(user, plan) do
    new()
    |> to({user.name, user.email})
    |> from({@from_name, @from_email})
    |> subject("🍽 Your #{plan.name} starts today")
    |> html_body("""
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:32px">
      <h1 style="color:#C97B2F;font-size:28px">Caramel Kitchen</h1>

      <h2>Your meal plan starts today 🎯</h2>
      <p style="color:#444;line-height:1.6">
        Your <strong>#{plan.name}</strong> is ready.
        Target: <strong>#{plan.calorie_target} kcal/day</strong>.
      </p>

      <a href="#{@app_url}/planner"
         style="display:inline-block;background:#C97B2F;color:#fff;padding:14px 28px;
                border-radius:8px;text-decoration:none;font-weight:bold;margin:24px 0">
        View My Plan →
      </a>
    </div>
    """)
    |> text_body("Your #{plan.name} starts today! View it: #{@app_url}/planner")
  end

  # ── Subscription Confirmation ─────────────────────────────────

  def subscription_confirmed(user, plan) do
    plan_name = if plan == "premium", do: "Premium", else: "Creator Pro"

    new()
    |> to({user.name, user.email})
    |> from({@from_name, @from_email})
    |> subject("Welcome to Caramel Kitchen #{plan_name} ⭐")
    |> html_body("""
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:32px">
      <h1 style="color:#C97B2F;font-size:28px">Caramel Kitchen</h1>

      <h2>You're now #{plan_name}! 🎉</h2>
      <p style="color:#444;line-height:1.6">
        Thank you, #{user.name}. Your #{plan_name} features are now active.
      </p>

      <div style="background:#E8F5E9;border-left:4px solid #2E7D32;padding:16px;border-radius:4px;margin:24px 0">
        <strong>Now unlocked:</strong>
        <ul style="margin:8px 0;padding-left:20px;color:#444">
          <li>Unlimited AI assistant access</li>
          <li>Goal-driven meal plan generation</li>
          <li>Voice cooking mode</li>
          <li>7-course menu builder</li>
          <li>Offline video downloads</li>
        </ul>
      </div>

      <a href="#{@app_url}/planner/generate"
         style="display:inline-block;background:#C97B2F;color:#fff;padding:14px 28px;
                border-radius:8px;text-decoration:none;font-weight:bold">
        Generate My First Meal Plan →
      </a>
    </div>
    """)
    |> text_body("Welcome to #{plan_name}, #{user.name}! Your features are active: #{@app_url}")
  end

  # ── Payment Failed ────────────────────────────────────────────

  def payment_failed(user) do
    new()
    |> to({user.name, user.email})
    |> from({@from_name, @from_email})
    |> subject("Action needed: Payment failed")
    |> html_body("""
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;padding:32px">
      <h1 style="color:#C97B2F;font-size:28px">Caramel Kitchen</h1>

      <h2 style="color:#C62828">Payment failed</h2>
      <p style="color:#444;line-height:1.6">
        Hi #{user.name}, we couldn't process your subscription payment.
        You have a 3-day grace period to update your payment details
        before your Premium access is paused.
      </p>

      <a href="#{@app_url}/subscription/portal"
         style="display:inline-block;background:#C62828;color:#fff;padding:14px 28px;
                border-radius:8px;text-decoration:none;font-weight:bold;margin:24px 0">
        Update Payment Details →
      </a>
    </div>
    """)
    |> text_body("Payment failed for #{user.name}. Update details: #{@app_url}/subscription/portal")
  end
end
