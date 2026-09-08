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

  describe "Collection save interactions" do
    test "authenticates save and unsave", %{conn: conn} do
      col = insert(:collection)

      conn_unauth = post(conn, "/api/v1/collections/#{col.id}/save")
      assert json_response(conn_unauth, 401)

      conn_unauth_del = delete(conn, "/api/v1/collections/#{col.id}/save")
      assert json_response(conn_unauth_del, 401)
    end

    test "saves, gets status, and unsaves collection", %{conn: conn} do
      user = insert(:user)
      col = insert(:collection, save_count: 0)

      # 1. Save
      conn_save = conn |> authenticate_conn(user) |> post("/api/v1/collections/#{col.id}/save")
      body_save = json_response(conn_save, 200)["data"]
      assert body_save["collection_id"] == col.id
      assert body_save["is_saved"] == true
      assert body_save["save_count"] == 1

      # 2. Status
      conn_stat = conn |> authenticate_conn(user) |> get("/api/v1/collections/#{col.id}/status")
      body_stat = json_response(conn_stat, 200)["data"]
      assert body_stat["is_saved"] == true
      assert body_stat["save_count"] == 1

      # 3. List saved
      conn_list = conn |> authenticate_conn(user) |> get("/api/v1/me/collections/saved")
      body_list = json_response(conn_list, 200)
      assert length(body_list["data"]) == 1
      assert hd(body_list["data"])["id"] == col.id
      assert hd(body_list["data"])["is_saved"] == true

      # 4. Unsave
      conn_unsave = conn |> authenticate_conn(user) |> delete("/api/v1/collections/#{col.id}/save")
      body_unsave = json_response(conn_unsave, 200)["data"]
      assert body_unsave["is_saved"] == false
      assert body_unsave["save_count"] == 0

      # 5. Status after unsave
      conn_stat2 = conn |> authenticate_conn(user) |> get("/api/v1/collections/#{col.id}/status")
      assert json_response(conn_stat2, 200)["data"]["is_saved"] == false
    end
  end

  describe "Seasonal Collections" do
    test "GET /api/v1/collections/seasonal and /api/v1/premium/collections/seasonal returns active seasonal collections", %{conn: conn} do
      user = insert(:user)
      today = Date.utc_today()

      active_col =
        insert(:collection,
          user_id: user.id,
          name: "Active Season Treat",
          is_seasonal: true,
          season_name: "Back to School",
          start_date: Date.add(today, -5),
          end_date: Date.add(today, 10),
          is_premium: true
        )

      future_col =
        insert(:collection,
          user_id: user.id,
          name: "Future Season Roast",
          is_seasonal: true,
          season_name: "Christmas",
          start_date: Date.add(today, 30),
          end_date: Date.add(today, 60),
          is_premium: true
        )

      # 1. /collections/seasonal
      conn_resp1 = get(conn, "/api/v1/collections/seasonal")
      assert conn_resp1.status == 200
      body1 = json_response(conn_resp1, 200)
      ids1 = Enum.map(body1["data"], & &1["id"])

      assert active_col.id in ids1
      refute future_col.id in ids1
      assert is_list(body1["seasons"])
      season_group = Enum.find(body1["seasons"], &(&1["season_name"] == "Back to School"))
      assert season_group != nil

      # 2. /premium/collections/seasonal
      conn_resp2 = get(conn, "/api/v1/premium/collections/seasonal")
      assert conn_resp2.status == 200
      body2 = json_response(conn_resp2, 200)
      ids2 = Enum.map(body2["data"], & &1["id"])
      assert active_col.id in ids2
      refute future_col.id in ids2

      # 3. Filter by season_name
      conn_filter = get(conn, "/api/v1/collections/seasonal?season_name=Back to School")
      body_filter = json_response(conn_filter, 200)
      assert length(body_filter["data"]) >= 1
      assert Enum.all?(body_filter["data"], &(&1["season_name"] == "Back to School"))
    end

    test "GET /api/v1/collections?is_seasonal=true filters properly", %{conn: conn} do
      user = insert(:user)
      today = Date.utc_today()

      regular_col = insert(:collection, user_id: user.id, is_seasonal: false)
      seasonal_col =
        insert(:collection,
          user_id: user.id,
          is_seasonal: true,
          season_name: "Ramadan",
          start_date: Date.add(today, -2),
          end_date: Date.add(today, 20),
          is_premium: true
        )

      conn_resp = get(conn, "/api/v1/collections?is_seasonal=true")
      assert conn_resp.status == 200
      ids = Enum.map(json_response(conn_resp, 200)["data"], & &1["id"])

      assert seasonal_col.id in ids
      refute regular_col.id in ids
    end

    test "GET /api/v1/collections/:id returns 404 for out-of-season collection to regular user, 200 to admin", %{conn: conn} do
      owner = insert(:user)
      regular_user = insert(:user)
      admin = insert(:admin)
      today = Date.utc_today()

      out_of_season =
        insert(:collection,
          user_id: owner.id,
          name: "Christmas Dinner",
          is_seasonal: true,
          season_name: "Christmas",
          start_date: Date.add(today, 40),
          end_date: Date.add(today, 80),
          is_premium: false
        )

      # Regular user gets 404
      conn_reg = conn |> authenticate_conn(regular_user) |> get("/api/v1/collections/#{out_of_season.id}")
      assert json_response(conn_reg, 404)

      # Admin gets 200
      conn_admin = conn |> authenticate_conn(admin) |> get("/api/v1/collections/#{out_of_season.id}")
      assert json_response(conn_admin, 200)["data"]["id"] == out_of_season.id
    end
  end
end
