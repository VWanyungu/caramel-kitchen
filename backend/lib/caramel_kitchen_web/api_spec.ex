defmodule CaramelKitchenWeb.ApiSpec do
  @moduledoc """
  OpenAPI 3.0 Specifications for Caramel Kitchen API.
  """

  alias OpenApiSpex.{Info, Server, Components, OpenApi, ServerVariable, Paths}

  @dialyzer {:nowarn_function, spec: 0}

  def spec do
    %OpenApi{
      info: %Info{
        title: "Caramel Kitchen API",
        version: "2.0.0",
        description: "API for the Caramel Kitchen v2.0 recipe and meal-planning platform."
      },
      servers: [
        %Server{
          url: "http://localhost:{port}",
          description: "Local Development Server",
          variables: %{
            "port" => %ServerVariable{default: "4000"}
          }
        }
      ],
      tags: [
        %{name: "Auth", description: "Authentication endpoints"},
        %{name: "Recipes", description: "Recipe browsing and management"}
      ],
      components: %Components{
        schemas: %{},
        securitySchemes: %{
          "BearerAuth" => %OpenApiSpex.SecurityScheme{
            type: "http",
            scheme: "bearer",
            bearerFormat: "JWT"
          }
        },
        responses: %{
          "Unauthorized" => %OpenApiSpex.Response{
            description: "Unauthorized",
            content: %{
              "application/json" => %OpenApiSpex.MediaType{
                schema: CaramelKitchenWeb.Schemas.ErrorResponse
              }
            }
          },
          "NotFound" => %OpenApiSpex.Response{
            description: "Not Found",
            content: %{
              "application/json" => %OpenApiSpex.MediaType{
                schema: CaramelKitchenWeb.Schemas.ErrorResponse
              }
            }
          }
        }
      },
      paths: Paths.from_router(CaramelKitchenWeb.Router)
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end

defmodule CaramelKitchenWeb.Schemas do
  @moduledoc "Reusable OpenAPI schemas"
  require OpenApiSpex
  alias OpenApiSpex.Schema

  defmodule ErrorResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "ErrorResponse",
      description: "Standard error response",
      type: :object,
      properties: %{
        error: %Schema{type: :string, description: "Error code or message"}
      },
      required: [:error],
      example: %{"error" => "unauthorized"}
    })
  end

  defmodule Ingredient do
    require OpenApiSpex
    alias OpenApiSpex.Schema

    OpenApiSpex.schema(%{
      title: "Ingredient",
      description: "A recipe ingredient",
      type: :object,
      properties: %{
        name: %Schema{type: :string},
        quantity: %Schema{type: :string},
        unit: %Schema{type: :string, nullable: true},
        notes: %Schema{type: :string, nullable: true}
      },
      required: [:name, :quantity]
    })
  end

  defmodule Step do
    require OpenApiSpex
    alias OpenApiSpex.Schema

    OpenApiSpex.schema(%{
      title: "Step",
      description: "A recipe instruction step",
      type: :object,
      properties: %{
        order: %Schema{type: :integer},
        instruction: %Schema{type: :string},
        duration_minutes: %Schema{type: :integer, nullable: true},
        tip: %Schema{type: :string, nullable: true}
      },
      required: [:order, :instruction]
    })
  end

  defmodule RecipeCard do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "RecipeCard",
      description: "A simplified recipe object for list views",
      type: :object,
      properties: %{
        id: %Schema{type: :string, format: :uuid},
        slug: %Schema{type: :string},
        title: %Schema{type: :string},
        thumbnail_url: %Schema{type: :string, nullable: true},
        dish_category: %Schema{type: :string},
        course: %Schema{type: :string},
        primary_method: %Schema{type: :string},
        difficulty: %Schema{type: :string, enum: ["beginner", "intermediate", "advanced"]},
        total_time_mins: %Schema{type: :integer},
        taste_tags: %Schema{type: :array, items: %Schema{type: :string}},
        dietary_flags: %Schema{type: :array, items: %Schema{type: :string}},
        calories: %Schema{type: :integer, nullable: true},
        avg_rating: %Schema{type: :number},
        rating_count: %Schema{type: :integer},
        cuisine_origin: %Schema{type: :array, items: %Schema{type: :string}},
        taste_score: %Schema{type: :number, nullable: true},
        search_rank: %Schema{type: :number, nullable: true}
      },
      required: [:id, :slug, :title, :total_time_mins]
    })
  end

  defmodule RecipeDetail do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "RecipeDetail",
      description: "A full recipe object with ingredients and steps",
      type: :object,
      properties: %{
        id: %Schema{type: :string, format: :uuid},
        slug: %Schema{type: :string},
        title: %Schema{type: :string},
        description: %Schema{type: :string, nullable: true},
        thumbnail_url: %Schema{type: :string, nullable: true},
        video_url: %Schema{type: :string, nullable: true},
        video_duration_secs: %Schema{type: :integer, nullable: true},
        dish_category: %Schema{type: :string},
        course: %Schema{type: :string},
        primary_method: %Schema{type: :string},
        secondary_method: %Schema{type: :string, nullable: true},
        difficulty: %Schema{type: :string, enum: ["beginner", "intermediate", "advanced"]},
        prep_time_mins: %Schema{type: :integer},
        cook_time_mins: %Schema{type: :integer},
        total_time_mins: %Schema{type: :integer},
        serving_size: %Schema{type: :integer},
        taste_tags: %Schema{type: :array, items: %Schema{type: :string}},
        dietary_flags: %Schema{type: :array, items: %Schema{type: :string}},
        allergens: %Schema{type: :array, items: %Schema{type: :string}},
        allergy_alerts: %Schema{type: :array, items: %Schema{type: :string}, nullable: true},
        calories: %Schema{type: :integer, nullable: true},
        macros: %Schema{type: :object, additionalProperties: true},
        avg_rating: %Schema{type: :number},
        rating_count: %Schema{type: :integer},
        cuisine_origin: %Schema{type: :array, items: %Schema{type: :string}},
        creator_id: %Schema{type: :string, format: :uuid},
        published_at: %Schema{type: :string, format: :"date-time", nullable: true},
        featured_until: %Schema{type: :string, format: :"date-time", nullable: true},
        view_count: %Schema{type: :integer},
        save_count: %Schema{type: :integer},
        cook_count: %Schema{type: :integer},
        ingredients: %Schema{type: :array, items: CaramelKitchenWeb.Schemas.Ingredient},
        steps: %Schema{type: :array, items: CaramelKitchenWeb.Schemas.Step}
      },
      required: [:id, :slug, :title, :ingredients, :steps, :prep_time_mins, :cook_time_mins]
    })
  end
end
