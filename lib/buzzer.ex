defmodule Buzzer do
  @on 0
  @off 1
  def start_link(button_pin, light_pin) do
    {:ok, button} = Gpio.start_link(button_pin, :input)
    {:ok, light} = Gpio.start_link(light_pin, :output)
    {:ok, pid} = Agent.start_link(fn ->
      %{button: button, light: light, interrupt_pid: nil}
    end)
    interrupt_pid = spawn(ButtonInterrupt, :start, [pid, self, :button_pressed])
    Agent.update(pid, fn state ->
      %{state | interrupt_pid: interrupt_pid}
    end)
    {:ok, pid}
  end

  def wait_for_press(pid) do
    interrupt_pid = Agent.get(pid, &(&1)).interrupt_pid
    send(interrupt_pid, {:set_interrupt})
  end

  def clear_wait(pid) do
    interrupt_pid = Agent.get(pid, &(&1)).interrupt_pid
    send(interrupt_pid, {:clear_interrupt})
  end

  def reset(pid) do
    darken(pid)
  end

  def select(pid) do
    enlighten(pid)
  end

  defp enlighten(pid) do
    light = Agent.get(pid, &(&1)).light
    Gpio.write(light, @on)
  end

  defp darken(pid) do
    light = Agent.get(pid, &(&1)).light
    Gpio.write(light, @off)
  end
end

defmodule BonusButton do
  def start_link(button_pin) do
    {:ok, button} = Gpio.start_link(button_pin, :input)
    {:ok, pid} = Agent.start_link(fn ->
      %{button: button, interrupt_pid: nil}
    end)
    interrupt_pid = spawn(ButtonInterrupt, :start, [pid, self, :bonus_pressed])
    Agent.update(pid, fn state ->
      %{state | interrupt_pid: interrupt_pid}
    end)
    {:ok, pid}
  end

  def wait_for_press(pid) do
    interrupt_pid = Agent.get(pid, &(&1)).interrupt_pid
    send(interrupt_pid, {:set_interrupt})
  end

  def clear_wait(pid) do
    interrupt_pid = Agent.get(pid, &(&1)).interrupt_pid
    send(interrupt_pid, {:clear_interrupt})
  end
end

defmodule ResetButton do
  def start_link(button_pin) do
    {:ok, button} = Gpio.start_link(button_pin, :input)
    {:ok, pid} = Agent.start_link(fn ->
      %{button: button, interrupt_pid: nil}
    end)
    interrupt_pid = spawn(ButtonInterrupt, :start, [pid, self, :reset_pressed])
    Agent.update(pid, fn state ->
      %{state | interrupt_pid: interrupt_pid}
    end)
    {:ok, pid}
  end

  def wait_for_press(pid) do
    interrupt_pid = Agent.get(pid, &(&1)).interrupt_pid
    send(interrupt_pid, {:set_interrupt})
  end
end

defmodule ButtonInterrupt do
  def start(pid, sender, message) do
    receive do
      {:set_interrupt} -> Gpio.set_int(button(pid), :rising)
      {:gpio_interrupt, pin, :rising} -> send(sender, {message, pid})
      {:clear_interrupt} -> Gpio.set_int(button(pid), :none)
    end
    start(pid, sender, message)
  end

  defp button(pid) do
    Agent.get(pid, &(&1)).button
  end
end
