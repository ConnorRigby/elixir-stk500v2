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

  use Bitwise
  def run do
    {:ok, uart} = UART.start_link()
    :ok = UART.open(uart, "/dev/ttyACM0", speed: 115200, data_bits: 8, stop_bits: 1, parity: :none, active: false, framing: UART.Framing.None)
    UART.set_dtr(uart, false)
    UART.set_rts(uart, false)
    Process.sleep(250)
    UART.set_dtr(uart, true)
    UART.set_rts(uart, true)
    Process.sleep(250)
    # CMD_SIGN_ON
    msg = <<@message_start, 0, <<0,1>>, @token, <<@cmd_sign_on>> >>
    checksum = Enum.reduce(to_charlist(msg), 0, fn(char, acc) -> acc ^^^ char  end)
    IO.inspect msg
    UART.write(uart, msg <> <<checksum>>)
    IO.puts "RECEIVED: #{inspect elem(UART.read(uart, 250), 1)}"
    UART.close(uart)
    UART.stop(uart)
    # CMD_GET_PARAMETER, PARAM_TOPCARD_DETECT
    # CMD_GET_PARAMETER, PARAM_HW_VER
    # CMD_GET_PARAMETER, PARAM_SW_MAJOR
    # CMD_GET_PARAMETER, PARAM_SW_MINOR
  end
end
