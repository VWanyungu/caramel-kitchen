defmodule CaramelKitchen.VideoInteractionsTest do
  use ExUnit.Case, async: true

  import CaramelKitchen.Factory
  alias CaramelKitchen.Videos
  alias CaramelKitchen.Videos.UserVideoInteraction

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(CaramelKitchen.Repo)
  end

  describe "favorite_video/3 and unfavorite_video/2" do
    test "successfully favorites a video and increments favorite_count" do
      user = insert(:user)
      video = insert(:video, favorite_count: 0)

      assert {:ok, result} = Videos.favorite_video(user, video.id)
      assert result.video_id == video.id
      assert result.action == "favorite"
      assert result.status == "favorited"
      assert result.is_favorited == true
      assert result.is_saved == false
      assert result.favorite_count == 1
      assert result.favorited_at != nil

      updated_video = Videos.get_video!(video.id)
      assert updated_video.favorite_count == 1
    end

    test "favoriting an already favorited video is idempotent" do
      user = insert(:user)
      video = insert(:video, favorite_count: 0)

      assert {:ok, result1} = Videos.favorite_video(user, video.id)
      assert result1.status == "favorited"
      assert result1.favorite_count == 1

      # Second favorite call
      assert {:ok, result2} = Videos.favorite_video(user, video.id)
      assert result2.status == "already_favorited"
      assert result2.favorite_count == 1

      updated_video = Videos.get_video!(video.id)
      assert updated_video.favorite_count == 1
    end

    test "successfully unfavorites a video and decrements favorite_count" do
      user = insert(:user)
      video = insert(:video, favorite_count: 0)

      {:ok, _} = Videos.favorite_video(user, video.id)
      assert Videos.get_video!(video.id).favorite_count == 1

      assert {:ok, unfav} = Videos.unfavorite_video(user, video.id)
      assert unfav.status == "unfavorited"
      assert unfav.is_favorited == false
      assert unfav.favorite_count == 0

      updated_video = Videos.get_video!(video.id)
      assert updated_video.favorite_count == 0
    end

    test "unfavoriting an unfavorited video is safe and does not drop below 0" do
      user = insert(:user)
      video = insert(:video, favorite_count: 0)

      assert {:ok, unfav} = Videos.unfavorite_video(user, video.id)
      assert unfav.status == "not_favorited"
      assert unfav.is_favorited == false
      assert unfav.favorite_count == 0
    end

    test "returns error when video is not found" do
      user = insert(:user)
      fake_id = Ecto.UUID.generate()

      assert {:error, :not_found} = Videos.favorite_video(user, fake_id)
      assert {:error, :not_found} = Videos.unfavorite_video(user, fake_id)
    end
  end

  describe "save_video/3 and unsave_video/2" do
    test "successfully saves a video to watch later and increments save_count" do
      user = insert(:user)
      video = insert(:video, save_count: 0)

      assert {:ok, result} = Videos.save_video(user, video.id)
      assert result.video_id == video.id
      assert result.action == "saved"
      assert result.status == "saved"
      assert result.is_saved == true
      assert result.is_favorited == false
      assert result.save_count == 1
      assert result.saved_at != nil

      updated_video = Videos.get_video!(video.id)
      assert updated_video.save_count == 1
    end

    test "saving an already saved video is idempotent" do
      user = insert(:user)
      video = insert(:video, save_count: 0)

      assert {:ok, res1} = Videos.save_video(user, video.id)
      assert res1.status == "saved"
      assert res1.save_count == 1

      assert {:ok, res2} = Videos.save_video(user, video.id)
      assert res2.status == "already_saved"
      assert res2.save_count == 1

      updated_video = Videos.get_video!(video.id)
      assert updated_video.save_count == 1
    end

    test "successfully unsaves a video and decrements save_count" do
      user = insert(:user)
      video = insert(:video, save_count: 0)

      {:ok, _} = Videos.save_video(user, video.id)
      assert Videos.get_video!(video.id).save_count == 1

      assert {:ok, unsaved} = Videos.unsave_video(user, video.id)
      assert unsaved.status == "unsaved"
      assert unsaved.is_saved == false
      assert unsaved.save_count == 0

      updated_video = Videos.get_video!(video.id)
      assert updated_video.save_count == 0
    end

    test "unsaving a non-saved video is safe" do
      user = insert(:user)
      video = insert(:video, save_count: 0)

      assert {:ok, res} = Videos.unsave_video(user, video.id)
      assert res.status == "not_saved"
      assert res.is_saved == false
      assert res.save_count == 0
    end
  end

  describe "strict separation between Favourite and Save (Issue #112)" do
    test "a user can both favorite and save the same video independently" do
      user = insert(:user)
      video = insert(:video, favorite_count: 0, save_count: 0)

      # 1. Favorite the video
      {:ok, fav} = Videos.favorite_video(user, video.id)
      assert fav.is_favorited == true
      assert fav.is_saved == false

      # 2. Save the video to watch later
      {:ok, sav} = Videos.save_video(user, video.id)
      assert sav.is_saved == true
      assert sav.is_favorited == true

      # Verify counts
      reloaded = Videos.get_video!(video.id)
      assert reloaded.favorite_count == 1
      assert reloaded.save_count == 1

      # 3. Status check confirms both states
      {:ok, status} = Videos.get_user_video_status(user, video.id)
      assert status.is_favorited == true
      assert status.is_saved == true
      assert status.favorite_count == 1
      assert status.save_count == 1

      # 4. Unfavoriting leaves saved state intact
      {:ok, unfav} = Videos.unfavorite_video(user, video.id)
      assert unfav.is_favorited == false
      assert unfav.is_saved == true

      {:ok, status_after_unfav} = Videos.get_user_video_status(user, video.id)
      assert status_after_unfav.is_favorited == false
      assert status_after_unfav.is_saved == true

      # 5. Unsaving removes saved state without touching favorite state
      {:ok, unsav} = Videos.unsave_video(user, video.id)
      assert unsav.is_saved == false
      assert unsav.is_favorited == false

      {:ok, final_status} = Videos.get_user_video_status(user, video.id)
      assert final_status.is_favorited == false
      assert final_status.is_saved == false
    end
  end

  describe "list_favorite_videos/2 and count_favorite_videos/2" do
    test "returns only favorited videos for the specified user" do
      user1 = insert(:user)
      user2 = insert(:user)

      v1 = insert(:video, title: "Favorite One", category: "Cooking_Techniques")
      v2 = insert(:video, title: "Favorite Two", category: "Tutorials")
      v3 = insert(:video, title: "User2 Favorite", category: "Quick Cooking")

      {:ok, _} = Videos.favorite_video(user1, v1.id)
      {:ok, _} = Videos.favorite_video(user1, v2.id)
      {:ok, _} = Videos.favorite_video(user2, v3.id)

      favorites = Videos.list_favorite_videos(user1)
      assert length(favorites) == 2
      assert Enum.map(favorites, & &1.id) |> Enum.sort() == Enum.sort([v1.id, v2.id])
      assert Videos.count_favorite_videos(user1) == 2

      # Check timestamps & flags
      assert Enum.all?(favorites, &(&1.is_favorited == true))
      assert Enum.all?(favorites, &(&1.favorited_at != nil))

      # Filter by category
      tech_favs = Videos.list_favorite_videos(user1, %{"category" => "Cooking_Techniques"})
      assert length(tech_favs) == 1
      assert hd(tech_favs).id == v1.id
    end

    test "respects access level redaction for premium videos in favorites list" do
      free_user = insert(:user, subscription_tier: "free")
      prem_user = insert(:user, subscription_tier: "premium")

      prem_video =
        insert(:video,
          is_premium: true,
          yt_embed_code: "<iframe>secret</iframe>",
          title: "Masterclass"
        )

      {:ok, _} = Videos.favorite_video(free_user, prem_video.id)
      {:ok, _} = Videos.favorite_video(prem_user, prem_video.id)

      # Free user sees preview with masked embed
      free_favs = Videos.list_favorite_videos(free_user)
      assert length(free_favs) == 1
      assert hd(free_favs).is_locked == true
      assert hd(free_favs).yt_embed_code == nil

      # Premium user sees full unlocked video
      prem_favs = Videos.list_favorite_videos(prem_user)
      assert length(prem_favs) == 1
      assert hd(prem_favs).is_locked == false
      assert hd(prem_favs).yt_embed_code == "<iframe>secret</iframe>"
    end
  end

  describe "list_saved_videos/2 and count_saved_videos/2" do
    test "returns only watch-later saved videos for the specified user" do
      user = insert(:user)
      v1 = insert(:video, title: "Watch Later 1", category: "Cooking_Tips")
      v2 = insert(:video, title: "Watch Later 2", category: "Recipe_Videos")

      {:ok, _} = Videos.save_video(user, v1.id)
      {:ok, _} = Videos.save_video(user, v2.id)

      saved_videos = Videos.list_saved_videos(user)
      assert length(saved_videos) == 2
      assert Enum.all?(saved_videos, &(&1.is_saved == true))
      assert Enum.all?(saved_videos, &(&1.saved_at != nil))
      assert Videos.count_saved_videos(user) == 2
    end
  end

  describe "list_videos/2 with interaction annotations and sorting" do
    test "annotates videos with is_favorited and is_saved for current_user" do
      user = insert(:user)
      v_fav = insert(:video, title: "Video Fav")
      v_sav = insert(:video, title: "Video Sav")
      v_plain = insert(:video, title: "Video Plain")

      {:ok, _} = Videos.favorite_video(user, v_fav.id)
      {:ok, _} = Videos.save_video(user, v_sav.id)

      videos = Videos.list_videos(%{}, user)
      by_id = Map.new(videos, &{&1.id, &1})

      assert by_id[v_fav.id].is_favorited == true
      assert by_id[v_fav.id].is_saved == false

      assert by_id[v_sav.id].is_favorited == false
      assert by_id[v_sav.id].is_saved == true

      assert by_id[v_plain.id].is_favorited == false
      assert by_id[v_plain.id].is_saved == false
    end

    test "sorts videos by most_favorited and most_saved" do
      _v1 = insert(:video, favorite_count: 5, save_count: 1, title: "Low Fav High Save")
      _v2 = insert(:video, favorite_count: 20, save_count: 0, title: "High Fav Low Save")

      fav_sorted = Videos.list_videos(%{"order" => "most_favorited"})
      assert hd(fav_sorted).favorite_count == 20

      save_sorted = Videos.list_videos(%{"order" => "most_saved"})
      assert hd(save_sorted).save_count == 1
    end
  end

  describe "UserVideoInteraction schema changesets and action normalization" do
    test "normalizes action variations (favourite -> favorite, save -> saved)" do
      user = insert(:user)
      video = insert(:video)

      changeset1 =
        UserVideoInteraction.changeset(%UserVideoInteraction{}, %{
          user_id: user.id,
          video_id: video.id,
          action: "favourite"
        })

      assert changeset1.valid?
      assert Ecto.Changeset.get_field(changeset1, :action) == "favorite"

      changeset2 =
        UserVideoInteraction.changeset(%UserVideoInteraction{}, %{
          user_id: user.id,
          video_id: video.id,
          action: "save"
        })

      assert changeset2.valid?
      assert Ecto.Changeset.get_field(changeset2, :action) == "saved"
    end

    test "rejects invalid actions" do
      user = insert(:user)
      video = insert(:video)

      changeset =
        UserVideoInteraction.changeset(%UserVideoInteraction{}, %{
          user_id: user.id,
          video_id: video.id,
          action: "dislike"
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).action
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
