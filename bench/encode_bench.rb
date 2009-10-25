$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'bert'
require 'json'
require 'yajl'
require 'benchmark'

ITER = 1_000

tiny = t[:ok, :awesome]
small = t[:ok, :answers, [42] * 42]
large = ["abc" * 1000] * 100
complex = [42, {:foo => 'bac' * 100}, t[(1..100).to_a]] * 10

Benchmark.bm(13) do |bench|
  bench.report("BERT tiny")    {ITER.times {BERT.encode(tiny)}}
  bench.report("BERT small")   {ITER.times {BERT.encode(small)}}
  bench.report("BERT large")   {ITER.times {BERT.encode(large)}}
  bench.report("BERT complex") {ITER.times {BERT.encode(complex)}}
  puts
  bench.report("JSON tiny")    {ITER.times {JSON.dump(tiny)}}
  bench.report("JSON small")   {ITER.times {JSON.dump(small)}}
  bench.report("JSON large")   {ITER.times {JSON.dump(large)}}
  bench.report("JSON complex") {ITER.times {JSON.dump(complex)}}
  puts
  bench.report("JSON tiny")    {ITER.times {Yajl::Encoder.encode(tiny)}}
  bench.report("JSON small")   {ITER.times {Yajl::Encoder.encode(small)}}
  bench.report("JSON large")   {ITER.times {Yajl::Encoder.encode(large)}}
  bench.report("JSON complex") {ITER.times {Yajl::Encoder.encode(complex)}}
  puts
  bench.report("Ruby tiny")    {ITER.times {Marshal.dump(tiny)}}
  bench.report("Ruby small")   {ITER.times {Marshal.dump(small)}}
  bench.report("Ruby large")   {ITER.times {Marshal.dump(large)}}
  bench.report("Ruby complex") {ITER.times {Marshal.dump(complex)}}
end