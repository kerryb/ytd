# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    default_release: :ytd,
    default_environment: :prod

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: "YTD_ERLANG_COOKIE" |> System.get_env |> String.to_atom
  set post_start_hook: "rel/hooks/post_start"
end

release :ytd do
  set version: "VERSION" |> File.read! |> String.trim
end
