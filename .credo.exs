# This file contains the configuration for Credo and you are probably reading
# this after creating it with `mix credo.gen.config`.
#
# If you find anything wrong or unclear in this file, please report an
# issue on GitHub: https://github.com/rrrene/credo/issues
#
%{
  #
  # You can have as many configs as you like in the `configs:` field.
  configs: [
    %{
      #
      # Run any config using `mix credo -C <name>`. If no config name is given
      # "default" is used.
      #
      name: "default",
      #
      # These are the files included in the analysis:
      files: %{
        #
        # You can give explicit globs or simply directories.
        # In the latter case `**/*.{ex,exs}` will be used.
        #
        included: [
          "lib/",
          "src/",
          "test/",
          "web/",
          "apps/*/lib/",
          "apps/*/src/",
          "apps/*/test/",
          "apps/*/web/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/ytd_web.ex", ~r"/core_components.ex"]
      },
      #
      # Load and configure plugins here:
      #
      plugins: [],
      #
      # If you create your own checks, you must specify the source files for
      # them here, so they can be loaded by Credo before running the analysis.
      #
      requires: [],
      #
      # If you want to enforce a style guide and need a more traditional linting
      # experience, you can change `strict` to `true` below:
      #
      strict: true,
      #
      # To modify the timeout for parsing files, change this value:
      #
      parse_timeout: 5000,
      #
      # If you want to use uncolored output by default, you can change `color`
      # to `false` below:
      #
      color: true,
      #
      # You can customize the parameters of any check by adding a second element
      # to the tuple.
      #
      # To disable a check put `false` as second element:
      #
      #     {Credo.Check.Design.DuplicatedCode, false}
      #
      checks: %{
        disabled: [
          # Styler Rewrites
          #
          # The following rules are automatically rewritten by Styler and so disabled here to save time
          # Some of the rules have `priority: :high`, meaning Credo runs them unless we explicitly disable them
          # (removing them from this file wouldn't be enough, the `false` is required)
          #
          # Some rules have a comment before them explaining ways Styler deviates from the Credo rule.
          #
          # always expands `A.{B, C}`
          {Credo.Check.Consistency.MultiAliasImportRequireUse, false},
          # including `case`, `fn` and `with` statements
          {Credo.Check.Consistency.ParameterPatternMatching, false},
          {Credo.Check.Readability.AliasOrder, false},
          {Credo.Check.Readability.BlockPipe, false},
          # goes further than formatter - fixes bad underscores, eg: `100_00` -> `10_000`
          {Credo.Check.Readability.LargeNumbers, false},
          # adds `@moduledoc false`
          {Credo.Check.Readability.ModuleDoc, false},
          {Credo.Check.Readability.MultiAlias, false},
          {Credo.Check.Readability.OneArityFunctionInPipe, false},
          # removes parens
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, false},
          {Credo.Check.Readability.PipeIntoAnonymousFunctions, false},
          {Credo.Check.Readability.PreferImplicitTry, false},
          {Credo.Check.Readability.SinglePipe, false},
          # **potentially breaks compilation** - see **Troubleshooting** section below
          {Credo.Check.Readability.StrictModuleLayout, false},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, false},
          {Credo.Check.Refactor.CaseTrivialMatches, false},
          {Credo.Check.Refactor.CondStatements, false},
          # in pipes only
          {Credo.Check.Refactor.FilterCount, false},
          # in pipes only
          {Credo.Check.Refactor.MapInto, false},
          # in pipes only
          {Credo.Check.Refactor.MapJoin, false},
          {Credo.Check.Refactor.NegatedConditionsInUnless, false},
          {Credo.Check.Refactor.NegatedConditionsWithElse, false},
          # allows ecto's `from
          {Credo.Check.Refactor.PipeChainStart, false},
          {Credo.Check.Refactor.RedundantWithClauseResult, false},
          {Credo.Check.Refactor.UnlessWithElse, false},
          {Credo.Check.Refactor.WithClauses, false}
        ]
      }
    }
  ]
}
