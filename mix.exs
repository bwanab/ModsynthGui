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
      applications: [:sc_em, :scenic, :modsynth_rand],
      mod: {ModsynthGui, []},
      extra_applications: [:crypto, :scenic_table]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.10"},
      {:scenic_table, path: "../scenic_table"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
      {:sc_em, path: "../sc_em"},
      {:modsynth_rand, path: "../modsynth_rand"},
      {:jason, "~> 1.2"},
      {:music_prims, path: "../music_prims"},
      {:midi_in, path: "../midi_in"}
    ]
  end
end
