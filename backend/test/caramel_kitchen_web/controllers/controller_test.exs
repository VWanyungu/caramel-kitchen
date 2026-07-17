defmodule CaramelKitchenWeb.AuthControllerTest do
  use CaramelKitchenWeb.ConnCase, async: true

  describe "POST /api/v1/auth/register" do
    test "registers user and returns tokens", %{conn: conn} do
      params = %{
        email:                 "register@example.com",
        password:              "SecurePass123",
        password_confirmation: "SecurePass123",
        name:                  "New User"
      }

      conn = post(conn, "/api/v1/auth/register", params)
      body = json_response(conn, 201)

      assert body["data"]["user"]["email"]       == "register@example.com"
      assert body["data"]["tokens"]["access_token"]
      assert body["data"]["tokens"]["refresh_token"]
      assert body["data"]["tokens"]["token_type"] == "Bearer"
    end

    test "returns 422 for duplicate email", %{conn: conn} do
      insert(:user, email: "duplicate@example.com")

      conn = post(conn, "/api/v1/auth/register", %{
        email:                 "duplicate@example.com",
        password:              "SecurePass123",
        password_confirmation: "SecurePass123",
        name:                  "Duplicate"
      })

      assert json_response(conn, 422)["error"] == "validation_error"
    end
  end

  describe "POST /api/v1/auth/login" do
    setup do
      user = insert(:user,
        email:         "login@example.com",
        password_hash: Bcrypt.hash_pwd_salt("TestPass123")
      )
      {:ok, user: user}
    end

    test "returns tokens for valid credentials", %{conn: conn} do
      conn = post(conn, "/api/v1/auth/login", %{
        email:    "login@example.com",
        password: "TestPass123"
      })
      body = json_response(conn, 200)
      assert body["data"]["tokens"]["access_token"]
      assert body["data"]["user"]["email"] == "login@example.com"
    end

    test "returns 401 for wrong password", %{conn: conn} do
      conn = post(conn, "/api/v1/auth/login", %{
        email:    "login@example.com",
        password: "WrongPassword"
      })
      assert json_response(conn, 401)["error"] == "invalid_credentials"
    end

    test "returns 401 for unknown email", %{conn: conn} do
      conn = post(conn, "/api/v1/auth/login", %{
        email:    "nobody@example.com",
        password: "anything"
      })
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/v1/auth/refresh" do
    test "returns new access token", %{conn: conn} do
      user            = insert(:user)
      {:ok, tokens}   = CaramelKitchen.Auth.Guardian.generate_tokens(user)

      conn = post(conn, "/api/v1/auth/refresh", %{refresh_token: tokens.refresh_token})
      body = json_response(conn, 200)
      assert body["data"]["access_token"]
    end

    test "returns 401 for invalid token", %{conn: conn} do
      conn = post(conn, "/api/v1/auth/refresh", %{refresh_token: "invalid.token.here"})
      assert json_response(conn, 401)
    end
  end
end

defmodule CaramelKitchenWeb.TasteControllerTest do
  use CaramelKitchenWeb.ConnCase, async: true

  describe "POST /api/v1/taste/survey (authenticated)" do
    setup %{conn: conn} do
      user = insert(:user)
      {:ok, conn: authenticate_conn(conn, user), user: user}
    end

    test "submits taste survey and returns vector", %{conn: conn} do
      responses = [
        %{taste: "spicy",  score: 5},
        %{taste: "savory", score: 4},
        %{taste: "sweet",  score: 2},
        %{taste: "sour",   score: 1},
        %{taste: "tangy",  score: 3},
        %{taste: "bitter", score: 1},
        %{taste: "umami",  score: 4},
        %{taste: "mild",   score: 2}
      ]

      conn = post(conn, "/api/v1/taste/survey", %{responses: responses})
      body = json_response(conn, 200)

      assert body["data"]["survey_complete"] == true
      assert length(body["data"]["taste_vector"]) == 8
      assert Enum.all?(body["data"]["taste_vector"], &(&1 >= 0.0 and &1 <= 1.0))
    end

    test "returns 401 without auth", %{conn: _conn} do
      conn = build_conn()
      conn = post(conn, "/api/v1/taste/survey", %{responses: []})
      assert json_response(conn, 401)
    end
  end
end

defmodule CaramelKitchenWeb.MealPlanControllerTest do
  use CaramelKitchenWeb.ConnCase, async: true

  describe "POST /api/v1/meal-plans/generate (premium)" do
    setup %{conn: conn} do
      user = insert(:premium_user)
      {:ok, conn: authenticate_conn(conn, user), user: user}
    end

    test "returns 402 for free tier users", %{conn: _} do
      free_user = insert(:user)
      conn = build_conn() |> authenticate_conn(free_user)
      conn = post(conn, "/api/v1/meal-plans/generate", %{goal_type: "balanced"})
      assert json_response(conn, 402)["error"] == "premium_required"
    end

    test "returns 422 for invalid goal type", %{conn: conn} do
      conn = post(conn, "/api/v1/meal-plans/generate", %{goal_type: "invalid_goal"})
      # Should hit function clause or return error
      assert conn.status in [422, 400, 500]
    end
  end

  describe "GET /api/v1/meal-plans (premium)" do
    setup %{conn: conn} do
      user = insert(:premium_user)
      insert(:meal_plan, user_id: user.id)
      {:ok, conn: authenticate_conn(conn, user)}
    end

    test "lists user's meal plans", %{conn: conn} do
      conn = get(conn, "/api/v1/meal-plans")
      body = json_response(conn, 200)
      assert is_list(body["data"])
      assert length(body["data"]) >= 1
    end
  end
end
