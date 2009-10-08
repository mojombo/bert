require 'test_helper'

class EncoderTest < Test::Unit::TestCase
  context "BERT Encoder complex type converter" do
    should "convert nil" do
      assert_equal [:nil, :nil], BERT::Encoder.convert(nil)
    end

    should "convert nested nil" do
      before = [nil, [nil]]
      after = [[:nil, :nil], [[:nil, :nil]]]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "convert hashes" do
      before = {:foo => 'bar'}
      after = [:dict, [:foo, 'bar']]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "convert nested hashes" do
      before = {:foo => {:baz => 'bar'}}
      after = [:dict, [:foo, [:dict, [:baz, 'bar']]]]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "convert true" do
      before = true
      after = [:bool, :true]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "convert false" do
      before = false
      after = [:bool, :false]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "leave other stuff alone" do
      before = [1, 2.0, [:foo, 'bar']]
      assert_equal before, BERT::Encoder.convert(before)
    end
  end
end
