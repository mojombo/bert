require 'test_helper'

class DecoderTest < Test::Unit::TestCase
  context "BERT Decoder complex type converter" do
    should "convert nil" do
      before = [:nil, :nil]
      after = nil
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert nested nil" do
      before = [[:nil, :nil], [[:nil, :nil]]]
      after = [nil, [nil]]
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert hashes" do
      before = [:dict, [:foo, 'bar']]
      after = {:foo => 'bar'}
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert nested hashes" do
      before = [:dict, [:foo, [:dict, [:baz, 'bar']]]]
      after = {:foo => {:baz => 'bar'}}
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert true" do
      before = [:bool, :true]
      after = true
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "convert false" do
      before = [:bool, :false]
      after = false
      assert_equal after, BERT::Decoder.convert(before)
    end

    should "leave other stuff alone" do
      before = [1, 2.0, [:foo, 'bar']]
      assert_equal before, BERT::Decoder.convert(before)
    end
  end
end
