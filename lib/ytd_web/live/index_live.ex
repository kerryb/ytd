defmodule YtdWeb.IndexLive do
  @moduledoc """
  Live view for main index page."
  """

  use YtdWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
