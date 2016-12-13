defmodule Murk.Mixfile do
  use Mix.Project

  def project do
    [app: :murk,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    []
  end

  defp deps do
    []
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE", "config"],
     maintainers: ["Kevin W. van Rooijen"],
     licenses: ["GPL3"],
     links: %{"GitHub": "https://github.com/kwrooijen/murk"}]
  end
end
