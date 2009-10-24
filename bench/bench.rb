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

Benchmark.bm do |bench|
  bench.report("BERT tiny") {ITER.times {BERT.decode(BERT.encode(tiny))}}
  bench.report("BERT small") {ITER.times {BERT.decode(BERT.encode(small))}}
  bench.report("BERT large") {ITER.times {BERT.decode(BERT.encode(large))}}
  bench.report("BERT complex") {ITER.times {BERT.decode(BERT.encode(complex))}}

  bench.report("JSON tiny") {ITER.times {JSON.load(JSON.dump(tiny))}}
  bench.report("JSON small") {ITER.times {JSON.load(JSON.dump(small))}}
  bench.report("JSON large") {ITER.times {JSON.load(JSON.dump(large))}}
  bench.report("JSON complex") {ITER.times {JSON.load(JSON.dump(complex))}}

  bench.report("YAJL tiny") {ITER.times {Yajl::Parser.parse(Yajl::Encoder.encode(tiny))}}
  bench.report("YAJL small") {ITER.times {Yajl::Parser.parse(Yajl::Encoder.encode(small))}}
  bench.report("YAJL large") {ITER.times {Yajl::Parser.parse(Yajl::Encoder.encode(large))}}
  bench.report("YAJL complex") {ITER.times {Yajl::Parser.parse(Yajl::Encoder.encode(complex))}}

  bench.report("Ruby tiny") {ITER.times {Marshal.load(Marshal.dump(tiny))}}
  bench.report("Ruby small") {ITER.times {Marshal.load(Marshal.dump(small))}}
  bench.report("Ruby large") {ITER.times {Marshal.load(Marshal.dump(large))}}
  bench.report("Ruby complex") {ITER.times {Marshal.load(Marshal.dump(complex))}}
end