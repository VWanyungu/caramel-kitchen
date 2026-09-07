defmodule CaramelKitchen.MealPlanInteractionsTest do
  use ExUnit.Case, async: true

  import CaramelKitchen.Factory
  alias CaramelKitchen.MealPlans
  alias CaramelKitchen.MealPlans.UserMealPlanInteraction

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(CaramelKitchen.Repo)
  end

  describe "save_meal_plan/3 and unsave_meal_plan/2" do
    test "successfully saves a meal plan and increments save_count" do
      user = insert(:user)
      plan = insert(:meal_plan, save_count: 0)

      assert {:ok, result} = MealPlans.save_meal_plan(user, plan.id)
      assert result.meal_plan_id == plan.id
      assert result.action == "saved"
      assert result.status == "saved"
      assert result.is_saved == true
      assert result.save_count == 1
      assert result.saved_at != nil

      updated = MealPlans.get_plan!(plan.id)
      assert updated.save_count == 1
    end

    test "saving an already saved meal plan is idempotent" do
      user = insert(:user)
      plan = insert(:meal_plan, save_count: 0)

      assert {:ok, res1} = MealPlans.save_meal_plan(user, plan.id)
      assert res1.status == "saved"
      assert res1.save_count == 1

      assert {:ok, res2} = MealPlans.save_meal_plan(user, plan.id)
      assert res2.status == "already_saved"
      assert res2.save_count == 1

      updated = MealPlans.get_plan!(plan.id)
      assert updated.save_count == 1
    end

    test "successfully unsaves a meal plan and decrements save_count" do
      user = insert(:user)
      plan = insert(:meal_plan, save_count: 0)

      {:ok, _} = MealPlans.save_meal_plan(user, plan.id)
      assert MealPlans.get_plan!(plan.id).save_count == 1

      assert {:ok, unsaved} = MealPlans.unsave_meal_plan(user, plan.id)
      assert unsaved.status == "unsaved"
      assert unsaved.is_saved == false
      assert unsaved.save_count == 0

      updated = MealPlans.get_plan!(plan.id)
      assert updated.save_count == 0
    end

    test "unsaving a non-saved meal plan is safe" do
      user = insert(:user)
      plan = insert(:meal_plan, save_count: 0)

      assert {:ok, res} = MealPlans.unsave_meal_plan(user, plan.id)
      assert res.status == "not_saved"
      assert res.is_saved == false
      assert res.save_count == 0
    end

    test "returns :not_found when meal plan does not exist" do
      user = insert(:user)
      fake_id = Ecto.UUID.generate()

      assert {:error, :not_found} = MealPlans.save_meal_plan(user, fake_id)
      assert {:error, :not_found} = MealPlans.unsave_meal_plan(user, fake_id)
    end
  end

  describe "is_saved?/2 and get_user_meal_plan_status/2" do
    test "correctly detects saved status" do
      user = insert(:user)
      p1 = insert(:meal_plan)
      p2 = insert(:meal_plan)

      {:ok, _} = MealPlans.save_meal_plan(user, p1.id)

      assert MealPlans.is_saved?(user, p1.id) == true
      assert MealPlans.is_saved?(user, p2.id) == false
      assert MealPlans.is_saved?(nil, p1.id) == false

      assert {:ok, status} = MealPlans.get_user_meal_plan_status(user, p1.id)
      assert status.is_saved == true
      assert status.save_count == 1
    end
  end

  describe "list_saved_meal_plans/2 and count_saved_meal_plans/2" do
    test "lists saved meal plans for a user with pagination" do
      user = insert(:user)
      p1 = insert(:meal_plan, name: "Muscle Gain Week 1")
      p2 = insert(:meal_plan, name: "Keto Week 1")
      _p3 = insert(:meal_plan, name: "Balanced Week 1")

      {:ok, _} = MealPlans.save_meal_plan(user, p1.id)
      {:ok, _} = MealPlans.save_meal_plan(user, p2.id)

      saved_list = MealPlans.list_saved_meal_plans(user, limit: 10, offset: 0)
      saved_ids = Enum.map(saved_list, & &1.id)

      assert p1.id in saved_ids
      assert p2.id in saved_ids
      assert length(saved_list) == 2
      assert MealPlans.count_saved_meal_plans(user) == 2
    end
  end

  describe "UserMealPlanInteraction schema and changeset" do
    test "validates required fields and action inclusion" do
      user = insert(:user)
      plan = insert(:meal_plan)

      changeset =
        UserMealPlanInteraction.changeset(%UserMealPlanInteraction{}, %{
          user_id: user.id,
          meal_plan_id: plan.id,
          action: "invalid_action"
        })

      assert "is invalid" in errors_on(changeset).action
    end

    test "normalizes action strings" do
      user = insert(:user)
      plan = insert(:meal_plan)

      changeset =
        UserMealPlanInteraction.changeset(%UserMealPlanInteraction{}, %{
          user_id: user.id,
          meal_plan_id: plan.id,
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
