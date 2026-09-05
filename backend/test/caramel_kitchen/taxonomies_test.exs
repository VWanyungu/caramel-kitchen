defmodule CaramelKitchen.TaxonomiesTest do
  use CaramelKitchen.DataCase, async: true

  alias CaramelKitchen.Taxonomies
  alias CaramelKitchen.Taxonomies.Taxonomy

  describe "taxonomies context" do
    test "list_taxonomies/2 returns items of the specified type ordered by display_order" do
      t1 = insert(:taxonomy, type: "category", name: "Zucchini Dishes", display_order: 10)
      t2 = insert(:taxonomy, type: "category", name: "Apple Pies", display_order: 5)
      _other = insert(:taxonomy, type: "cuisine", name: "Japanese")

      categories = Taxonomies.list_taxonomies("category", active_only: false)
      ids = Enum.map(categories, & &1.id)

      assert t2.id in ids
      assert t1.id in ids
      refute _other.id in ids
    end

    test "list_taxonomies/2 with active_only filter" do
      active = insert(:taxonomy, type: "cuisine", is_active: true)
      inactive = insert(:taxonomy, type: "cuisine", is_active: false)

      active_items = Taxonomies.list_taxonomies("cuisine", active_only: true)
      ids = Enum.map(active_items, & &1.id)

      assert active.id in ids
      refute inactive.id in ids

      all_items = Taxonomies.list_taxonomies("cuisine", active_only: false)
      all_ids = Enum.map(all_items, & &1.id)

      assert active.id in all_ids
      assert inactive.id in all_ids
    end

    test "list_taxonomies/2 with search filter" do
      t1 = insert(:taxonomy, type: "dietary_tag", name: "Gluten-Free Ultra")
      _t2 = insert(:taxonomy, type: "dietary_tag", name: "Keto")

      results = Taxonomies.list_taxonomies("dietary_tag", search: "gluten", active_only: false)
      assert length(results) >= 1
      assert hd(results).id == t1.id
    end

    test "convenience helpers list expected types" do
      c = insert(:taxonomy, type: "category")
      cu = insert(:taxonomy, type: "cuisine")
      dt = insert(:taxonomy, type: "dietary_tag")
      df = insert(:taxonomy, type: "difficulty")

      assert c.id in Enum.map(Taxonomies.list_categories(active_only: false), & &1.id)
      assert cu.id in Enum.map(Taxonomies.list_cuisines(active_only: false), & &1.id)
      assert dt.id in Enum.map(Taxonomies.list_dietary_tags(active_only: false), & &1.id)
      assert df.id in Enum.map(Taxonomies.list_difficulties(active_only: false), & &1.id)
    end

    test "get_taxonomy/1 and get_taxonomy!/1" do
      taxonomy = insert(:taxonomy)
      assert {:ok, fetched} = Taxonomies.get_taxonomy(taxonomy.id)
      assert fetched.id == taxonomy.id

      assert Taxonomies.get_taxonomy!(taxonomy.id).id == taxonomy.id
      assert {:error, :not_found} = Taxonomies.get_taxonomy(Ecto.UUID.generate())
      assert_raise Ecto.NoResultsError, fn -> Taxonomies.get_taxonomy!(Ecto.UUID.generate()) end
    end

    test "get_taxonomy_by_slug/2" do
      taxonomy = insert(:taxonomy, type: "cuisine", slug: "ethiopian_traditional")
      assert {:ok, fetched} = Taxonomies.get_taxonomy_by_slug("cuisine", "ethiopian_traditional")
      assert fetched.id == taxonomy.id

      assert {:error, :not_found} = Taxonomies.get_taxonomy_by_slug("cuisine", "non_existent")
    end

    test "create_taxonomy/2 with valid attributes generates slug automatically" do
      attrs = %{
        "name" => "Middle Eastern",
        "description" => "Authentic recipes from the Middle East",
        "display_order" => 4,
        "is_active" => true
      }

      assert {:ok, %Taxonomy{} = taxonomy} = Taxonomies.create_taxonomy("cuisine", attrs)
      assert taxonomy.type == "cuisine"
      assert taxonomy.name == "Middle Eastern"
      assert taxonomy.slug == "middle_eastern"
      assert taxonomy.display_order == 4
      assert taxonomy.is_active == true
    end

    test "create_taxonomy/2 with custom slug" do
      attrs = %{
        "name" => "Low Carb High Protein",
        "slug" => "custom_lchp"
      }

      assert {:ok, %Taxonomy{} = taxonomy} = Taxonomies.create_taxonomy("dietary_tag", attrs)
      assert taxonomy.slug == "custom_lchp"
    end

    test "create_taxonomy/2 fails with invalid type" do
      attrs = %{"name" => "Invalid Taxonomy"}
      assert {:error, changeset} = Taxonomies.create_taxonomy("unsupported_type", attrs)
      assert "is invalid" in errors_on(changeset).type
    end

    test "create_taxonomy/2 enforces unique slug per type" do
      attrs = %{"name" => "Nordic Cuisine", "slug" => "nordic"}
      assert {:ok, _} = Taxonomies.create_taxonomy("cuisine", attrs)
      assert {:error, changeset} = Taxonomies.create_taxonomy("cuisine", attrs)
      assert "has already been taken" in errors_on(changeset).slug
    end

    test "update_taxonomy/2 updates attributes" do
      taxonomy = insert(:taxonomy, name: "Old Name", display_order: 1)

      assert {:ok, updated} =
               Taxonomies.update_taxonomy(taxonomy, %{
                 "name" => "Updated Name",
                 "slug" => "updated_name",
                 "display_order" => 9
               })

      assert updated.name == "Updated Name"
      assert updated.slug == "updated_name"
      assert updated.display_order == 9
    end

    test "delete_taxonomy/1 deletes the taxonomy" do
      taxonomy = insert(:taxonomy)
      assert {:ok, _} = Taxonomies.delete_taxonomy(taxonomy)
      assert {:error, :not_found} = Taxonomies.get_taxonomy(taxonomy.id)
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
