defmodule CaramelKitchen.CollectionsTest do
  use CaramelKitchen.DataCase, async: true

  alias CaramelKitchen.Collections
  alias CaramelKitchen.Collections.{Collection, CollectionItem}

  describe "collections context" do
    test "create_collection/2 creates a collection and auto-generates slug" do
      user = insert(:user)

      attrs = %{
        "name" => "Summer BBQ Favorites",
        "description" => "Juicy grilled meats and refreshing sides",
        "is_public" => true
      }

      assert {:ok, %Collection{} = col} = Collections.create_collection(user, attrs)
      assert col.user_id == user.id
      assert col.name == "Summer BBQ Favorites"
      assert col.slug == "summer_bbq_favorites"
      assert col.is_public == true
      assert col.items == []
    end

    test "create_collection/2 with initial recipe_ids and video_ids" do
      user = insert(:user)
      r1 = insert(:recipe)
      r2 = insert(:recipe)
      v1 = insert(:video)

      attrs = %{
        "name" => "Complete Feast",
        "recipe_ids" => [r1.id, r2.id],
        "video_ids" => [v1.id]
      }

      assert {:ok, %Collection{} = col} = Collections.create_collection(user, attrs)
      assert length(col.items) == 3

      recipe_item_ids =
        Enum.filter(col.items, &(&1.item_type == "recipe")) |> Enum.map(& &1.recipe_id)

      assert r1.id in recipe_item_ids
      assert r2.id in recipe_item_ids

      video_item = Enum.find(col.items, &(&1.item_type == "video"))
      assert video_item.video_id == v1.id
    end

    test "create_collection/2 enforces unique slug per user" do
      user = insert(:user)
      attrs = %{"name" => "Taco Night", "slug" => "taco_night"}

      assert {:ok, _} = Collections.create_collection(user, attrs)
      assert {:error, changeset} = Collections.create_collection(user, attrs)
      assert "slug already exists for this user" in errors_on(changeset).slug
    end

    test "list_collections/1 filters by recipe_id" do
      user = insert(:user)
      r1 = insert(:recipe)
      r2 = insert(:recipe)

      col1 = insert(:collection, user_id: user.id)
      col2 = insert(:collection, user_id: user.id)

      insert(:collection_item, collection_id: col1.id, item_type: "recipe", recipe_id: r1.id)
      insert(:collection_item, collection_id: col2.id, item_type: "recipe", recipe_id: r2.id)

      results = Collections.list_collections(recipe_id: r1.id)
      ids = Enum.map(results, & &1.id)

      assert col1.id in ids
      refute col2.id in ids
    end

    test "list_collections/1 filters by video_id" do
      user = insert(:user)
      v1 = insert(:video)
      v2 = insert(:video)

      col1 = insert(:collection, user_id: user.id)
      col2 = insert(:collection, user_id: user.id)

      insert(:collection_item, collection_id: col1.id, item_type: "video", video_id: v1.id)
      insert(:collection_item, collection_id: col2.id, item_type: "video", video_id: v2.id)

      results = Collections.list_collections(video_id: v1.id)
      ids = Enum.map(results, & &1.id)

      assert col1.id in ids
      refute col2.id in ids
    end

    test "list_collections/1 filters by search term and is_curated" do
      user = insert(:user)
      col1 = insert(:collection, user_id: user.id, name: "Ethiopian Spices", is_curated: true)
      col2 = insert(:collection, user_id: user.id, name: "Italian Pastas", is_curated: false)

      search_results = Collections.list_collections(search: "ethiopian")
      assert col1.id in Enum.map(search_results, & &1.id)
      refute col2.id in Enum.map(search_results, & &1.id)

      curated_results = Collections.list_collections(is_curated: true)
      assert col1.id in Enum.map(curated_results, & &1.id)
      refute col2.id in Enum.map(curated_results, & &1.id)
    end

    test "list_collections/1 privacy gating: hides private collections from guests and other users" do
      owner = insert(:user)
      stranger = insert(:user)
      admin = insert(:admin)

      public_col = insert(:collection, user_id: owner.id, is_public: true)
      private_col = insert(:collection, user_id: owner.id, is_public: false)

      # 1. Guest viewer
      guest_list = Collections.list_collections(viewer: nil)
      guest_ids = Enum.map(guest_list, & &1.id)
      assert public_col.id in guest_ids
      refute private_col.id in guest_ids

      # 2. Stranger viewer
      stranger_list = Collections.list_collections(viewer: stranger)
      stranger_ids = Enum.map(stranger_list, & &1.id)
      assert public_col.id in stranger_ids
      refute private_col.id in stranger_ids

      # 3. Owner viewer
      owner_list = Collections.list_collections(viewer: owner, mine: true)
      owner_ids = Enum.map(owner_list, & &1.id)
      assert public_col.id in owner_ids
      assert private_col.id in owner_ids

      # 4. Admin viewer
      admin_list = Collections.list_collections(viewer: admin)
      admin_ids = Enum.map(admin_list, & &1.id)
      assert public_col.id in admin_ids
      assert private_col.id in admin_ids
    end

    test "get_collection/2 returns collection or enforces privacy" do
      owner = insert(:user)
      stranger = insert(:user)
      private_col = insert(:collection, user_id: owner.id, is_public: false)

      assert {:error, :not_found} = Collections.get_collection(private_col.id, viewer: stranger)
      assert {:ok, col} = Collections.get_collection(private_col.id, viewer: owner)
      assert col.id == private_col.id
    end

    test "update_collection/2 updates attributes" do
      collection = insert(:collection, name: "Old Name")

      assert {:ok, updated} =
               Collections.update_collection(collection, %{
                 "name" => "New Name",
                 "slug" => "new_name"
               })

      assert updated.name == "New Name"
      assert updated.slug == "new_name"
    end

    test "delete_collection/1 deletes collection and cascading items" do
      collection = insert(:collection)
      recipe = insert(:recipe)

      insert(:collection_item,
        collection_id: collection.id,
        recipe_id: recipe.id,
        item_type: "recipe"
      )

      assert {:ok, _} = Collections.delete_collection(collection)
      assert {:error, :not_found} = Collections.get_collection(collection.id)
      assert Repo.get_by(CollectionItem, collection_id: collection.id) == nil
    end

    test "add_item/2 and remove_item/2" do
      collection = insert(:collection)
      recipe = insert(:recipe)
      video = insert(:video)

      assert {:ok, %CollectionItem{} = item1} =
               Collections.add_item(collection, %{"recipe_id" => recipe.id})

      assert item1.item_type == "recipe"
      assert item1.recipe_id == recipe.id
      assert item1.position == 1

      assert {:ok, %CollectionItem{} = item2} =
               Collections.add_item(collection, %{"video_id" => video.id})

      assert item2.item_type == "video"
      assert item2.video_id == video.id
      assert item2.position == 2

      # Duplicate prevention
      assert {:error, changeset} = Collections.add_item(collection, %{"recipe_id" => recipe.id})
      assert "recipe already in collection" in errors_on(changeset).recipe_id

      # Removal by item ID
      assert {:ok, _} = Collections.remove_item(collection, item1.id)
      assert Repo.get(CollectionItem, item1.id) == nil

      # Removal by reference
      assert {:ok, _} = Collections.remove_item_by_ref(collection, %{"video_id" => video.id})
      assert Repo.get(CollectionItem, item2.id) == nil
    end

    test "create_collection/2 and update_collection/2 support is_premium" do
      user = insert(:user)

      assert {:ok, col} =
               Collections.create_collection(user, %{
                 "name" => "Masterclass Series",
                 "is_premium" => true
               })

      assert col.is_premium == true

      assert {:ok, updated} =
               Collections.update_collection(col, %{
                 "is_premium" => false
               })

      assert updated.is_premium == false
    end

    test "list_collections/1 and count_collections/1 filter by is_premium" do
      user = insert(:user)
      premium_col = insert(:collection, user_id: user.id, name: "Premium Collection", is_premium: true)
      free_col = insert(:collection, user_id: user.id, name: "Free Collection", is_premium: false)

      prem_results = Collections.list_collections(is_premium: true)
      prem_ids = Enum.map(prem_results, & &1.id)
      assert premium_col.id in prem_ids
      refute free_col.id in prem_ids
      assert Collections.count_collections(is_premium: true) >= 1

      free_results = Collections.list_collections(is_premium: false)
      free_ids = Enum.map(free_results, & &1.id)
      assert free_col.id in free_ids
      refute premium_col.id in free_ids
    end

    test "has_access?/2 gates access based on tier and ownership" do
      owner = insert(:user)
      free_user = insert(:user, subscription_tier: "free")
      premium_user = insert(:premium_user)
      creator_pro_user = insert(:user, subscription_tier: "creator_pro")
      admin = insert(:admin)

      free_col = insert(:collection, user_id: owner.id, is_premium: false)
      premium_col = insert(:collection, user_id: owner.id, is_premium: true)

      # Non-premium collection is accessible by everyone
      assert Collections.has_access?(free_col, nil) == true
      assert Collections.has_access?(free_col, free_user) == true
      assert Collections.has_access?(free_col, premium_user) == true

      # Premium collection
      assert Collections.has_access?(premium_col, nil) == false
      assert Collections.has_access?(premium_col, free_user) == false
      assert Collections.has_access?(premium_col, owner) == true
      assert Collections.has_access?(premium_col, admin) == true
      assert Collections.has_access?(premium_col, premium_user) == true
      assert Collections.has_access?(premium_col, creator_pro_user) == true
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
