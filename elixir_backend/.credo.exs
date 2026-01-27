%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Readability.ModuleDoc, false},
        {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 15},
        {Credo.Check.Refactor.Nesting, max_nesting: 4},
        {Credo.Check.Readability.PreferImplicitTry, false},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, false},
        {Credo.Check.Readability.AliasOrder, false},
        {Credo.Check.Readability.WithSingleClause, false},
        {Credo.Check.Design.AliasUsage, false},
        {Credo.Check.Readability.LargeNumbers, false}
      ]
    }
  ]
}
