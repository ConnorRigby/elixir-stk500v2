defmodule Stk500.Framing do
  @behaviour Nerves.Uart.Framing

  def init(_opts) do
    {:ok, <<>>}
  end

  def add_framing(data, rx_Buffer) do
    {:ok, data, <<>>}
  end

  def frame_timeout(buffer) do
    IO.puts "timeout"
    {:error, :uhh, <<>>}
  end

  def flush(_, _buffer) do
    <<>>
  end

  def remove_framing(data, buffer) do
    process_data(buffer <> data, [])
  end

  def process_data(<<0x1b, sequence, msg_size::size(16), 0x0E, body::binary-size(msg_size), check>> = msg, messages) do
    IO.puts "perfect data"
    {:ok, messages ++ [msg], <<>>}
  end

  def process_data(<<0x1b, sequence, msg_size::size(16), 0x0E, body::binary-size(msg_size), check, rest :: binary>>, messages) do
    IO.puts "too much data"
    msg = <<0x1b, sequence, msg_size::size(16), 0x0E, body, check>>
    process_data(rest, messages ++ [msg])
  end

  def process_data(<<>>, messages) do
    {:ok, messages, <<>>}
  end

  def process_data(partial, messages) do
    IO.puts "partial: #{inspect partial}"
    {:in_frame, messages, partial}
  end
end
