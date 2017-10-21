require "test_helper"

require "benchmark/ips"


def positional_vs_decompose
  arg = [ [1, 2], 3 ]

  def a((one, two), three)
    one + two + three
  end

  def b(arr, three)
    arr[0] + arr[1] + three
  end

  Benchmark.ips do |x|
    x.report("decompose") { a(*arg) }
    x.report("positional") { b(*arg) }
    x.compare!
  end

  #  decompose      5.646M (± 3.1%) i/s -     28.294M in   5.015759s
  # positional      5.629M (± 8.0%) i/s -     28.069M in   5.029745s
end

# positional_vs_decompose

##########################################################

class Callable
  def initialize(proc, i)
    @proc = proc
    @i = i
  end

  def call(args)
    @proc.(@i, args)
  end
end

def scoped(proc, i)
  ->(args) { proc.(i, args) }
end

def object_vs_method_scope
  proc = ->(i, args) { i + args }

  callable = Callable.new(proc, 2)
  scoped  = scoped(proc, 2)

  Benchmark.ips do |x|
    x.report("callable") { callable.(1) }
    x.report("scoped")   { scoped.(1) }
    x.compare!
  end
end

object_vs_method_scope

# Comparison:
#             callable:  4620906.3 i/s
#               scoped:  3388535.6 i/s - 1.36x  slower
