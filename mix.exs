defmodule Loom.Mixfile do
  use Mix.Project

  def project do
    [app: :loom,
     description: "A modern CRDT library that uses protocols to create composable CRDTs.",
     package: package(),
     version: "0.1.0-dev",
     elixir: "~> 1.0",
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
    #  docs: [readme: true, main: "README"]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:dialyze, "~> 0.1.3", only: :dev},
      {:earmark, "~> 0.1", only: :dev},
      {:excheck, "~> 0.2.0", only: [:dev,:test]},
      {:excoveralls, "~> 0.3", only: :dev},
      {:ex_doc, "~> 0.7", only: :dev},
      {:triq, github: "krestenkrab/triq", only: [:dev,:test]},
      {:inch_ex, only: :dev},
    ]
  end

  defp package do
    %{licenses: ["Apache 2"],
    links: %{"Github" => "https://github.com/asonge/loom"},
    contributors: ["Alex Songe"]}
  end

end
