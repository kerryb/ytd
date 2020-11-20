{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:wallaby)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(YTD.Repo, :manual)

Application.put_env(:wallaby, :base_url, YTDWeb.Endpoint.url())

"screenshots/*" |> Path.wildcard() |> Enum.each(&File.rm/1)
