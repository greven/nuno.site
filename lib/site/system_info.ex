defmodule Site.SystemInfo do
  @moduledoc """
  This module provides helpers to fetch system information from the host machine
  or any connected nodes.
  """

  ## Memory

  @doc """
  Fetches the memory usage of the Erlang VM.

  ## Keys

    * `:total` - Total memory allocated (sum of processes and system)
    * `:processes` - Memory allocated for Erlang processes
    * `:atom` - Memory allocated for atoms (part of system memory)
    * `:binary` - Memory allocated for binaries (part of system memory)
    * `:code` - Memory allocated for Erlang code (part of system memory)
    * `:ets` - Memory allocated for ETS tables (part of system memory)
    * `:other` - Memory allocated for other purposes
  """
  def vm_memory do
    memory = :erlang.memory()
    total = memory[:total]
    processes = memory[:processes]
    atom = memory[:atom]
    binary = memory[:binary]
    code = memory[:code]
    ets = memory[:ets]

    %{
      total: total,
      processes: processes,
      atom: atom,
      binary: binary,
      code: code,
      ets: ets,
      other: total - processes - atom - binary - code - ets
    }
  end

  @doc """
  Returns the system memory information in bytes as a map.
  Requires the `:os_mon` application to be started in `mix.exs`.

  ## Keys

    * `:total_memory` - Total amount of memory available to the Erlang emulator
    * `:available_memory` - Amount of memory available for increased usage
    * `:free_memory` - Amount of free memory available for allocation
    * `:system_total_memory` - Total memory available to the operating system
    * `:buffered_memory` - Memory used for temporary raw disk blocks
    * `:cached_memory` - Memory used for cached files and kernel slab
    * `:total_swap` - Total amount of swap memory available
    * `:free_swap` - Available swap memory

  Note: On Linux systems without `:available_memory`, you can approximate it by
  summing `:cached_memory`, `:buffered_memory`, and `:free_memory`.
  Note: Not all keys are available on all platforms.
  """
  def system_memory do
    :memsup.get_system_memory_data()
    |> Map.new()
  end

  ## CPU

  @doc """
  Returns the system CPU information as a map.

  ## Keys

    * `:cpu_avg1` - Average CPU usage over the last 1 minute
    * `:cpu_avg5` - Average CPU usage over the last 5 minutes
    * `:cpu_avg15` - Average CPU usage over the last 15 minutes
    * `:cpu_nprocs` - Number of processes running on the system
    * `:cpu_per_core` - CPU usage per core as a list of tuples with the core number and usage

  The `:cpu_per_core` key contains a list of tuples with the core number and usage as a map, with
  the following keys:

    * `:idle` - Percentage of time the core was idle
    * `:kernel` - Percentage of time the core was running kernel processes
    * `:user` - Percentage of time the core was running user processes
    * `:nice_user` - Percentage of time the core was running user processes with a nice value
  """
  def cpu_info do
    cpu_per_core =
      case :cpu_sup.util([:detailed, :per_cpu]) do
        {:all, 0, 0, []} -> []
        cores -> Enum.map(cores, fn {n, busy, non_b, _} -> {n, Map.new(busy ++ non_b)} end)
      end

    %{
      cpu_avg1: :cpu_sup.avg1(),
      cpu_avg5: :cpu_sup.avg5(),
      cpu_avg15: :cpu_sup.avg15(),
      cpu_nprocs: :cpu_sup.nprocs(),
      cpu_per_core: cpu_per_core
    }
  end

  ## Disk

  @doc """
  Returns the disk information as a list of tuples with the following elements `{id, totalKiB, capacity}`, where

    * `id` - A string that identifies the disk or partition
    * `totalKiB` - The total size of the disk or partition in KiB
    * `capacity` - The percentage of disk space used.

  """
  def disk_info do
    case :disksup.get_disk_data() do
      [{~c"none", 0, 0}] -> []
      other -> other
    end
  end
end
