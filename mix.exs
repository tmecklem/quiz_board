defmodule QuizBoard.Mixfile do
  use Mix.Project

  def project do
    [app: :quiz_board,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :elixir_ale]]
  end

  defp deps do
    [{:elixir_ale, "~> 0.5.2"}]
  end
end
