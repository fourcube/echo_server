defmodule EchoServerTest do
  use ExUnit.Case
  doctest EchoServer

  test "simply echoes everything back" do
    {:ok, socket} = :gen_tcp.connect String.to_char_list("127.0.0.1"), 4040, [:binary, active: false]

    :ok = :gen_tcp.send socket, "foo\n"
    {:ok, "foo\n"} = :gen_tcp.recv(socket, 0)
  end
end
