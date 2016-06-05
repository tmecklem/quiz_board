defmodule QuizBoard do
  def start do
    {:ok, reset} = ResetButton.start_link(26)
    {:ok, bonus} = BonusButton.start_link(21)
    teams_buzzers = [
      Enum.map([
        Buzzer.start_link( 5, 17),
        Buzzer.start_link( 6, 27),
        Buzzer.start_link(13, 22),
        Buzzer.start_link(19, 10)
      ], fn {:ok, buzzer} -> buzzer end),

      Enum.map([
        Buzzer.start_link( 7, 18),
        Buzzer.start_link(12, 23),
        Buzzer.start_link(16, 24),
        Buzzer.start_link(20, 25),
      ], fn {:ok, buzzer} -> buzzer end)
    ]

    Agent.start_link(fn ->
      %{teams_buzzers: teams_buzzers, bonus: bonus, selected_buzzer: nil}
    end, name: __MODULE__)

    ResetButton.wait_for_press(reset)
    wait_for_buzzer_press
    reset_board
    loop
  end

  def loop do
    receive do
      {:reset_pressed, _} -> reset_board
      {:button_pressed, buzzer} ->
        select_buzzer(buzzer)
        clear_wait_for_buzzer_press
        BonusButton.wait_for_press(bonus_button)
      {:bonus_pressed, _} -> enter_bonus
    end

    loop
  end

  defp wait_for_buzzer_press do
    Enum.each(buzzers, fn buzzer -> Buzzer.wait_for_press(buzzer) end)
  end

  defp clear_wait_for_buzzer_press do
    Enum.each(buzzers, fn buzzer -> Buzzer.clear_wait(buzzer) end)
  end

  defp select_buzzer(buzzer) do
    selected_buzzer = Agent.get(__MODULE__, &(&1)).selected_buzzer
    unless selected_buzzer do
      Agent.update(__MODULE__, fn state ->
        %{state | selected_buzzer: buzzer}
      end)
      Buzzer.select(buzzer)
    end
  end

  defp enter_bonus do
    selected_buzzer = Agent.get(__MODULE__, &(&1)).selected_buzzer
    Agent.get(__MODULE__, &(&1)).teams_buzzers
      |> Enum.find(nil, fn team_buzzers -> Enum.member?(team_buzzers, selected_buzzer) end)
      |> Enum.each(fn buzzer -> Buzzer.select(buzzer) end)
  end

  defp reset_board do
    Agent.update(__MODULE__, fn state ->
      %{state | selected_buzzer: nil}
    end)
    Enum.each(buzzers, fn buzzer -> Buzzer.reset(buzzer) end)
    BonusButton.clear_wait(bonus_button)
    clear_wait_for_buzzer_press
    wait_for_buzzer_press
  end

  defp buzzers do
    Enum.concat(state.teams_buzzers)
  end

  defp bonus_button do
    state.bonus
  end

  defp state do
    Agent.get(__MODULE__, &(&1))
  end
end
