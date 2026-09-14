defmodule CaramelKitchen.VideosTest do
  use ExUnit.Case, async: true

  import CaramelKitchen.Factory
  alias CaramelKitchen.Videos
  alias CaramelKitchen.Videos.Video

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(CaramelKitchen.Repo)
  end

  describe "video creation and changesets" do
    test "successfully creates video from YouTube URL" do
      attrs = %{
        title: "How to Make Caramel",
        description: "Step by step caramel cooking tutorial",
        category: "Cooking_Techniques",
        yt_embed_code: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        is_premium: false
      }

      assert {:ok, %Video{} = video} = Videos.create_video(attrs)
      assert video.title == "How to Make Caramel"
      assert video.category == "Cooking_Techniques"
      assert video.youtube_video_id == "dQw4w9WgXcQ"
      assert video.video_url == "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
      assert video.video_embed_url == "https://www.youtube.com/embed/dQw4w9WgXcQ"
      assert video.thumbnail_url == "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg"
      assert String.contains?(video.yt_embed_code, "<iframe")
      assert video.is_premium == false
      assert video.is_special == false
    end

    test "syncs is_premium and is_special" do
      {:ok, v1} =
        Videos.create_video(%{
          title: "Special Masterclass",
          category: "Masterclasses",
          yt_embed_code: "https://youtu.be/dQw4w9WgXcQ",
          is_special: true
        })

      assert v1.is_premium == true
      assert v1.is_special == true

      {:ok, v2} =
        Videos.create_video(%{
          title: "Premium Academy Lesson",
          category: "Caramel_Academy",
          yt_embed_code: "https://youtu.be/dQw4w9WgXcQ",
          is_premium: true
        })

      assert v2.is_premium == true
      assert v2.is_special == true
    end

    test "normalizes category variations" do
      {:ok, video} =
        Videos.create_video(%{
          title: "Fast Stir Fry",
          category: "quick_cooking",
          yt_embed_code: "https://youtu.be/dQw4w9WgXcQ"
        })

      assert video.category == "Quick Cooking"
    end

    test "rejects invalid category" do
      assert {:error, changeset} =
               Videos.create_video(%{
                 title: "Invalid Video",
                 category: "NonExistentCategory",
                 yt_embed_code: "dQw4w9WgXcQ"
               })

      assert "is invalid" in errors_on(changeset).category
    end

    test "requires title, category, and yt_embed_code" do
      assert {:error, changeset} = Videos.create_video(%{})
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.category
      assert "can't be blank" in errors.yt_embed_code
    end
  end

  describe "video updates and deletion" do
    test "updates video attributes" do
      video = insert(:video, title: "Old Title", category: "Cooking_Tips")

      assert {:ok, updated} =
               Videos.update_video(video, %{
                 title: "New Title",
                 category: "Tutorials"
               })

      assert updated.title == "New Title"
      assert updated.category == "Tutorials"
    end

    test "deletes video" do
      video = insert(:video)
      assert {:ok, _} = Videos.delete_video(video)
      assert {:error, :not_found} = Videos.get_video(video.id)
    end
  end

  describe "filtering and search" do
    test "filters by category" do
      insert(:video, title: "Tip 1", category: "Cooking_Tips")
      insert(:video, title: "Tip 2", category: "Cooking_Tips")
      insert(:video, title: "Recipe 1", category: "Recipe_Videos")

      results = Videos.list_videos(%{"category" => "Cooking_Tips"})
      assert length(results) == 2
      assert Enum.all?(results, &(&1.category == "Cooking_Tips"))
    end

    test "searches by title and description" do
      insert(:video, title: "How to Poach Eggs", description: "Breakfast guide")
      insert(:video, title: "Roast Beef", description: "Hearty dinner")

      assert [v] = Videos.list_videos(%{"search" => "poach"})
      assert v.title == "How to Poach Eggs"

      assert [v2] = Videos.list_videos(%{"search" => "breakfast"})
      assert v2.title == "How to Poach Eggs"
    end

    test "filters by is_premium" do
      insert(:video, title: "Free Video", is_premium: false)
      insert(:video, title: "VIP Video", is_premium: true)

      free_videos = Videos.list_videos(%{"is_premium" => "false"})
      assert Enum.any?(free_videos, &(&1.title == "Free Video"))
      refute Enum.any?(free_videos, &(&1.title == "VIP Video"))

      premium_videos = Videos.list_videos(%{"is_premium" => "true"})
      assert Enum.any?(premium_videos, &(&1.title == "VIP Video"))
      refute Enum.any?(premium_videos, &(&1.title == "Free Video"))
    end
  end

  describe "access level gating (Sub-issue #105)" do
    test "free video is accessible to unauthenticated user" do
      video = insert(:video, is_premium: false)
      redacted = Videos.redact_video(video, nil)

      assert redacted.is_locked == false
      assert redacted.yt_embed_code != nil
      assert redacted.video_embed_url != nil
    end

    test "premium video is locked and redacted for unauthenticated or free user" do
      video = insert(:video, is_premium: true, yt_embed_code: "<iframe>secret</iframe>")
      free_user = insert(:user, subscription_tier: "free")

      # Unauthenticated
      redacted_anon = Videos.redact_video(video, nil)
      assert redacted_anon.is_locked == true
      assert redacted_anon.yt_embed_code == nil
      assert redacted_anon.video_embed_url == nil

      # Free user
      redacted_user = Videos.redact_video(video, free_user)
      assert redacted_user.is_locked == true
      assert redacted_user.yt_embed_code == nil
      assert redacted_user.video_embed_url == nil
    end

    test "premium video is accessible to premium user and admin" do
      video = insert(:video, is_premium: true, yt_embed_code: "<iframe>secret</iframe>")
      prem_user = insert(:premium_user)
      admin_user = insert(:admin)

      unlocked_prem = Videos.redact_video(video, prem_user)
      assert unlocked_prem.is_locked == false
      assert unlocked_prem.yt_embed_code == "<iframe>secret</iframe>"

      unlocked_admin = Videos.redact_video(video, admin_user)
      assert unlocked_admin.is_locked == false
      assert unlocked_admin.yt_embed_code == "<iframe>secret</iframe>"
    end
  end

  describe "categories list" do
    test "returns canonical categories with counts" do
      insert(:video, category: "Recipe_Videos")
      insert(:video, category: "Recipe_Videos")
      insert(:video, category: "Cooking_Tips")

      categories = Videos.list_categories()
      assert is_list(categories)

      recipe_cat = Enum.find(categories, &(&1.name == "Recipe_Videos"))
      assert recipe_cat.count == 2

      tips_cat = Enum.find(categories, &(&1.name == "Cooking_Tips"))
      assert tips_cat.count == 1
    end
  end

  # Helper for extracting changeset errors
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
