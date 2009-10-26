$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'json'
require 'yajl'
require 'benchmark'

ITER = 1_000

def setup
  tiny = t[:ok, :awesome]
  small = t[:ok, :answers, [42] * 42]
  large = ["abc" * 1000] * 100
  complex = [42, {:foo => 'bac' * 100}, t[(1..100).to_a]] * 10

  $tiny_encoded_bert = BERT.encode(tiny)
  $small_encoded_bert = BERT.encode(small)
  $large_encoded_bert = BERT.encode(large)
  $complex_encoded_bert = BERT.encode(complex)

  $tiny_encoded_json = JSON.dump(tiny)
  $small_encoded_json = JSON.dump(small)
  $large_encoded_json = JSON.dump(large)
  $complex_encoded_json = JSON.dump(complex)

  $tiny_encoded_yajl = Yajl::Encoder.encode(tiny)
  $small_encoded_yajl = Yajl::Encoder.encode(small)
  $large_encoded_yajl = Yajl::Encoder.encode(large)
  $complex_encoded_yajl = Yajl::Encoder.encode(complex)

  $tiny_encoded_ruby = Marshal.dump(tiny)
  $small_encoded_ruby = Marshal.dump(small)
  $large_encoded_ruby = Marshal.dump(large)
  $complex_encoded_ruby = Marshal.dump(complex)
end

Benchmark.bm(13) do |bench|
  pid = fork do
    Dir.chdir(File.join(File.dirname(__FILE__), *%w[.. ext bert c])) { `make` }
    require 'bert'
    raise "Could not load C extension" unless BERT::Decode.impl == 'C'
    setup
    puts "BERT C Extension Decoder"
    bench.report("BERT tiny")    {ITER.times {BERT.decode($tiny_encoded_bert)}}
    bench.report("BERT small")   {ITER.times {BERT.decode($small_encoded_bert)}}
    bench.report("BERT large")   {ITER.times {BERT.decode($large_encoded_bert)}}
    bench.report("BERT complex") {ITER.times {BERT.decode($complex_encoded_bert)}}
    puts
  end
  Process.waitpid(pid)

  pid = fork do
    Dir.chdir(File.join(File.dirname(__FILE__), *%w[.. ext bert c])) do
      ['*.bundle', '*.o'].each { |pat| `rm -f #{pat}` }
    end
    require 'bert'
    raise "Not using Ruby decoder" unless BERT::Decode.impl == 'Ruby'
    setup
    puts "BERT Pure Ruby Decoder"
    bench.report("BERT tiny")    {ITER.times {BERT.decode($tiny_encoded_bert)}}
    bench.report("BERT small")   {ITER.times {BERT.decode($small_encoded_bert)}}
    bench.report("BERT large")   {ITER.times {BERT.decode($large_encoded_bert)}}
    bench.report("BERT complex") {ITER.times {BERT.decode($complex_encoded_bert)}}
    puts
  end
  Process.waitpid(pid)

  require 'bert'
  setup

  bench.report("JSON tiny")      {ITER.times {JSON.load($tiny_encoded_json)}}
  bench.report("JSON small")     {ITER.times {JSON.load($small_encoded_json)}}
  bench.report("JSON large")     {ITER.times {JSON.load($large_encoded_json)}}
  bench.report("JSON complex")   {ITER.times {JSON.load($complex_encoded_json)}}
  puts

  bench.report("YAJL tiny")      {ITER.times {Yajl::Parser.parse($tiny_encoded_yajl)}}
  bench.report("YAJL small")     {ITER.times {Yajl::Parser.parse($small_encoded_yajl)}}
  bench.report("YAJL large")     {ITER.times {Yajl::Parser.parse($large_encoded_yajl)}}
  bench.report("YAJL complex")   {ITER.times {Yajl::Parser.parse($complex_encoded_yajl)}}
  puts

  bench.report("Ruby tiny")      {ITER.times {Marshal.load($tiny_encoded_ruby)}}
  bench.report("Ruby small")     {ITER.times {Marshal.load($small_encoded_ruby)}}
  bench.report("Ruby large")     {ITER.times {Marshal.load($large_encoded_ruby)}}
  bench.report("Ruby complex")   {ITER.times {Marshal.load($complex_encoded_ruby)}}
end