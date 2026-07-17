defmodule CaramelKitchenWeb.ApiSpec do
  @moduledoc """
  OpenAPI 3.0 Specifications for Caramel Kitchen API.
  """

  alias OpenApiSpex.{Info, Server, Components, OpenApi, ServerVariable, Paths}

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
        %{name: "Recipes", description: "Recipe browsing and management"},
      ],
      components: %Components{
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

  defmodule Recipe do
    require OpenApiSpex
    OpenApiSpex.schema(%{
      title: "Recipe",
      description: "A recipe object",
      type: :object,
      properties: %{
        id: %Schema{type: :string, format: :uuid},
        title: %Schema{type: :string},
        description: %Schema{type: :string},
        status: %Schema{type: :string, enum: ["draft", "live", "archived"]},
        dish_category: %Schema{type: :string},
        difficulty: %Schema{type: :string, enum: ["beginner", "intermediate", "advanced"]},
        prep_time_mins: %Schema{type: :integer},
        cook_time_mins: %Schema{type: :integer},
        calories: %Schema{type: :integer},
        taste_tags: %Schema{type: :array, items: %Schema{type: :string}},
        dietary_flags: %Schema{type: :array, items: %Schema{type: :string}},
        thumbnail_url: %Schema{type: :string},
        video_url: %Schema{type: :string, nullable: true}
      },
      required: [:id, :title, :status, :difficulty, :prep_time_mins, :cook_time_mins]
    })
  end
end
