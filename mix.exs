defmodule ModsynthGui.MixProject do
  use Mix.Project

  def project do
    [
      app: :modsynth_gui,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ModsynthGui, []},
      extra_applications: [:crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.11.0"},
      {:scenic_driver_local, "~> 0.11.0"},
      {:sc_em, path: "../sc_em"},
      {:jason, "~> 1.2"}
    ]
  end
end
