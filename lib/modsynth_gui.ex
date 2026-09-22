defmodule ModsynthGui do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    # load the viewport configuration from config

    # start the application with the viewport
    children = [
      {Scenic, [Application.get_env(:modsynth_gui, :viewport)]},
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
