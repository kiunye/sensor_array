# Credo — run: mix credo or mix credo --strict
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "config/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/priv/"]
      },
      checks: [
        {Credo.Check.Design.AliasUsage, priority: :low},
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 120},
        {Credo.Check.Design.TagTODO, exit_status: 0},
        {Credo.Check.Design.TagFIXME, exit_status: 0}
      ]
    }
  ]
}
