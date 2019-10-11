defmodule Sievex.MixProject do
  use Mix.Project

  def project do
    [
      app: :sievex,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [
        test: ["test --trace --cover"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.0", only: :dev},
      {:faker, "~> 0.13", only: :dev}
    ]
  end
end
