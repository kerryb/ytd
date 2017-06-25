defmodule YTDWeb.Web.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use YTDWeb.Web.ConnCase
      use PhoenixIntegration
    end
  end
end
