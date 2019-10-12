defmodule Sievex.MixProject do
  use Mix.Project

  def project do
    [
      app: :sievex,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Sievex",
      source_url: "https://github.com/alizain/sievex",
      homepage_url: "https://YOUR_PROJECT_HOMEPAGE",
      docs: [
        main: "Sievex"
        # api_reference: false,
      ],
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
      {:faker, "~> 0.13", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
