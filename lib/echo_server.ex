defmodule EchoServer do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      supervisor(Task.Supervisor, [[name: EchoServer.ImplSupervisor]]),
      worker(Task, [EchoServer.Impl, :accept, [4040]]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EchoServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defmodule Impl do
    def accept(port) do
      # The options below mean:
      #
      # 1. `:binary` - receives data as binaries (instead of lists)
      # 2. `packet: :line` - receives data line by line
      # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
      # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
      #
      {:ok, socket} = :gen_tcp.listen(port,
                        [:binary, packet: :line, active: false, reuseaddr: true])
      IO.puts "Accepting connections on port #{port}"
      loop_acceptor(socket)
    end

    defp loop_acceptor(socket) do
      {:ok, client} = :gen_tcp.accept(socket)
      {:ok, pid} = Task.Supervisor.start_child(EchoServer.ImplSupervisor, fn -> serve(client) end)
      :ok = :gen_tcp.controlling_process(client, pid)
      loop_acceptor(socket)
    end

    defp serve(socket) do
      socket
      |> read_line()
      |> write_line(socket)

      serve(socket)
    end

    defp read_line(socket) do
      case :gen_tcp.recv(socket, 0) do
        {:ok, data} -> data
        {:error, e} -> handle_error(e)
      end

    end

    defp handle_error(:closed) do
      nil
    end

    defp handle_error(e) do
      # Maybe handle other errors differently
      nil
    end

    defp write_line(nil, socket) do
      nil
    end

    defp write_line(line, socket) do
      :gen_tcp.send(socket, line)
    end
  end
end
