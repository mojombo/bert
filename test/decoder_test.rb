require 'test_helper'

class DecoderTest < Test::Unit::TestCase
  context "BERT Decoder complex type converter" do
    # should "convert nil" do
    #   before = t[:bert, :nil]
    #   after = nil
    #   assert_equal after, BERT::Decoder.convert(before)
    # end
    # 
    # should "convert nested nil" do
    #   before = [t[:bert, :nil], [t[:bert, :nil]]]
    #   after = [nil, [nil]]
    #   assert_equal after, BERT::Decoder.convert(before)
    # end
    # 
    # should "convert hashes" do
    #   before = t[:bert, :dict, [[:foo, 'bar']]]
    #   after = {:foo => 'bar'}
    #   assert_equal after, BERT::Decoder.convert(before)
    # end
    # 
    # should "convert empty hashes" do
    #   before = t[:bert, :dict, []]
    #   after = {}
    #   assert_equal after, BERT::Decoder.convert(before)
    # end
    # 
    # should "convert nested hashes" do
    #   before = t[:bert, :dict, [[:foo, t[:bert, :dict, [[:baz, 'bar']]]]]]
    #   after = {:foo => {:baz => 'bar'}}
    #   assert_equal after, BERT::Decoder.convert(before)
    # end

    should "convert true" do
      # {bert, true}
      bert = [131,104,2,100,0,4,98,101,114,116,100,0,4,116,114,117,101].pack('c*')
      assert_equal true, BERT::Decoder.decode(bert)
    end

    # should "convert false" do
    #   before = t[:bert, :false]
    #   after = false
    #   assert_equal after, BERT::Decoder.convert(before)
    # end
    # 
    # should "convert times" do
    #   before = t[:bert, :time, 1254, 976067, 0]
    #   after = Time.at(1254976067)
    #   assert_equal after, BERT::Decoder.convert(before)
    # end
    # 
    # should "convert regexen" do
    #   before = t[:bert, :regex, '^c(a)t$', [:caseless, :extended]]
    #   after = /^c(a)t$/ix
    #   assert_equal after, BERT::Decoder.convert(before)
    # end
    # 
    # should "leave other stuff alone" do
    #   before = [1, 2.0, [:foo, 'bar']]
    #   assert_equal before, BERT::Decoder.convert(before)
    # end
  end
end
