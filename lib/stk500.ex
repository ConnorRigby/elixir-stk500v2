defmodule Stk500 do
  # http://www.diericx.net/downloads/STK500v2.pdf
  alias Nerves.UART
  @message_start                       0x1b # 27
  @token                               0x0e # 14

  @cmd_sign_on                         0x01
  @cmd_set_parameter                   0x02
  @cmd_get_parameter                   0x03
  @cmd_set_device_parameters           0x04
  @cmd_osccal                          0x05
  @cmd_load_address                    0x06
  @cmd_firmware_upgrade                0x07
  @cmd_check_target_connection         0x0d
  @cmd_load_rc_id_table                0x0e
  @cmd_load_ec_id_table                0x0f
  @cmd_enter_progmode_isp              0x10
  @cmd_leave_progmode_isp              0x11
  @cmd_chip_erase_isp                  0x12
  @cmd_program_flash_isp               0x13
  @cmd_read_flash_isp                  0x14
  @cmd_program_eeprom_isp              0x15
  @cmd_read_eeprom_isp                 0x16
  @cmd_program_fuse_isp                0x17
  @cmd_read_fuse_isp                   0x18
  @cmd_program_lock_isp                0x19
  @cmd_read_lock_isp                   0x1a
  @cmd_read_signature_isp              0x1b
  @cmd_read_osccal_isp                 0x1c
  @cmd_spi_multi                       0x1d
  @cmd_set_sck                         0x1d
  @cmd_get_sck                         0x1e

  @status_cmd_ok 0x00

  @param_topcard_detect 0x9A
  @param_hw_ver 0x90
  @param_sw_major 0x91
  @param_sw_minor 0x92

  @sleep_time 500

  use Bitwise
  def run do
    {:ok, uart} = UART.start_link()
    :ok = UART.open(uart, "/dev/ttyACM0", [
      speed: 115200,
      data_bits: 8,
      stop_bits: 1,
      parity: :none,
      active: false,
      framing: Nerves.UART.Framing.None
    ])

    UART.set_dtr(uart, false)
    UART.set_rts(uart, false)

    Process.sleep(250)

    UART.set_dtr(uart, true)
    UART.set_rts(uart, true)

    Process.sleep(250)
    UART.flush(uart, :both)
    UART.configure(uart, [framing: Stk500.Framing])

    seq = 0
    check_sig(uart, seq)
  end

  defp bye(uart, reason) do
    IO.puts "Exit: #{reason}"
    UART.close(uart)
    UART.stop(uart)
  end

  def check_sig(uart, seq) do
    # CMD_SIGN_ON
    msg = <<@message_start, seq, <<0,1>>, @token, <<@cmd_sign_on>> >>
    checksum = calc_check(msg)

    UART.write(uart, msg <> <<checksum>>)
    case UART.read(uart, @sleep_time) do
      {:ok, <<@message_start, ^seq, <<0, 11>>, @token, @cmd_sign_on, @status_cmd_ok, 8, <<"AVRISP_2">>, _check>>} ->
        IO.puts "Got signature."
        {:ok, topcard_detect, seq} = get_param(uart, seq + 1, @param_topcard_detect)
        {:ok, hw_ver, seq} = get_param(uart, seq, @param_hw_ver)
        {:ok, sw_major, seq} = get_param(uart, seq, @param_sw_major)
        {:ok, sw_minor, seq} = get_param(uart, seq, @param_sw_minor)

      {:error, reason} -> bye(uart, reason)
    end
  end

  def get_param(uart, seq, param) do
    msg = <<@message_start, seq, <<0, 2>>, @token, <<@cmd_get_parameter, param >> >>
    checksum = calc_check(msg)
    UART.write(uart, msg <> <<checksum>>)
    case UART.read(uart, @sleep_time) do
      {:ok, <<@message_start, ^seq, <<0, 3>>, @token, <<@cmd_get_parameter, @status_cmd_ok, data>>, _check>>} ->
        IO.puts "Read param: #{param} => #{data}"
        {:ok, data, seq + 1}
      {:error, reason} -> bye(uart, inspect reason)
    end
  end

  defp calc_check(msg) do
    Enum.reduce(:erlang.binary_to_list(msg), 0, fn(char, acc) -> acc ^^^ char  end)
  end
end
