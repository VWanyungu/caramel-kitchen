defmodule CaramelKitchenWeb.ErrorJSON do
  @moduledoc """
  Renders JSON error responses for Phoenix.
  Called automatically by Phoenix on 404, 500, etc.
  """

  # 404
  def render("404.json", _assigns) do
    %{error: "not_found", message: "The requested resource does not exist"}
  end

  # 400
  def render("400.json", _assigns) do
    %{error: "bad_request", message: "The request could not be understood"}
  end

  # 401
  def render("401.json", _assigns) do
    %{error: "unauthorized", message: "Authentication required"}
  end

  # 403
  def render("403.json", _assigns) do
    %{error: "forbidden", message: "You do not have permission to perform this action"}
  end

  # 422
  def render("422.json", _assigns) do
    %{error: "unprocessable_entity", message: "The request could not be processed"}
  end

  # 429
  def render("429.json", _assigns) do
    %{error: "rate_limit_exceeded", message: "Too many requests. Please slow down."}
  end

  # 500
  def render("500.json", _assigns) do
    %{error: "internal_server_error", message: "Something went wrong on our end. We've been notified."}
  end

  # 503
  def render("503.json", _assigns) do
    %{error: "service_unavailable", message: "Service temporarily unavailable. Please try again shortly."}
  end

  # Catch-all
  def render(template, _assigns) do
    %{error: Phoenix.Controller.status_message_from_template(template)}
  end
end
