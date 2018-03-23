defmodule Stk500.Msg do
  defstruct [:message_start, :sequence_number, :message_size, :token, :message_body, :checksum]

  def parse_msg(
        <<start, sequence, msg_size::size(16), 0x0E, body::binary-size(msg_size), check>>
      ) do
        %__MODULE__{
          message_start: start,
          sequence_number: sequence,
          message_size: msg_size,
          token: <<0x0E>>,
          message_body: body,
          checksum: check
        }
  end
end
