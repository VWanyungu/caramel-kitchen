defmodule CaramelKitchen.Factory do
  use ExMachina.Ecto, repo: CaramelKitchen.Repo

  alias CaramelKitchen.Accounts.User
  alias CaramelKitchen.Recipes.Recipe
  alias CaramelKitchen.MealPlans.MealPlan

  alias CaramelKitchen.Monetisation.Subscription

  def user_factory do
    %User{
      email:             sequence(:email, &"user#{&1}@test.com"),
      password_hash:     Bcrypt.hash_pwd_salt("password123"),
      name:              sequence(:name, &"Test User #{&1}"),
      role:              "user",
      subscription_tier: "free",
      taste_vector:      [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
      taste_survey_done: false,
      dietary_flags:     [],
      allergy_flags:     [],
      email_verified:    true,
      sign_in_count:     0
    }
  end

  def creator_factory do
    struct!(user_factory(), %{
      role:              "creator",
      subscription_tier: "creator_pro"
    })
  end

  def premium_user_factory do
    struct!(user_factory(), %{
      subscription_tier: "premium",
      taste_survey_done: true,
      taste_vector:      [0.8, 0.3, 0.7, 0.9, 0.6, 0.2, 0.5, 0.1]
    })
  end

  def recipe_factory(attrs \\ %{}) do
    %Recipe{
      creator_id:      attrs[:creator_id] || insert(:creator).id,
      slug:            sequence(:slug, &"test-recipe-#{&1}"),
      title:           sequence(:title, &"Test Recipe #{&1}"),
      description:     "A delicious test recipe",
      ingredients: [
        %{"name" => "chicken", "quantity" => 500, "unit" => "g"},
        %{"name" => "garlic",  "quantity" => 3,   "unit" => "cloves"},
        %{"name" => "olive oil","quantity" => 2,  "unit" => "tbsp"}
      ],
      steps: [
        %{"order" => 1, "instruction" => "Heat the oil in a pan"},
        %{"order" => 2, "instruction" => "Add garlic and fry for 1 minute"},
        %{"order" => 3, "instruction" => "Add chicken and cook through"}
      ],
      serving_size:    2,
      dish_category:   "meat_dishes",
      course:          "main",
      primary_method:  "frying",
      difficulty:      "intermediate",
      cuisine_origin:  ["west_african"],
      prep_time_mins:  10,
      cook_time_mins:  20,
      total_time_mins: 30,
      taste_tags:      ["savory", "spicy"],
      taste_profile:   [0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0],
      dietary_flags:   ["halal"],
      allergens:       [],
      calories:        450,
      macros:          %{"protein_g" => 35, "carbs_g" => 10, "fat_g" => 28},
      status:          "live",
      published_at:    DateTime.utc_now() |> DateTime.truncate(:second),
      view_count:      100,
      save_count:      25,
      cook_count:      10,
      avg_rating:      Decimal.new("4.2"),
      engagement_score: 0.75
    }
  end

  def draft_recipe_factory do
    struct!(recipe_factory(), %{status: "draft", published_at: nil})
  end

  def meal_plan_factory do
    %MealPlan{
      user_id:        insert(:premium_user).id,
      goal_type:      "balanced",
      name:           "Test Meal Plan",
      week_start:     Date.utc_today(),
      week_end:       Date.add(Date.utc_today(), 6),
      calorie_target: 2000,
      macro_split:    %{protein_pct: 30, carbs_pct: 40, fat_pct: 30},
      days:           [],
      is_ai_generated: false,
      is_active:      true
    }
  end

  def subscription_factory do
    %Subscription{
      user_id:             insert(:user).id,
      stripe_customer_id:  "cus_test_#{sequence(:stripe_cus, &"#{&1}")}",
      stripe_sub_id:       "sub_test_#{sequence(:stripe_sub, &"#{&1}")}",
      plan:                "premium",
      status:              "active",
      current_period_end:  DateTime.add(DateTime.utc_now(), 30 * 86_400, :second) |> DateTime.truncate(:second)
    }
  end
end

defmodule CaramelKitchen.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias CaramelKitchen.Repo
      import Ecto.Query
      import CaramelKitchen.DataCase
      import CaramelKitchen.Factory
    end
  end

  setup tags do
    CaramelKitchen.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(CaramelKitchen.Repo,
      shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end

defmodule CaramelKitchenWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest
      import Plug.Conn
      import Phoenix.ConnTest
      import CaramelKitchen.Factory
      import CaramelKitchenWeb.ConnCase

      alias CaramelKitchenWeb.Router.Helpers, as: Routes
      @endpoint CaramelKitchenWeb.Endpoint
    end
  end

  setup tags do
    CaramelKitchen.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def authenticate_conn(conn, user) do
    {:ok, tokens} = CaramelKitchen.Auth.Guardian.generate_tokens(user)
    Plug.Conn.put_req_header(conn, "authorization", "Bearer #{tokens.access_token}")
  end
end
