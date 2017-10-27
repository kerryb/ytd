defmodule YTDWeb.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use YTDWeb.ConnCase
      use PhoenixIntegration
    end
  end
end
