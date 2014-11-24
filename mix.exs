defmodule Loom.Mixfile do
  use Mix.Project

  def project do
    [app: :loom,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps,
     test_coverage: [tool: ExCoveralls],
     docs: [readme: true, main: "README"]
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
      {:ex_doc, "~> 0.6", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
      {:excoveralls, "~> 0.3", only: :dev},
      {:dialyze, "~> 0.1.3", only: :dev},
      {:inch_ex, only: :docs}
    ]
  end
end
