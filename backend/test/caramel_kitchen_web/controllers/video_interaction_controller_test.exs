defmodule CaramelKitchenWeb.VideoInteractionControllerTest do
  use CaramelKitchenWeb.ConnCase, async: false

  describe "Authentication requirement" do
    test "returns 401 unauthorized for guest requests to interaction endpoints", %{conn: conn} do
      video = insert(:video)

      assert conn |> post("/api/v1/videos/#{video.id}/favorite") |> json_response(401)
      assert conn |> post("/api/v1/videos/#{video.id}/save") |> json_response(401)
      assert conn |> delete("/api/v1/videos/#{video.id}/favorite") |> json_response(401)
      assert conn |> delete("/api/v1/videos/#{video.id}/save") |> json_response(401)
      assert conn |> get("/api/v1/me/videos/favorites") |> json_response(401)
      assert conn |> get("/api/v1/me/videos/saved") |> json_response(401)
    end
  end

  describe "POST and DELETE /api/v1/videos/:id/favorite (and /favourite)" do
    test "authenticates user, favorites video, and increments favorite count", %{conn: conn} do
      user = insert(:user)
      video = insert(:video, favorite_count: 0)

      conn_fav =
        conn
        |> authenticate_conn(user)
        |> post("/api/v1/videos/#{video.id}/favorite")

      assert %{"data" => data} = json_response(conn_fav, 200)
      assert data["video_id"] == video.id
      assert data["action"] == "favorite"
      assert data["status"] == "favorited"
      assert data["is_favorited"] == true
      assert data["is_saved"] == false
      assert data["favorite_count"] == 1
      assert data["interacted_at"] != nil
    end

    test "supports British spelling /favourite", %{conn: conn} do
      user = insert(:user)
      video = insert(:video, favorite_count: 0)

      conn_fav =
        conn
        |> authenticate_conn(user)
        |> post("/api/v1/videos/#{video.id}/favourite")

      assert %{"data" => data} = json_response(conn_fav, 200)
      assert data["status"] == "favorited"
      assert data["is_favorited"] == true
    end

    test "unfavorites video via DELETE and POST /unfavorite", %{conn: conn} do
      user = insert(:user)
      video = insert(:video, favorite_count: 0)

      # Favorite it first
      conn |> authenticate_conn(user) |> post("/api/v1/videos/#{video.id}/favorite")

      # Unfavorite via DELETE
      conn_unfav =
        conn
        |> authenticate_conn(user)
        |> delete("/api/v1/videos/#{video.id}/favorite")

      assert %{"data" => data} = json_response(conn_unfav, 200)
      assert data["status"] == "unfavorited"
      assert data["is_favorited"] == false
      assert data["favorite_count"] == 0

      # Re-favorite and unfavorite via POST /unfavorite
      conn |> authenticate_conn(user) |> post("/api/v1/videos/#{video.id}/favorite")

      conn_post_unfav =
        conn
        |> authenticate_conn(user)
        |> post("/api/v1/videos/#{video.id}/unfavorite")

      assert %{"data" => post_data} = json_response(conn_post_unfav, 200)
      assert post_data["status"] == "unfavorited"
      assert post_data["is_favorited"] == false
    end
  end

  describe "POST and DELETE /api/v1/videos/:id/save" do
    test "authenticates user, saves video to watch later, and increments save count", %{conn: conn} do
      user = insert(:user)
      video = insert(:video, save_count: 0)

      conn_save =
        conn
        |> authenticate_conn(user)
        |> post("/api/v1/videos/#{video.id}/save")

      assert %{"data" => data} = json_response(conn_save, 200)
      assert data["video_id"] == video.id
      assert data["action"] == "saved"
      assert data["status"] == "saved"
      assert data["is_saved"] == true
      assert data["is_favorited"] == false
      assert data["save_count"] == 1
      assert data["interacted_at"] != nil
    end

    test "unsaves video via DELETE and POST /unsave", %{conn: conn} do
      user = insert(:user)
      video = insert(:video, save_count: 0)

      # Save first
      conn |> authenticate_conn(user) |> post("/api/v1/videos/#{video.id}/save")

      # Unsave via DELETE
      conn_unsave =
        conn
        |> authenticate_conn(user)
        |> delete("/api/v1/videos/#{video.id}/save")

      assert %{"data" => data} = json_response(conn_unsave, 200)
      assert data["status"] == "unsaved"
      assert data["is_saved"] == false
      assert data["save_count"] == 0

      # Save again and unsave via POST /unsave
      conn |> authenticate_conn(user) |> post("/api/v1/videos/#{video.id}/save")

      conn_post_unsave =
        conn
        |> authenticate_conn(user)
        |> post("/api/v1/videos/#{video.id}/unsave")

      assert %{"data" => post_data} = json_response(conn_post_unsave, 200)
      assert post_data["status"] == "unsaved"
      assert post_data["is_saved"] == false
    end
  end

  describe "Separation of Favourite and Saved in Controller & Status endpoint" do
    test "maintains both states separately and returns status via GET /videos/:id/status", %{
      conn: conn
    } do
      user = insert(:user)
      video = insert(:video, title: "Dual State Video", favorite_count: 0, save_count: 0)

      auth_conn = authenticate_conn(conn, user)

      # 1. Favorite
      auth_conn |> post("/api/v1/videos/#{video.id}/favorite")

      status1 = auth_conn |> get("/api/v1/videos/#{video.id}/status") |> json_response(200)
      assert status1["data"]["is_favorited"] == true
      assert status1["data"]["is_saved"] == false
      assert status1["data"]["favorite_count"] == 1
      assert status1["data"]["save_count"] == 0

      # 2. Save
      auth_conn |> post("/api/v1/videos/#{video.id}/save")

      status2 = auth_conn |> get("/api/v1/videos/#{video.id}/status") |> json_response(200)
      assert status2["data"]["is_favorited"] == true
      assert status2["data"]["is_saved"] == true
      assert status2["data"]["favorite_count"] == 1
      assert status2["data"]["save_count"] == 1

      # 3. Public video show also includes flags for authenticated user
      show_res = auth_conn |> get("/api/v1/videos/#{video.id}") |> json_response(200)
      assert show_res["data"]["is_favorited"] == true
      assert show_res["data"]["is_saved"] == true
      assert show_res["data"]["favorite_count"] == 1
      assert show_res["data"]["save_count"] == 1

      # 4. Unfavorite does not remove saved
      auth_conn |> delete("/api/v1/videos/#{video.id}/favorite")

      status3 = auth_conn |> get("/api/v1/videos/#{video.id}/status") |> json_response(200)
      assert status3["data"]["is_favorited"] == false
      assert status3["data"]["is_saved"] == true
    end

    test "status endpoint works for unauthenticated guests", %{conn: conn} do
      video = insert(:video, favorite_count: 3, save_count: 5)

      status = conn |> get("/api/v1/videos/#{video.id}/status") |> json_response(200)
      assert status["data"]["is_favorited"] == false
      assert status["data"]["is_saved"] == false
      assert status["data"]["favorite_count"] == 3
      assert status["data"]["save_count"] == 5
    end
  end

  describe "GET /api/v1/me/videos/favorites and GET /api/v1/me/videos/saved" do
    test "lists favorited videos with metadata and timestamps", %{conn: conn} do
      user = insert(:user)
      v1 = insert(:video, title: "Favorite 1")
      v2 = insert(:video, title: "Favorite 2")
      _v3 = insert(:video, title: "Other Video")

      auth_conn = authenticate_conn(conn, user)
      auth_conn |> post("/api/v1/videos/#{v1.id}/favorite")
      auth_conn |> post("/api/v1/videos/#{v2.id}/favorite")

      res = auth_conn |> get("/api/v1/me/videos/favorites") |> json_response(200)
      assert %{"data" => items, "meta" => meta} = res

      assert length(items) == 2
      assert meta["total_count"] == 2
      assert Enum.any?(items, &(&1["title"] == "Favorite 1"))
      assert Enum.any?(items, &(&1["title"] == "Favorite 2"))
      assert Enum.all?(items, &(&1["is_favorited"] == true))
      assert Enum.all?(items, &(&1["favorited_at"] != nil))

      # Test alias /me/videos/favourites
      res_uk = auth_conn |> get("/api/v1/me/videos/favourites") |> json_response(200)
      assert length(res_uk["data"]) == 2

      # Test alias /me/favorites/videos
      res_alias = auth_conn |> get("/api/v1/me/favorites/videos") |> json_response(200)
      assert length(res_alias["data"]) == 2
    end

    test "lists saved watch-later videos with metadata and timestamps", %{conn: conn} do
      user = insert(:user)
      v1 = insert(:video, title: "Watch Later A")
      v2 = insert(:video, title: "Watch Later B")

      auth_conn = authenticate_conn(conn, user)
      auth_conn |> post("/api/v1/videos/#{v1.id}/save")
      auth_conn |> post("/api/v1/videos/#{v2.id}/save")

      res = auth_conn |> get("/api/v1/me/videos/saved") |> json_response(200)
      assert %{"data" => items, "meta" => meta} = res

      assert length(items) == 2
      assert meta["total_count"] == 2
      assert Enum.any?(items, &(&1["title"] == "Watch Later A"))
      assert Enum.any?(items, &(&1["title"] == "Watch Later B"))
      assert Enum.all?(items, &(&1["is_saved"] == true))
      assert Enum.all?(items, &(&1["saved_at"] != nil))

      # Test alias /me/saved/videos
      res_alias = auth_conn |> get("/api/v1/me/saved/videos") |> json_response(200)
      assert length(res_alias["data"]) == 2
    end
  end

  describe "Error handling" do
    test "returns 404 for interactions on non-existent video ID", %{conn: conn} do
      user = insert(:user)
      fake_id = Ecto.UUID.generate()
      auth_conn = authenticate_conn(conn, user)

      assert auth_conn |> post("/api/v1/videos/#{fake_id}/favorite") |> json_response(404)
      assert auth_conn |> post("/api/v1/videos/#{fake_id}/save") |> json_response(404)
      assert auth_conn |> delete("/api/v1/videos/#{fake_id}/favorite") |> json_response(404)
      assert auth_conn |> delete("/api/v1/videos/#{fake_id}/save") |> json_response(404)
      assert auth_conn |> get("/api/v1/videos/#{fake_id}/status") |> json_response(404)
    end
  end
end
