defmodule CaramelKitchen.AccountsTest do
  use CaramelKitchen.DataCase, async: true

  alias CaramelKitchen.Accounts
  alias CaramelKitchen.Accounts.User

  describe "register_user/1" do
    test "registers with valid attributes" do
      attrs = %{
        "email" => "newuser@example.com",
        "password" => "SecurePass123",
        "password_confirmation" => "SecurePass123",
        "name" => "New User"
      }

      assert {:ok, %User{} = user} = Accounts.register_user(attrs)
      assert user.email == "newuser@example.com"
      assert user.name == "New User"
      assert user.role == "user"
      assert user.subscription_tier == "free"
      assert user.taste_survey_done == false
      assert is_nil(user.taste_vector)
    end

    test "downcases email on registration" do
      attrs = %{
        "email" => "USER@EXAMPLE.COM",
        "password" => "SecurePass123",
        "password_confirmation" => "SecurePass123",
        "name" => "Test"
      }

      assert {:ok, user} = Accounts.register_user(attrs)
      assert user.email == "user@example.com"
    end

    test "rejects duplicate email" do
      insert(:user, email: "taken@example.com")

      attrs = %{
        "email" => "taken@example.com",
        "password" => "SecurePass123",
        "password_confirmation" => "SecurePass123",
        "name" => "Test"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert "already registered" in errors_on(changeset).email
    end

    test "rejects short password" do
      attrs = %{
        "email" => "x@example.com",
        "password" => "short",
        "password_confirmation" => "short",
        "name" => "Test"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert errors_on(changeset).password != []
    end

    test "rejects password without number" do
      attrs = %{
        "email" => "x@example.com",
        "password" => "passwordonly",
        "password_confirmation" => "passwordonly",
        "name" => "Test"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert errors_on(changeset).password != []
    end

    test "rejects mismatched passwords" do
      attrs = %{
        "email" => "x@example.com",
        "password" => "SecurePass123",
        "password_confirmation" => "DifferentPass456",
        "name" => "Test"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)
      assert errors_on(changeset).password_confirmation != []
    end
  end

  describe "authenticate/2" do
    setup do
      user =
        insert(:user,
          email: "auth@example.com",
          password_hash: Bcrypt.hash_pwd_salt("correct_pass1")
        )

      {:ok, user: user}
    end

    test "returns user with correct credentials", %{user: user} do
      assert {:ok, authed_user} = Accounts.authenticate("auth@example.com", "correct_pass1")
      assert authed_user.id == user.id
    end

    test "increments sign_in_count", %{user: user} do
      {:ok, _} = Accounts.authenticate("auth@example.com", "correct_pass1")
      updated = Repo.get!(User, user.id)
      assert updated.sign_in_count == 1
    end

    test "returns error for wrong password" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate("auth@example.com", "wrong_password")
    end

    test "returns error for unknown email" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate("nobody@example.com", "any_pass")
    end

    test "returns error for deactivated account" do
      user =
        insert(:user,
          email: "deac@example.com",
          password_hash: Bcrypt.hash_pwd_salt("pass123"),
          deactivated_at: DateTime.utc_now() |> DateTime.truncate(:second)
        )

      assert {:error, :account_deactivated} =
               Accounts.authenticate("deac@example.com", "pass123")
    end
  end

  describe "submit_taste_survey/2" do
    test "stores normalised 8-dim vector" do
      user = insert(:user)

      responses = [
        %{taste: "sour", score: 5},
        %{taste: "sweet", score: 1},
        %{taste: "spicy", score: 4},
        %{taste: "savory", score: 3},
        %{taste: "tangy", score: 2},
        %{taste: "bitter", score: 1},
        %{taste: "umami", score: 5},
        %{taste: "mild", score: 2}
      ]

      assert {:ok, updated} = Accounts.submit_taste_survey(user, responses)
      assert updated.taste_survey_done == true
      assert not is_nil(updated.taste_vector)

      vec = User.taste_vector_list(updated)
      assert length(vec) == 8
      assert Enum.all?(vec, fn v -> v >= 0.0 and v <= 1.0 end)
      # score 5 → 1.0, score 1 → 0.0
      [sour_val | _] = vec
      assert sour_val == 1.0
    end

    test "defaults missing dimensions to 0.5" do
      user = insert(:user)
      # only one dimension provided
      responses = [%{taste: "spicy", score: 5}]

      assert {:ok, updated} = Accounts.submit_taste_survey(user, responses)
      vec = User.taste_vector_list(updated)
      # All non-spicy should be 0.5
      assert Enum.count(vec, &(&1 == 0.5)) == 7
    end
  end

  describe "update_taste_vector/3" do
    test "applies positive delta for cooked action" do
      user = insert(:user, taste_vector: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])
      # spicy + savory recipe
      profile = [0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0]

      assert {:ok, updated} = Accounts.update_taste_vector(user, profile, :cooked)
      vec = User.taste_vector_list(updated)

      # Spicy dim (index 3): 0.5 + 0.10 * 1.0 = 0.60
      assert Enum.at(vec, 3) == 0.60
      # Sour dim (index 0): 0.5 + 0.10 * 0.0 = 0.50 (unchanged)
      assert Enum.at(vec, 0) == 0.50
    end

    test "applies negative delta for skipped action" do
      user = insert(:user, taste_vector: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])
      # pure sour recipe
      profile = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

      assert {:ok, updated} = Accounts.update_taste_vector(user, profile, :skipped)
      vec = User.taste_vector_list(updated)

      # Sour: 0.5 + (-0.05) * 1.0 = 0.45
      assert Enum.at(vec, 0) == 0.45
    end

    test "clamps vector values between 0.0 and 1.0" do
      # Start with vector already at 0.95
      user = insert(:user, taste_vector: [0.97, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])
      profile = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

      assert {:ok, updated} = Accounts.update_taste_vector(user, profile, :rated_5)
      vec = User.taste_vector_list(updated)
      # Should not exceed 1.0
      assert Enum.at(vec, 0) == 1.0
    end
  end

  # ── Helpers ────────────────────────────────────────────────────

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(Regex.compile!("%{(\\w+)}"), msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
