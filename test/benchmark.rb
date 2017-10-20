require "test_helper"

require "benchmark/ips"


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
end

#  decompose      5.646M (± 3.1%) i/s -     28.294M in   5.015759s
# positional      5.629M (± 8.0%) i/s -     28.069M in   5.029745s
