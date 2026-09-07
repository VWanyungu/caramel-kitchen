defmodule CaramelKitchen.Factory do
  use ExMachina.Ecto, repo: CaramelKitchen.Repo

  alias CaramelKitchen.Accounts.User
  alias CaramelKitchen.Recipes.Recipe
  alias CaramelKitchen.MealPlans.MealPlan

  alias CaramelKitchen.Monetisation.Subscription
  alias CaramelKitchen.Videos.{Video, UserVideoInteraction}
  alias CaramelKitchen.Taxonomies.Taxonomy
  alias CaramelKitchen.Collections.{Collection, CollectionItem}

  def user_factory do
    %User{
      email: sequence(:email, &"user#{&1}@test.com"),
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      name: sequence(:name, &"Test User #{&1}"),
      role: "user",
      subscription_tier: "free",
      taste_vector: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
      taste_survey_done: false,
      dietary_flags: [],
      allergy_flags: [],
      email_verified: true,
      sign_in_count: 0
    }
  end

  def creator_factory do
    struct!(user_factory(), %{
      role: "creator",
      subscription_tier: "creator_pro"
    })
  end

  def admin_factory do
    struct!(user_factory(), %{
      role: "admin",
      subscription_tier: "creator_pro"
    })
  end

  def premium_user_factory do
    struct!(user_factory(), %{
      subscription_tier: "premium",
      taste_survey_done: true,
      taste_vector: [0.8, 0.3, 0.7, 0.9, 0.6, 0.2, 0.5, 0.1]
    })
  end

  def video_factory(attrs \\ %{}) do
    title = Map.get(attrs, :title) || sequence(:title, &"Test Video #{&1}")
    category = Map.get(attrs, :category, "Recipe_Videos")
    yt_embed = Map.get(attrs, :yt_embed_code, "https://www.youtube.com/watch?v=dQw4w9WgXcQ")

    %Video{
      title: title,
      description: Map.get(attrs, :description, "A test cooking video tutorial"),
      category: category,
      is_premium: Map.get(attrs, :is_premium, false),
      is_special: Map.get(attrs, :is_special, false),
      yt_embed_code: yt_embed,
      youtube_video_id: "dQw4w9WgXcQ",
      video_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      video_embed_url: "https://www.youtube.com/embed/dQw4w9WgXcQ",
      thumbnail_url: "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
      duration_secs: 180,
      view_count: Map.get(attrs, :view_count, 0),
      favorite_count: Map.get(attrs, :favorite_count, 0),
      save_count: Map.get(attrs, :save_count, 0)
    }
  end

  def user_video_interaction_factory(attrs \\ %{}) do
    action = Map.get(attrs, :action, "favorite")

    %UserVideoInteraction{
      user: build(:user),
      video: build(:video),
      action: action,
      metadata: Map.get(attrs, :metadata, %{})
    }
  end

  def recipe_factory(attrs \\ %{}) do
    title = Map.get(attrs, :title) || sequence(:title, &"Test Recipe #{&1}")
    slug = Map.get(attrs, :slug) || sequence(:slug, &"test-recipe-#{&1}")
    creator_id = Map.get(attrs, :creator_id) || insert(:creator).id

    prep_time = Map.get(attrs, :prep_time_mins, 10)
    cook_time = Map.get(attrs, :cook_time_mins, 20)
    total_time = Map.get(attrs, :total_time_mins, prep_time + cook_time)

    recipe = %Recipe{
      creator_id: creator_id,
      slug: slug,
      title: title,
      description: "A delicious test recipe",
      ingredients: [
        %{"name" => "chicken", "quantity" => 500, "unit" => "g"},
        %{"name" => "garlic", "quantity" => 3, "unit" => "cloves"},
        %{"name" => "olive oil", "quantity" => 2, "unit" => "tbsp"}
      ],
      steps: [
        %{"order" => 1, "instruction" => "Heat the oil in a pan"},
        %{"order" => 2, "instruction" => "Add garlic and fry for 1 minute"},
        %{"order" => 3, "instruction" => "Add chicken and cook through"}
      ],
      serving_size: 2,
      dish_category: "meat_dishes",
      dish_categories: ["meat_dishes"],
      course: "main",
      primary_method: "frying",
      difficulty: "intermediate",
      cuisine_origin: ["west_african"],
      prep_time_mins: prep_time,
      cook_time_mins: cook_time,
      total_time_mins: total_time,
      taste_tags: ["savory", "spicy"],
      taste_profile: [0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0],
      dietary_flags: ["halal"],
      allergens: [],
      calories: 450,
      macros: %{"protein_g" => 35, "carbs_g" => 10, "fat_g" => 28},
      status: "live",
      is_special: Map.get(attrs, :is_special, false),
      published_at: DateTime.utc_now() |> DateTime.truncate(:second),
      view_count: 100,
      save_count: 25,
      cook_count: 10,
      avg_rating: Decimal.new("4.2"),
      engagement_score: 0.75
    }

    merge_attributes(recipe, attrs)
  end

  def draft_recipe_factory do
    struct!(recipe_factory(), %{status: "draft", published_at: nil})
  end

  def meal_plan_factory(attrs \\ %{}) do
    meal_plan = %MealPlan{
      user_id: Map.get(attrs, :user_id) || insert(:premium_user).id,
      goal_type: Map.get(attrs, :goal_type, "balanced"),
      name: Map.get(attrs, :name, "Test Meal Plan"),
      week_start: Map.get(attrs, :week_start, Date.utc_today()),
      week_end: Map.get(attrs, :week_end, Date.add(Date.utc_today(), 6)),
      calorie_target: Map.get(attrs, :calorie_target, 2000),
      macro_split: Map.get(attrs, :macro_split, %{protein_pct: 30, carbs_pct: 40, fat_pct: 30}),
      days: Map.get(attrs, :days, []),
      is_ai_generated: Map.get(attrs, :is_ai_generated, false),
      is_active: Map.get(attrs, :is_active, true),
      is_premium: Map.get(attrs, :is_premium, false)
    }

    merge_attributes(meal_plan, attrs)
  end

  def subscription_factory do
    %Subscription{
      user_id: insert(:user).id,
      stripe_customer_id: "cus_test_#{sequence(:stripe_cus, &"#{&1}")}",
      stripe_sub_id: "sub_test_#{sequence(:stripe_sub, &"#{&1}")}",
      plan: "premium",
      status: "active",
      current_period_end:
        DateTime.add(DateTime.utc_now(), 30 * 86_400, :second) |> DateTime.truncate(:second)
    }
  end

  def taxonomy_factory(attrs \\ %{}) do
    type = Map.get(attrs, :type, "category")
    name = Map.get(attrs, :name) || sequence(:taxonomy_name, &"Taxonomy Item #{&1}")
    slug = Map.get(attrs, :slug) || sequence(:taxonomy_slug, &"taxonomy_item_#{&1}")

    taxonomy = %Taxonomy{
      type: to_string(type),
      name: name,
      slug: slug,
      description: Map.get(attrs, :description, "A test taxonomy item"),
      icon_url: Map.get(attrs, :icon_url, "https://example.com/icon.svg"),
      display_order: Map.get(attrs, :display_order, 0),
      is_active: Map.get(attrs, :is_active, true)
    }

    merge_attributes(taxonomy, attrs)
  end

  def collection_factory(attrs \\ %{}) do
    user_id = Map.get(attrs, :user_id) || insert(:user).id
    name = Map.get(attrs, :name) || sequence(:collection_name, &"Collection #{&1}")
    slug = Map.get(attrs, :slug) || sequence(:collection_slug, &"collection_#{&1}")

    collection = %Collection{
      user_id: user_id,
      name: name,
      slug: slug,
      description: Map.get(attrs, :description, "A curated group of recipes and videos"),
      cover_image_url: Map.get(attrs, :cover_image_url),
      is_public: Map.get(attrs, :is_public, true),
      is_curated: Map.get(attrs, :is_curated, false),
      is_premium: Map.get(attrs, :is_premium, false)
    }

    merge_attributes(collection, attrs)
  end

  def collection_item_factory(attrs \\ %{}) do
    collection_id = Map.get(attrs, :collection_id) || insert(:collection).id
    item_type = Map.get(attrs, :item_type, "recipe")

    {recipe_id, video_id} =
      case item_type do
        "recipe" ->
          {Map.get(attrs, :recipe_id) || insert(:recipe).id, nil}

        "video" ->
          {nil, Map.get(attrs, :video_id) || insert(:video).id}
      end

    item = %CollectionItem{
      collection_id: collection_id,
      item_type: item_type,
      recipe_id: recipe_id,
      video_id: video_id,
      position: Map.get(attrs, :position, 1),
      notes: Map.get(attrs, :notes)
    }

    merge_attributes(item, attrs)
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
    pid =
      Ecto.Adapters.SQL.Sandbox.start_owner!(CaramelKitchen.Repo,
        shared: not tags[:async]
      )

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end

defmodule CaramelKitchenWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
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
    conn = %{
      Phoenix.ConnTest.build_conn()
      | remote_ip: {127, 0, rem(System.unique_integer([:positive]), 250) + 1, rem(System.unique_integer([:positive]), 250) + 1}
    }
    {:ok, conn: conn}
  end

  def authenticate_conn(conn, user) do
    {:ok, tokens} = CaramelKitchen.Auth.Guardian.generate_tokens(user)
    Plug.Conn.put_req_header(conn, "authorization", "Bearer #{tokens.access_token}")
  end
end
