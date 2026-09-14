defmodule CaramelKitchen.CollectionInteractionsTest do
  use ExUnit.Case, async: true

  import CaramelKitchen.Factory
  alias CaramelKitchen.Collections
  alias CaramelKitchen.Collections.UserCollectionInteraction

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(CaramelKitchen.Repo)
  end

  describe "save_collection/3 and unsave_collection/2" do
    test "successfully saves a collection and increments save_count" do
      user = insert(:user)
      collection = insert(:collection, save_count: 0)

      assert {:ok, result} = Collections.save_collection(user, collection.id)
      assert result.collection_id == collection.id
      assert result.action == "saved"
      assert result.status == "saved"
      assert result.is_saved == true
      assert result.save_count == 1
      assert result.saved_at != nil

      updated = Collections.get_collection!(collection.id)
      assert updated.save_count == 1
    end

    test "saving an already saved collection is idempotent" do
      user = insert(:user)
      collection = insert(:collection, save_count: 0)

      assert {:ok, res1} = Collections.save_collection(user, collection.id)
      assert res1.status == "saved"
      assert res1.save_count == 1

      assert {:ok, res2} = Collections.save_collection(user, collection.id)
      assert res2.status == "already_saved"
      assert res2.save_count == 1

      updated = Collections.get_collection!(collection.id)
      assert updated.save_count == 1
    end

    test "successfully unsaves a collection and decrements save_count" do
      user = insert(:user)
      collection = insert(:collection, save_count: 0)

      {:ok, _} = Collections.save_collection(user, collection.id)
      assert Collections.get_collection!(collection.id).save_count == 1

      assert {:ok, unsaved} = Collections.unsave_collection(user, collection.id)
      assert unsaved.status == "unsaved"
      assert unsaved.is_saved == false
      assert unsaved.save_count == 0

      updated = Collections.get_collection!(collection.id)
      assert updated.save_count == 0
    end

    test "unsaving a non-saved collection is safe" do
      user = insert(:user)
      collection = insert(:collection, save_count: 0)

      assert {:ok, res} = Collections.unsave_collection(user, collection.id)
      assert res.status == "not_saved"
      assert res.is_saved == false
      assert res.save_count == 0
    end

    test "returns :not_found when collection does not exist" do
      user = insert(:user)
      fake_id = Ecto.UUID.generate()

      assert {:error, :not_found} = Collections.save_collection(user, fake_id)
      assert {:error, :not_found} = Collections.unsave_collection(user, fake_id)
    end
  end

  describe "is_saved?/2 and get_user_collection_status/2" do
    test "correctly detects saved status" do
      user = insert(:user)
      c1 = insert(:collection)
      c2 = insert(:collection)

      {:ok, _} = Collections.save_collection(user, c1.id)

      assert Collections.is_saved?(user, c1.id) == true
      assert Collections.is_saved?(user, c2.id) == false
      assert Collections.is_saved?(nil, c1.id) == false

      assert {:ok, status} = Collections.get_user_collection_status(user, c1.id)
      assert status.is_saved == true
      assert status.save_count == 1
    end
  end

  describe "list_saved_collections/2 and count_saved_collections/2" do
    test "lists saved collections for a user with pagination" do
      user = insert(:user)
      c1 = insert(:collection, name: "Alpha Collection")
      c2 = insert(:collection, name: "Beta Collection")
      _c3 = insert(:collection, name: "Gamma Collection")

      {:ok, _} = Collections.save_collection(user, c1.id)
      {:ok, _} = Collections.save_collection(user, c2.id)

      saved_list = Collections.list_saved_collections(user, limit: 10, offset: 0)
      saved_ids = Enum.map(saved_list, & &1.id)

      assert c1.id in saved_ids
      assert c2.id in saved_ids
      assert length(saved_list) == 2
      assert Collections.count_saved_collections(user) == 2
    end
  end

  describe "UserCollectionInteraction schema and changeset" do
    test "validates required fields and action inclusion" do
      user = insert(:user)
      col = insert(:collection)

      changeset =
        UserCollectionInteraction.changeset(%UserCollectionInteraction{}, %{
          user_id: user.id,
          collection_id: col.id,
          action: "invalid_action"
        })

      assert "is invalid" in errors_on(changeset).action
    end

    test "normalizes action strings" do
      user = insert(:user)
      col = insert(:collection)

      changeset =
        UserCollectionInteraction.changeset(%UserCollectionInteraction{}, %{
          user_id: user.id,
          collection_id: col.id,
          action: "save"
        })

      assert Ecto.Changeset.get_change(changeset, :action) == "saved"
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
