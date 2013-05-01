defmodule Tracer do
  def run(pid) do
    :inets.start
    tpid = spawn(fn-> Tracer.Loop.run end)
    :erlang.trace(pid, true, [:send, :receive, :procs, :set_on_spawn, :timestamp, { :tracer, tpid }])
  end
end

defmodule Tracer.Loop do
  def run do
    receive do
      { :trace_ts, pid, :receive, message, ts } ->
        Tracer.Client.send(pid, :receive, [message: message], ts)
        run
      { :trace_ts, pid, :send, message, to, ts } ->
        Tracer.Client.send(pid, :send, [to: to, messge: message], ts)
        run
      { :trace_ts, pid, :spawn, new_pid, { mod, fun, args }, ts } ->
        Tracer.Client.send(pid, :spawn, [new_pid: new_pid, mod: mod, fun: fun, args: args], ts)
        run
      { :trace_ts, pid, :exit, reason, ts } ->
        Tracer.Client.send(pid, :exit, [reason: reason], ts)
        run
      _ ->
        run
    end
  end
end

defmodule Tracer.Client do
  def send(pid, type, contents, ts) do
    url = make_url([pid: inspect(pid), type: inspect(type), contents: inspect(contents), ts: inspect(ts)])
    :httpc.request(:get, {url ,[]}, [], [sync: false])
  end

  defp make_url(query) do
    binary_to_list("http://localhost:4000/register?" <> URI.encode_query(query))
  end
end
