defmodule CaramelKitchen.Collections.SeasonalSeeds do
  @moduledoc """
  Seeds official curated Seasonal Collections under Premium.
  Supports Christmas, Valentine's, Back to School, Ramadan, and future seasons.
  """
  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Accounts.User
  alias CaramelKitchen.Collections
  alias CaramelKitchen.Collections.Collection

  @seasons [
    %{
      season_name: "Christmas",
      start_date: ~D[2026-11-15],
      end_date: ~D[2027-01-05],
      collections: [
        %{
          name: "Christmas Dinner",
          description:
            "Festive roasts, savory mains, and celebratory holiday centerpieces for Christmas dinner."
        },
        %{
          name: "Christmas Baking",
          description:
            "Holiday cookies, spiced cakes, gingerbread, and classic sweet festive bakes."
        },
        %{
          name: "Christmas Desserts",
          description:
            "Decadent seasonal puddings, trifles, yule logs, and festive dessert treats."
        },
        %{
          name: "Christmas Drinks",
          description:
            "Warm spiced ciders, hot chocolate, festive eggnogs, and holiday mocktails."
        }
      ]
    },
    %{
      season_name: "Valentine's",
      start_date: ~D[2026-02-01],
      end_date: ~D[2026-02-28],
      collections: [
        %{
          name: "Date Night Dinner",
          description: "Romantic and flavorful restaurant-quality dishes crafted for two."
        },
        %{
          name: "Romantic Dinner",
          description:
            "Candlelit meals, steak, pasta, and elevated dinners to impress your valentine."
        },
        %{
          name: "Valentine's Desserts",
          description: "Chocolate fondants, strawberry treats, and romantic confections."
        },
        %{
          name: "Valentine's Drinks",
          description: "Sparkling berry drinks, mocktails, and decadent dessert sips."
        }
      ]
    },
    %{
      season_name: "Back to School",
      # Active around August - October
      start_date: ~D[2026-08-15],
      end_date: ~D[2026-10-15],
      collections: [
        %{
          name: "Student Breakfasts",
          description: "Quick, energizing, grab-and-go morning meals for busy student schedules."
        },
        %{
          name: "Student Lunches",
          description: "Packable lunchbox ideas, meal prep bowls, and easy campus lunches."
        },
        %{
          name: "Budget Dinners",
          description: "Affordable, nutrient-dense dinners that are cheap and fast to cook."
        },
        %{
          name: "Back-to-School Meal Plan",
          description: "Weekly structured meal planning for academic terms and family routines."
        }
      ]
    },
    %{
      season_name: "Ramadan",
      start_date: ~D[2026-02-15],
      end_date: ~D[2026-04-15],
      collections: [
        %{
          name: "Iftar Collection",
          description:
            "Hearty, comforting meals, soups, and traditional dishes to break the fast."
        },
        %{
          name: "Suhoor Collection",
          description:
            "Nourishing, slow-burning, hydrating breakfast recipes for early morning pre-dawn meals."
        },
        %{
          name: "Ramadan Drinks",
          description:
            "Refreshing juices, hibiscus drinks, date smoothies, and hydrating infusions."
        },
        %{
          name: "Ramadan Desserts",
          description: "Sweet pastries, syrup-drenched treats, kunafa, and celebratory sweets."
        }
      ]
    }
  ]

  @doc "Returns the definition map of standard seasonal collections"
  def seasonal_definitions, do: @seasons

  @doc "Seeds or updates all curated seasonal collections"
  def seed_seasonal_collections(admin_user \\ nil) do
    user = admin_user || get_default_creator()

    unless user do
      raise "No admin or creator user found to own seasonal collections"
    end

    Enum.flat_map(@seasons, fn season ->
      Enum.map(season.collections, fn col_info ->
        seed_collection(user, season, col_info)
      end)
    end)
  end

  defp seed_collection(user, season, col_info) do
    slug =
      col_info.name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/i, "_")
      |> String.trim("_")

    attrs = %{
      "name" => col_info.name,
      "slug" => slug,
      "description" => col_info.description,
      "is_public" => true,
      "is_curated" => true,
      "is_premium" => true,
      "is_seasonal" => true,
      "season_name" => season.season_name,
      "start_date" => season.start_date,
      "end_date" => season.end_date
    }

    case Repo.get_by(Collection, user_id: user.id, slug: slug) do
      nil ->
        case Collections.create_collection(user, attrs) do
          {:ok, col} ->
            col

          {:error, cs} ->
            raise "Failed to seed seasonal collection #{col_info.name}: #{inspect(cs.errors)}"
        end

      existing ->
        case Collections.update_collection(existing, attrs) do
          {:ok, updated} ->
            updated

          {:error, cs} ->
            raise "Failed to update seasonal collection #{col_info.name}: #{inspect(cs.errors)}"
        end
    end
  end

  defp get_default_creator do
    Repo.one(from u in User, where: u.role == "admin", limit: 1) ||
      Repo.one(from u in User, limit: 1)
  end
end
