defmodule CaramelKitchenWeb.AdminAnalyticsController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Analytics

  # GET /api/v1/admin/analytics
  def index(conn, params) do
    creator = conn.assigns.current_user
    period = String.to_atom(params["period"] || "last_30_days")

    json(conn, %{
      data: %{
        top_recipes: Analytics.top_recipes(creator.id, period: period),
        user_growth: Analytics.user_growth_stats(),
        taste_dist: Analytics.taste_distribution(),
        ai_queries: Analytics.ai_query_stats(creator.id, period)
      }
    })
  end

  # GET /api/v1/admin/analytics/recipes
  def recipes(conn, params) do
    creator = conn.assigns.current_user
    limit = String.to_integer(params["limit"] || "10")
    period = String.to_atom(params["period"] || "last_30_days")

    json(conn, %{data: Analytics.top_recipes(creator.id, limit: limit, period: period)})
  end

  # GET /api/v1/admin/analytics/taste
  def taste_distribution(conn, _params) do
    json(conn, %{data: Analytics.taste_distribution()})
  end

  # GET /api/v1/admin/analytics/ai
  def ai_queries(conn, params) do
    creator = conn.assigns.current_user
    period = String.to_atom(params["period"] || "last_7_days")
    json(conn, %{data: Analytics.ai_query_stats(creator.id, period)})
  end
end

# ── Profile Controller ─────────────────────────────────────────

defmodule CaramelKitchenWeb.ProfileController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.{Accounts, Monetisation}
  alias CaramelKitchen.Accounts.User

  # GET /api/v1/me
  def show(conn, _params) do
    user = conn.assigns.current_user

    sub =
      case Monetisation.get_subscription(user.id) do
        {:ok, s} -> %{plan: s.plan, status: s.status, period_end: s.current_period_end}
        _ -> %{plan: "free", status: "active", period_end: nil}
      end

    json(conn, %{
      data: %{
        id: user.id,
        email: user.email,
        name: user.name,
        avatar_url: user.avatar_url,
        role: user.role,
        subscription_tier: user.subscription_tier,
        taste_survey_done: user.taste_survey_done,
        taste_vector: User.taste_vector_list(user),
        goal_type: user.goal_type,
        dietary_flags: user.dietary_flags,
        allergy_flags: user.allergy_flags,
        cuisine_preferences: user.cuisine_preferences,
        email_verified: user.email_verified,
        sign_in_count: user.sign_in_count,
        last_sign_in_at: user.last_sign_in_at,
        subscription: sub,
        inserted_at: user.inserted_at
      }
    })
  end

  # PUT /api/v1/me
  def update(conn, params) do
    user = conn.assigns.current_user

    with {:ok, updated} <- Accounts.update_profile(user, params) do
      json(conn, %{
        data: %{
          id: updated.id,
          name: updated.name,
          dietary_flags: updated.dietary_flags,
          allergy_flags: updated.allergy_flags,
          cuisine_preferences: updated.cuisine_preferences,
          goal_type: updated.goal_type
        }
      })
    end
  end

  # DELETE /api/v1/me
  def deactivate(conn, params) do
    user = conn.assigns.current_user
    reason = params["reason"]

    with {:ok, _} <- Accounts.deactivate_user(user, reason) do
      # Revoke all tokens
      CaramelKitchen.Auth.Guardian.revoke(conn.assigns.jwt_claims)
      send_resp(conn, :no_content, "")
    end
  end
end

# ── Course Controller ──────────────────────────────────────────

defmodule CaramelKitchenWeb.CourseController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  import Ecto.Query
  alias CaramelKitchen.Repo

  defmodule EventMenu do
    use Ecto.Schema
    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    schema "event_menus" do
      belongs_to :user, CaramelKitchen.Accounts.User
      field :name, :string
      field :courses, :map, default: %{}
      field :notes, :string
      field :event_date, :date
      field :guest_count, :integer, default: 4
      timestamps(type: :utc_datetime)
    end
  end

  def index(conn, _params) do
    user = conn.assigns.current_user

    menus =
      Repo.all(
        from m in EventMenu,
          where: m.user_id == ^user.id,
          order_by: [desc: m.inserted_at],
          limit: 20
      )

    json(conn, %{data: menus})
  end

  def create(conn, params) do
    user = conn.assigns.current_user

    cs =
      Ecto.Changeset.cast(
        %EventMenu{},
        Map.put(params, "user_id", user.id),
        [:name, :courses, :notes, :event_date, :guest_count, :user_id]
      )
      |> Ecto.Changeset.validate_required([:name, :user_id])

    with {:ok, menu} <- Repo.insert(cs) do
      conn |> put_status(:created) |> json(%{data: menu})
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, menu} <- Repo.fetch(from m in EventMenu, where: m.id == ^id) do
      json(conn, %{data: menu})
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, menu} <- Repo.fetch(from m in EventMenu, where: m.id == ^id) do
      cs = Ecto.Changeset.cast(menu, params, [:name, :courses, :notes, :event_date, :guest_count])

      with {:ok, updated} <- Repo.update(cs) do
        json(conn, %{data: updated})
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, menu} <- Repo.fetch(from m in EventMenu, where: m.id == ^id) do
      Repo.delete(menu)
      send_resp(conn, :no_content, "")
    end
  end
end
