defmodule CaramelKitchenWeb.VideoControllerTest do
  use CaramelKitchenWeb.ConnCase, async: false

  describe "GET /api/v1/videos" do
    test "lists all public videos with pagination metadata", %{conn: conn} do
      insert(:video, title: "Knife Skills 101", category: "Cooking_Techniques")
      insert(:video, title: "Sautéing Basics", category: "Cooking_Techniques")

      conn = get(conn, "/api/v1/videos")
      assert %{"data" => videos, "meta" => meta} = json_response(conn, 200)

      assert is_list(videos)
      assert length(videos) >= 2
      assert meta["total_count"] >= 2
    end

    test "filters videos by category", %{conn: conn} do
      insert(:video, title: "Tip 1", category: "Cooking_Tips")
      insert(:video, title: "Recipe 1", category: "Recipe_Videos")

      conn = get(conn, "/api/v1/videos?category=Cooking_Tips")
      assert %{"data" => videos} = json_response(conn, 200)

      assert length(videos) == 1
      assert hd(videos)["title"] == "Tip 1"
    end

    test "filters videos by search term", %{conn: conn} do
      insert(:video, title: "Special Risotto", description: "Creamy arborio rice")
      insert(:video, title: "Simple Salad", description: "Fresh greens")

      conn = get(conn, "/api/v1/videos?search=arborio")
      assert %{"data" => videos} = json_response(conn, 200)

      assert length(videos) == 1
      assert hd(videos)["title"] == "Special Risotto"
    end

    test "filters videos by is_premium", %{conn: conn} do
      insert(:video, title: "Free Tutorial", is_premium: false)
      insert(:video, title: "Pro Masterclass", is_premium: true)

      conn_free = get(conn, "/api/v1/videos?is_premium=false")
      assert %{"data" => free_videos} = json_response(conn_free, 200)
      assert Enum.any?(free_videos, &(&1["title"] == "Free Tutorial"))
      refute Enum.any?(free_videos, &(&1["title"] == "Pro Masterclass"))

      conn_prem = get(conn, "/api/v1/videos?is_premium=true")
      assert %{"data" => prem_videos} = json_response(conn_prem, 200)
      assert Enum.any?(prem_videos, &(&1["title"] == "Pro Masterclass"))
      refute Enum.any?(prem_videos, &(&1["title"] == "Free Tutorial"))
    end
  end

  describe "GET /api/v1/videos/categories" do
    test "returns canonical video categories and counts", %{conn: conn} do
      insert(:video, category: "Tutorials")

      conn = get(conn, "/api/v1/videos/categories")
      assert %{"data" => categories} = json_response(conn, 200)

      assert is_list(categories)
      assert length(categories) == 8
      assert Enum.any?(categories, &(&1["name"] == "Tutorials" && &1["count"] >= 1))
    end
  end

  describe "GET /api/v1/videos/:id and Access Control (Issue #105)" do
    test "returns full details for free video to unauthenticated visitor", %{conn: conn} do
      video = insert(:video, is_premium: false, yt_embed_code: "<iframe>free_code</iframe>")

      conn = get(conn, "/api/v1/videos/#{video.id}")
      assert %{"data" => data} = json_response(conn, 200)

      assert data["id"] == video.id
      assert data["is_locked"] == false
      assert data["yt_embed_code"] == "<iframe>free_code</iframe>"
      assert data["video_embed_url"] != nil
    end

    test "masks embed code for premium video when viewed by unauthenticated or free user", %{
      conn: conn
    } do
      video =
        insert(:video, is_premium: true, yt_embed_code: "<iframe>secret_premium_code</iframe>")

      # 1. Unauthenticated request
      conn_anon = get(conn, "/api/v1/videos/#{video.id}")
      assert %{"data" => data_anon} = json_response(conn_anon, 200)

      assert data_anon["id"] == video.id
      assert data_anon["is_locked"] == true
      assert data_anon["yt_embed_code"] == nil
      assert data_anon["video_embed_url"] == nil

      # 2. Free user request
      free_user = insert(:user, subscription_tier: "free")
      conn_free = conn |> authenticate_conn(free_user) |> get("/api/v1/videos/#{video.id}")
      assert %{"data" => data_free} = json_response(conn_free, 200)

      assert data_free["id"] == video.id
      assert data_free["is_locked"] == true
      assert data_free["yt_embed_code"] == nil
    end

    test "returns full embed code for premium video when viewed by premium user", %{conn: conn} do
      video =
        insert(:video, is_premium: true, yt_embed_code: "<iframe>secret_premium_code</iframe>")

      prem_user = insert(:premium_user)

      conn = conn |> authenticate_conn(prem_user) |> get("/api/v1/videos/#{video.id}")
      assert %{"data" => data} = json_response(conn, 200)

      assert data["id"] == video.id
      assert data["is_locked"] == false
      assert data["yt_embed_code"] == "<iframe>secret_premium_code</iframe>"
      assert data["video_embed_url"] != nil
    end
  end

  describe "Admin Video CRUD" do
    setup %{conn: conn} do
      admin = insert(:admin)
      user = insert(:user)
      admin_conn = authenticate_conn(conn, admin)
      user_conn = authenticate_conn(conn, user)

      {:ok, admin_conn: admin_conn, user_conn: user_conn, admin: admin}
    end

    test "rejects unauthorized access to admin endpoints", %{conn: conn, user_conn: user_conn} do
      # No auth
      assert %{"error" => "unauthorized"} =
               conn |> post("/api/v1/admin/videos", %{}) |> json_response(401)

      # Non-admin user
      assert %{"error" => "forbidden"} =
               user_conn |> post("/api/v1/admin/videos", %{}) |> json_response(403)
    end

    test "admin can create a video", %{admin_conn: conn} do
      attrs = %{
        title: "Chef Masterclass: Sourdough",
        description: "Comprehensive guide to wild fermentation",
        category: "Masterclasses",
        yt_embed_code: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        is_premium: true
      }

      conn = post(conn, "/api/v1/admin/videos", attrs)
      assert %{"data" => data} = json_response(conn, 201)

      assert data["title"] == "Chef Masterclass: Sourdough"
      assert data["category"] == "Masterclasses"
      assert data["is_premium"] == true
      assert data["is_special"] == true
      assert data["youtube_video_id"] == "dQw4w9WgXcQ"
    end

    test "admin can update a video", %{admin_conn: conn} do
      video = insert(:video, title: "Initial Title")

      conn = put(conn, "/api/v1/admin/videos/#{video.id}", %{title: "Updated Title"})
      assert %{"data" => data} = json_response(conn, 200)

      assert data["id"] == video.id
      assert data["title"] == "Updated Title"
    end

    test "admin can delete a video", %{admin_conn: conn} do
      video = insert(:video)

      conn = delete(conn, "/api/v1/admin/videos/#{video.id}")
      assert %{"data" => %{"id" => id, "message" => msg}} = json_response(conn, 200)

      assert id == video.id
      assert msg == "Video deleted successfully"
    end
  end
end
