defmodule CaramelKitchenWeb.CollectionControllerTest do
  use CaramelKitchenWeb.ConnCase, async: false

  alias CaramelKitchen.Repo
  alias CaramelKitchen.Collections.CollectionItem

  describe "GET /api/v1/collections (public discovery with filters)" do
    test "lists public collections with metadata", %{conn: conn} do
      user = insert(:user)
      col1 = insert(:collection, user_id: user.id, is_public: true, name: "Family Dinners")
      _private_col = insert(:collection, user_id: user.id, is_public: false, name: "Secret Stash")

      conn = get(conn, "/api/v1/collections")
      body = json_response(conn, 200)

      assert %{"data" => items, "meta" => meta} = body
      assert is_list(items)
      ids = Enum.map(items, & &1["id"])
      assert col1.id in ids
      refute Enum.any?(items, &(&1["name"] == "Secret Stash"))
      assert meta["total_count"] >= 1
    end

    test "filters by recipe_id", %{conn: conn} do
      user = insert(:user)
      r1 = insert(:recipe)
      r2 = insert(:recipe)

      col1 = insert(:collection, user_id: user.id, name: "Curry Night")
      col2 = insert(:collection, user_id: user.id, name: "Pasta Night")

      insert(:collection_item, collection_id: col1.id, recipe_id: r1.id, item_type: "recipe")
      insert(:collection_item, collection_id: col2.id, recipe_id: r2.id, item_type: "recipe")

      conn = get(conn, "/api/v1/collections?recipe_id=#{r1.id}")
      body = json_response(conn, 200)
      ids = Enum.map(body["data"], & &1["id"])

      assert col1.id in ids
      refute col2.id in ids
    end

    test "filters by video_id", %{conn: conn} do
      user = insert(:user)
      v1 = insert(:video)
      v2 = insert(:video)

      col1 = insert(:collection, user_id: user.id, name: "Baking Techniques")
      col2 = insert(:collection, user_id: user.id, name: "Knife Skills")

      insert(:collection_item, collection_id: col1.id, video_id: v1.id, item_type: "video")
      insert(:collection_item, collection_id: col2.id, video_id: v2.id, item_type: "video")

      conn = get(conn, "/api/v1/collections?video_id=#{v1.id}")
      body = json_response(conn, 200)
      ids = Enum.map(body["data"], & &1["id"])

      assert col1.id in ids
      refute col2.id in ids
    end

    test "filters by search and is_curated", %{conn: conn} do
      user = insert(:user)
      col1 = insert(:collection, user_id: user.id, name: "Ultimate Keto", is_curated: true)
      col2 = insert(:collection, user_id: user.id, name: "Comfort Food", is_curated: false)

      conn_search = get(conn, "/api/v1/collections?search=keto")
      search_ids = Enum.map(json_response(conn_search, 200)["data"], & &1["id"])
      assert col1.id in search_ids
      refute col2.id in search_ids

      conn_curated = get(conn, "/api/v1/collections?is_curated=true")
      curated_ids = Enum.map(json_response(conn_curated, 200)["data"], & &1["id"])
      assert col1.id in curated_ids
      refute col2.id in curated_ids
    end

    test "filters by is_premium", %{conn: conn} do
      user = insert(:user)
      col1 = insert(:collection, user_id: user.id, name: "Premium Collection", is_premium: true)
      col2 = insert(:collection, user_id: user.id, name: "Free Collection", is_premium: false)

      conn_prem = get(conn, "/api/v1/collections?is_premium=true")
      body_prem = json_response(conn_prem, 200)
      prem_ids = Enum.map(body_prem["data"], & &1["id"])
      assert col1.id in prem_ids
      refute col2.id in prem_ids

      conn_free = get(conn, "/api/v1/collections?is_premium=false")
      body_free = json_response(conn_free, 200)
      free_ids = Enum.map(body_free["data"], & &1["id"])
      assert col2.id in free_ids
      refute col1.id in free_ids
    end
  end

  describe "GET /api/v1/collections/:id" do
    test "returns full collection detail with recipes and videos", %{conn: conn} do
      user = insert(:user)
      col = insert(:collection, user_id: user.id, name: "Dinner & A Movie")
      recipe = insert(:recipe, title: "Popcorn Chicken")
      video = insert(:video, title: "How to Make Popcorn Chicken")

      insert(:collection_item,
        collection_id: col.id,
        recipe_id: recipe.id,
        item_type: "recipe",
        position: 1
      )

      insert(:collection_item,
        collection_id: col.id,
        video_id: video.id,
        item_type: "video",
        position: 2
      )

      conn = get(conn, "/api/v1/collections/#{col.id}")
      body = json_response(conn, 200)

      assert %{"data" => data} = body
      assert data["id"] == col.id
      assert data["name"] == "Dinner & A Movie"
      assert data["recipe_count"] == 1
      assert data["video_count"] == 1
      assert length(data["items"]) == 2

      recipe_item = Enum.find(data["items"], &(&1["item_type"] == "recipe"))
      assert recipe_item["recipe"]["title"] == "Popcorn Chicken"

      video_item = Enum.find(data["items"], &(&1["item_type"] == "video"))
      assert video_item["video"]["title"] == "How to Make Popcorn Chicken"
    end

    test "returns 404 for private collection to stranger, 200 to owner", %{conn: conn} do
      owner = insert(:user)
      stranger = insert(:user)
      private_col = insert(:collection, user_id: owner.id, is_public: false)

      # Stranger
      conn_stranger =
        conn |> authenticate_conn(stranger) |> get("/api/v1/collections/#{private_col.id}")

      assert json_response(conn_stranger, 404)

      # Owner
      conn_owner =
        conn |> authenticate_conn(owner) |> get("/api/v1/collections/#{private_col.id}")

      assert json_response(conn_owner, 200)["data"]["id"] == private_col.id
    end

    test "premium collection access gating: 402 for free/guest, 200 for owner, premium, and admin", %{conn: conn} do
      owner = insert(:user)
      free_user = insert(:user, subscription_tier: "free")
      premium_user = insert(:premium_user)
      admin = insert(:admin)
      col = insert(:collection, user_id: owner.id, name: "Gourmet Techniques", is_premium: true)

      # Guest: 402
      conn_guest = get(conn, "/api/v1/collections/#{col.id}")
      assert json_response(conn_guest, 402)["error"] == "premium_required"

      # Free user: 402
      conn_free = conn |> authenticate_conn(free_user) |> get("/api/v1/collections/#{col.id}")
      assert json_response(conn_free, 402)["error"] == "premium_required"

      # Owner: 200
      conn_owner = conn |> authenticate_conn(owner) |> get("/api/v1/collections/#{col.id}")
      assert json_response(conn_owner, 200)["data"]["id"] == col.id

      # Premium user: 200
      conn_prem = conn |> authenticate_conn(premium_user) |> get("/api/v1/collections/#{col.id}")
      assert json_response(conn_prem, 200)["data"]["id"] == col.id

      # Admin: 200
      conn_admin = conn |> authenticate_conn(admin) |> get("/api/v1/collections/#{col.id}")
      assert json_response(conn_admin, 200)["data"]["id"] == col.id
    end
  end

  describe "GET /api/v1/me/collections" do
    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/api/v1/me/collections")
      assert json_response(conn, 401)
    end

    test "returns authenticated user's public and private collections", %{conn: conn} do
      user = insert(:user)
      col1 = insert(:collection, user_id: user.id, is_public: true, name: "Public Meal Prep")
      col2 = insert(:collection, user_id: user.id, is_public: false, name: "Private Secrets")

      other_user = insert(:user)
      _other_col = insert(:collection, user_id: other_user.id, name: "Other User Collection")

      conn = conn |> authenticate_conn(user) |> get("/api/v1/me/collections")
      body = json_response(conn, 200)

      ids = Enum.map(body["data"], & &1["id"])
      assert col1.id in ids
      assert col2.id in ids
      assert length(body["data"]) == 2
    end
  end

  describe "POST /api/v1/collections" do
    test "requires authentication", %{conn: conn} do
      conn = post(conn, "/api/v1/collections", %{"name" => "Unauthorized"})
      assert json_response(conn, 401)
    end

    test "creates a collection with attached recipe and video IDs", %{conn: conn} do
      user = insert(:user)
      r1 = insert(:recipe)
      v1 = insert(:video)

      payload = %{
        "name" => "Sunday Meal Prep",
        "description" => "Prep steps for the entire week",
        "is_public" => true,
        "recipe_ids" => [r1.id],
        "video_ids" => [v1.id]
      }

      conn = conn |> authenticate_conn(user) |> post("/api/v1/collections", payload)
      body = json_response(conn, 201)

      assert %{"data" => data} = body
      assert data["name"] == "Sunday Meal Prep"
      assert data["slug"] == "sunday_meal_prep"
      assert data["user_id"] == user.id
      assert data["recipe_count"] == 1
      assert data["video_count"] == 1
      assert length(data["items"]) == 2
      assert data["is_premium"] == false
    end

    test "creates a premium collection", %{conn: conn} do
      user = insert(:user)

      payload = %{
        "name" => "Premium Cooking School",
        "is_premium" => true
      }

      conn = conn |> authenticate_conn(user) |> post("/api/v1/collections", payload)
      body = json_response(conn, 201)
      assert body["data"]["name"] == "Premium Cooking School"
      assert body["data"]["is_premium"] == true
    end
  end

  describe "PUT /api/v1/collections/:id" do
    test "owner can update collection", %{conn: conn} do
      user = insert(:user)
      col = insert(:collection, user_id: user.id, name: "Old Title")

      conn =
        conn
        |> authenticate_conn(user)
        |> put("/api/v1/collections/#{col.id}", %{"name" => "New Title", "is_public" => false})

      body = json_response(conn, 200)

      assert body["data"]["name"] == "New Title"
      assert body["data"]["is_public"] == false
      assert body["data"]["is_premium"] == false
    end

    test "owner can update is_premium status", %{conn: conn} do
      user = insert(:user)
      col = insert(:collection, user_id: user.id, is_premium: false)

      conn =
        conn
        |> authenticate_conn(user)
        |> put("/api/v1/collections/#{col.id}", %{"is_premium" => true})

      body = json_response(conn, 200)
      assert body["data"]["is_premium"] == true
    end

    test "non-owner receives 403 Forbidden", %{conn: conn} do
      owner = insert(:user)
      stranger = insert(:user)
      col = insert(:collection, user_id: owner.id)

      conn =
        conn
        |> authenticate_conn(stranger)
        |> put("/api/v1/collections/#{col.id}", %{"name" => "Hijacked"})

      assert json_response(conn, 403)
    end
  end

  describe "DELETE /api/v1/collections/:id" do
    test "owner can delete collection", %{conn: conn} do
      user = insert(:user)
      col = insert(:collection, user_id: user.id)

      conn = conn |> authenticate_conn(user) |> delete("/api/v1/collections/#{col.id}")
      assert response(conn, 204)

      conn_get = build_conn() |> authenticate_conn(user) |> get("/api/v1/collections/#{col.id}")
      assert json_response(conn_get, 404)
    end

    test "non-owner receives 403 Forbidden", %{conn: conn} do
      owner = insert(:user)
      stranger = insert(:user)
      col = insert(:collection, user_id: owner.id)

      conn = conn |> authenticate_conn(stranger) |> delete("/api/v1/collections/#{col.id}")
      assert json_response(conn, 403)
    end
  end

  describe "Collection items manipulation" do
    test "owner can add and remove items", %{conn: conn} do
      user = insert(:user)
      col = insert(:collection, user_id: user.id)
      recipe = insert(:recipe)

      # Add item
      conn_add =
        conn
        |> authenticate_conn(user)
        |> post("/api/v1/collections/#{col.id}/items", %{
          "recipe_id" => recipe.id,
          "notes" => "Must try with garlic"
        })

      body_add = json_response(conn_add, 201)
      assert %{"data" => item} = body_add
      assert item["recipe_id"] == recipe.id
      assert item["notes"] == "Must try with garlic"
      item_id = item["id"]

      # Remove item
      conn_del =
        conn
        |> authenticate_conn(user)
        |> delete("/api/v1/collections/#{col.id}/items/#{item_id}")

      assert response(conn_del, 204)
      assert Repo.get(CollectionItem, item_id) == nil
    end
  end
end
