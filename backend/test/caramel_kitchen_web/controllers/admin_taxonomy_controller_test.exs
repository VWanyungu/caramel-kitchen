defmodule CaramelKitchenWeb.AdminTaxonomyControllerTest do
  use CaramelKitchenWeb.ConnCase, async: false

  describe "Authentication & Authorization" do
    test "unauthenticated requests return 401", %{conn: conn} do
      conn = get(conn, "/api/v1/admin/categories")
      assert json_response(conn, 401)
    end

    test "regular user requests return 403", %{conn: conn} do
      user = insert(:user)
      conn = authenticate_conn(conn, user)
      conn = get(conn, "/api/v1/admin/categories")
      assert json_response(conn, 403)
    end
  end

  describe "Admin Categories CRUD" do
    setup %{conn: conn} do
      admin = insert(:admin)
      {:ok, conn: authenticate_conn(conn, admin), admin: admin}
    end

    test "GET /api/v1/admin/categories lists all categories", %{conn: conn} do
      c1 = insert(:taxonomy, type: "category", name: "Alpha Category")
      conn = get(conn, "/api/v1/admin/categories")
      assert %{"data" => items} = json_response(conn, 200)
      assert is_list(items)
      assert Enum.any?(items, &(&1["id"] == c1.id))
    end

    test "POST /api/v1/admin/categories creates a new category", %{conn: conn} do
      payload = %{
        "name" => "Brunch Classics",
        "description" => "Delicious brunch recipes",
        "display_order" => 10,
        "is_active" => true
      }

      conn = post(conn, "/api/v1/admin/categories", payload)
      assert %{"data" => item} = json_response(conn, 201)
      assert item["name"] == "Brunch Classics"
      assert item["slug"] == "brunch_classics"
      assert item["type"] == "category"
      assert item["display_order"] == 10
    end

    test "GET /api/v1/admin/categories/:id shows a category", %{conn: conn} do
      category = insert(:taxonomy, type: "category", name: "Show Me Category")
      conn = get(conn, "/api/v1/admin/categories/#{category.id}")
      assert %{"data" => item} = json_response(conn, 200)
      assert item["id"] == category.id
      assert item["name"] == "Show Me Category"
    end

    test "PUT /api/v1/admin/categories/:id updates a category", %{conn: conn} do
      category = insert(:taxonomy, type: "category", name: "Old Cat")

      conn =
        put(conn, "/api/v1/admin/categories/#{category.id}", %{
          "name" => "New Cat",
          "slug" => "new_cat"
        })

      assert %{"data" => item} = json_response(conn, 200)
      assert item["name"] == "New Cat"
      assert item["slug"] == "new_cat"
    end

    test "DELETE /api/v1/admin/categories/:id deletes a category", %{conn: conn} do
      category = insert(:taxonomy, type: "category")
      conn = delete(conn, "/api/v1/admin/categories/#{category.id}")
      assert response(conn, 204)

      conn = get(conn, "/api/v1/admin/categories/#{category.id}")
      assert json_response(conn, 404)
    end
  end

  describe "Admin Cuisines CRUD" do
    setup %{conn: conn} do
      admin = insert(:admin)
      {:ok, conn: authenticate_conn(conn, admin)}
    end

    test "CRUD operations for cuisines", %{conn: conn} do
      # Create
      conn_post =
        post(conn, "/api/v1/admin/cuisines", %{"name" => "Ethiopian", "slug" => "ethiopian"})

      assert %{"data" => created} = json_response(conn_post, 201)
      assert created["name"] == "Ethiopian"
      id = created["id"]

      # Show
      conn_get = get(conn, "/api/v1/admin/cuisines/#{id}")
      assert %{"data" => shown} = json_response(conn_get, 200)
      assert shown["id"] == id

      # Update
      conn_put = put(conn, "/api/v1/admin/cuisines/#{id}", %{"display_order" => 99})
      assert %{"data" => updated} = json_response(conn_put, 200)
      assert updated["display_order"] == 99

      # Delete
      conn_del = delete(conn, "/api/v1/admin/cuisines/#{id}")
      assert response(conn_del, 204)
    end
  end

  describe "Admin Dietary Tags CRUD" do
    setup %{conn: conn} do
      admin = insert(:admin)
      {:ok, conn: authenticate_conn(conn, admin)}
    end

    test "CRUD operations for dietary tags", %{conn: conn} do
      # Create
      conn_post =
        post(conn, "/api/v1/admin/dietary-tags", %{"name" => "Low FODMAP", "slug" => "low_fodmap"})

      assert %{"data" => created} = json_response(conn_post, 201)
      id = created["id"]

      # Show
      conn_get = get(conn, "/api/v1/admin/dietary-tags/#{id}")
      assert %{"data" => shown} = json_response(conn_get, 200)
      assert shown["id"] == id

      # Update
      conn_put = put(conn, "/api/v1/admin/dietary-tags/#{id}", %{"is_active" => false})
      assert %{"data" => updated} = json_response(conn_put, 200)
      assert updated["is_active"] == false

      # Delete
      conn_del = delete(conn, "/api/v1/admin/dietary-tags/#{id}")
      assert response(conn_del, 204)
    end
  end

  describe "Admin Difficulties CRUD" do
    setup %{conn: conn} do
      admin = insert(:admin)
      {:ok, conn: authenticate_conn(conn, admin)}
    end

    test "CRUD operations for difficulties", %{conn: conn} do
      # Create
      conn_post =
        post(conn, "/api/v1/admin/difficulties", %{
          "name" => "Master Chef",
          "slug" => "master_chef"
        })

      assert %{"data" => created} = json_response(conn_post, 201)
      id = created["id"]

      # Show
      conn_get = get(conn, "/api/v1/admin/difficulties/#{id}")
      assert %{"data" => shown} = json_response(conn_get, 200)
      assert shown["id"] == id

      # Update
      conn_put =
        put(conn, "/api/v1/admin/difficulties/#{id}", %{"description" => "Only for pros"})

      assert %{"data" => updated} = json_response(conn_put, 200)
      assert updated["description"] == "Only for pros"

      # Delete
      conn_del = delete(conn, "/api/v1/admin/difficulties/#{id}")
      assert response(conn_del, 204)
    end
  end

  describe "Cross-type isolation" do
    setup %{conn: conn} do
      admin = insert(:admin)
      {:ok, conn: authenticate_conn(conn, admin)}
    end

    test "accessing a cuisine via categories endpoint returns 404", %{conn: conn} do
      cuisine = insert(:taxonomy, type: "cuisine")
      conn = get(conn, "/api/v1/admin/categories/#{cuisine.id}")
      assert json_response(conn, 404)
    end
  end

  describe "Public Taxonomy Discovery" do
    test "GET /api/v1/cuisines returns active cuisines", %{conn: conn} do
      active = insert(:taxonomy, type: "cuisine", name: "Active Cuisine", is_active: true)
      inactive = insert(:taxonomy, type: "cuisine", name: "Inactive Cuisine", is_active: false)

      conn = get(conn, "/api/v1/cuisines")
      assert %{"data" => items} = json_response(conn, 200)
      ids = Enum.map(items, & &1["id"])
      assert active.id in ids
      refute inactive.id in ids
    end

    test "GET /api/v1/dietary-tags returns active dietary tags", %{conn: conn} do
      conn = get(conn, "/api/v1/dietary-tags")
      assert %{"data" => items} = json_response(conn, 200)
      assert is_list(items)
      assert length(items) >= 1
    end

    test "GET /api/v1/difficulties returns active difficulties", %{conn: conn} do
      conn = get(conn, "/api/v1/difficulties")
      assert %{"data" => items} = json_response(conn, 200)
      assert is_list(items)
      assert length(items) >= 1
    end
  end
end
