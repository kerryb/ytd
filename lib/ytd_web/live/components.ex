# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule YTDWeb.Components do
  @moduledoc """
  Stateless view components.
  """

  use Phoenix.Component

  alias YTD.Stats

  embed_templates "components/*"

  attr :stats, Stats, required: true
  attr :target, :integer, required: true
  attr :unit, :atom, required: true
  def target_progress(assigns)

  attr :target, :integer, required: true
  def target_hit(assigns)

  attr :stats, Stats, required: true
  attr :target, :integer, required: true
  attr :unit, :atom, required: true
  def on_target(assigns)

  attr :stats, Stats, required: true
  attr :target, :integer, required: true
  attr :unit, :atom, required: true
  def behind_target(assigns)

  attr :target, :integer, required: true
  attr :type, :atom, required: true
  attr :unit, :atom, required: true
  def edit_target_modal(assigns)
end
