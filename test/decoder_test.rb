require 'test_helper'

class DecoderTest < Test::Unit::TestCase
  context "BERT Decoder complex type converter" do
    should "convert nil" do
      before = [:bert, :nil]
      after = nil
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert nested nil" do
      before = [[:bert, :nil], [[:bert, :nil]]]
      after = [nil, [nil]]
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert hashes" do
      before = [:bert, :dict, [[:foo, 'bar']]]
      after = {:foo => 'bar'}
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert empty hashes" do
      before = [:bert, :dict, []]
      after = {}
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert nested hashes" do
      before = [:bert, :dict, [[:foo, [:bert, :dict, [[:baz, 'bar']]]]]]
      after = {:foo => {:baz => 'bar'}}
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert true" do
      before = [:bert, :bool, true]
      after = true
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert false" do
      before = [:bert, :bool, false]
      after = false
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert times" do
      before = [:bert, :time, 1254, 976067, 0]
      after = Time.at(1254976067)
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert regexen" do
      before = [:bert, :regex, '^c(a)t$', [:caseless, :extended]]
      after = /^c(a)t$/ix
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "leave other stuff alone" do
      before = [1, 2.0, [:foo, 'bar']]
      assert_equal before, BERT::Decoder.convert(before)
    end
  end
end
