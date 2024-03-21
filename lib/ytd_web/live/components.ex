# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule YTDWeb.Components do
  @moduledoc """
  Stateless view components.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.Rendered
  alias Phoenix.LiveView.Socket
  alias YTD.Stats

  attr :stats, Stats, required: true
  attr :target, :integer, required: true
  attr :unit, :atom, required: true
  @spec target_progress(Socket.assigns()) :: Rendered.t()
  def target_progress(assigns) do
    ~H"""
    <%= cond do %>
      <% @stats.completed? -> %>
        <.target_hit target={@target} />
      <% @stats.on_target? -> %>
        <.on_target target={@target} stats={@stats} unit={@unit} />
      <% true -> %>
        <.behind_target target={@target} stats={@stats} unit={@unit} />
    <% end %>
    """
  end

  attr :target, :integer, required: true
  @spec target_hit(Socket.assigns()) :: Rendered.t()
  def target_hit(assigns) do
    ~H"""
    You have hit your target of
    <a class="link" href="#" id="edit-target" phx-click="edit-target">
      <%= @target.target %> <%= @target.unit %>
    </a> !
    """
  end

  attr :stats, Stats, required: true
  attr :target, :integer, required: true
  attr :unit, :atom, required: true
  @spec on_target(Socket.assigns()) :: Rendered.t()
  def on_target(assigns) do
    ~H"""
    You are on track to hit your target of
    <a class="link" href="#" id="edit-target" phx-click="edit-target">
      <%= @target.target %> <%= @target.unit %>
    </a> , as long as you average
    <span class="font-extrabold"><%= @stats.required_average %> <%= @unit %></span> a week from now on.
    """
  end

  attr :stats, Stats, required: true
  attr :target, :integer, required: true
  attr :unit, :atom, required: true
  @spec behind_target(Socket.assigns()) :: Rendered.t()
  def behind_target(assigns) do
    ~H"""
    To hit your target of
    <a class="link" href="#" id="edit-target" phx-click="edit-target">
      <%= @target.target %> <%= @target.unit %>
    </a> , you need to average
    <span class="font-extrabold"><%= @stats.required_average %> <%= @unit %></span> a week from now on.
    """
  end

  attr :target, :integer, required: true
  attr :type, :atom, required: true
  attr :unit, :atom, required: true
  @spec edit_target_modal(Socket.assigns()) :: Rendered.t()
  def edit_target_modal(assigns) do
    ~H"""
    <div class="p-4 fixed flex justify-center items-center inset-0 bg-black bg-opacity-75 z-50">
      <div class="max-w-xl max-h-full bg-strava-orange dark:bg-black dark:border dark:border-strava-orange rounded shadow-lg overflow-auto p-4 mb-2">
        <form id="edit-target-form" phx-submit="submit-target">
          <div class="mb-4">
            <label for="target"><%= @type %> target:</label>
            <input
              autofocus="true"
              class="w-20 text-strava-orange dark:bg-black dark:border dark:border-strava-orange pl-2 ml-2 rounded"
              id="target"
              name="target"
              type="number"
              value={if @target, do: @target.target, else: 0}
            />
            <%= @unit %>
          </div>
          <div class="flex justify-between">
            <button
              class="font-thin border rounded px-1 bg-strava-orange hover:bg-strava-orange-dark dark:bg-black dark:border-strava-orange dark:hover:bg-gray-800"
              phx-click="cancel-target"
              type="button"
            >
              Cancel
            </button>
            <button
              class="font-bold border-2 rounded px-1 bg-white text-strava-orange hover:bg-gray-200 dark:bg-strava-orange dark:border-strava-orange dark:text-black dark:hover:bg-strava-orange-dark"
              type="submit"
            >
              Save
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
