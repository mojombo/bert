require 'test_helper'

class DecoderTest < Test::Unit::TestCase
  BERT_NIL = [131,104,2,100,0,4,98,101,114,116,100,0,3,110,105,108].pack('c*')
  BERT_TRUE = [131,104,2,100,0,4,98,101,114,116,100,0,4,116,114,117,101].pack('c*')
  BERT_FALSE = [131,104,2,100,0,4,98,101,114,116,100,0,5,102,97,108,115,101].pack('c*')

  context "BERT Decoder complex type converter" do
    should "convert nil" do
      assert_equal nil, BERT::Decoder.decode(BERT_NIL)
    end

    should "convert nested nil" do
      bert = [131,108,0,0,0,2,104,2,100,0,4,98,101,114,116,100,0,3,110,105,
              108,108,0,0,0,1,104,2,100,0,4,98,101,114,116,100,0,3,110,105,
              108,106,106].pack('c*')
      assert_equal [nil, [nil]], BERT::Decoder.decode(bert)
    end

    should "convert hashes" do
      bert = [131,104,3,100,0,4,98,101,114,116,100,0,4,100,105,99,116,108,
              0,0,0,1,104,2,100,0,3,102,111,111,109,0,0,0,3,98,97,114,
              106].pack('c*')
      after = {:foo => 'bar'}
      assert_equal after, BERT::Decoder.decode(bert)
    end

    should "convert empty hashes" do
      bert = [131,104,3,100,0,4,98,101,114,116,100,0,4,100,105,99,116,
              106].pack('c*')
      after = {}
      assert_equal after, BERT::Decoder.decode(bert)
    end

    should "convert nested hashes" do
      bert = [131,104,3,100,0,4,98,101,114,116,100,0,4,100,105,99,116,108,0,
              0,0,1,104,2,100,0,3,102,111,111,104,3,100,0,4,98,101,114,116,
              100,0,4,100,105,99,116,108,0,0,0,1,104,2,100,0,3,98,97,122,109,
              0,0,0,3,98,97,114,106,106].pack('c*')
      after = {:foo => {:baz => 'bar'}}
      assert_equal after, BERT::Decoder.decode(bert)
    end

    should "convert true" do
      assert_equal true, BERT::Decoder.decode(BERT_TRUE)
    end

    should "convert false" do
      assert_equal false, BERT::Decoder.decode(BERT_FALSE)
    end

    should "convert times" do
      bert = [131,104,5,100,0,4,98,101,114,116,100,0,4,116,105,109,101,98,0,
              0,4,230,98,0,14,228,195,97,0].pack('c*')
      after = Time.at(1254976067)
      assert_equal after, BERT::Decoder.decode(bert)
    end

    should "convert regexen" do
      bert = [131,104,4,100,0,4,98,101,114,116,100,0,5,114,101,103,101,120,
              109,0,0,0,7,94,99,40,97,41,116,36,108,0,0,0,2,100,0,8,99,97,
              115,101,108,101,115,115,100,0,8,101,120,116,101,110,100,101,
              100,106].pack('c*')
      after = /^c(a)t$/ix
      assert_equal after, BERT::Decoder.decode(bert)
    end

    should "leave other stuff alone" do
      bert = [131,108,0,0,0,3,97,1,99,50,46,48,48,48,48,48,48,48,48,48,48,48,
              48,48,48,48,48,48,48,48,48,101,43,48,48,0,0,0,0,0,108,0,0,0,2,
              100,0,3,102,111,111,109,0,0,0,3,98,97,114,106,106].pack('c*')
      after = [1, 2.0, [:foo, 'bar']]
      assert_equal after, BERT::Decoder.decode(bert)
    end

    should "handle bignums" do
      bert = [131,110,8,0,0,0,232,137,4,35,199,138].pack('c*')
      assert_equal 10_000_000_000_000_000_000, BERT::Decoder.decode(bert)
    end

    should "handle bytelists" do
      bert = [131,104,3,100,0,3,102,111,111,107,0,2,97,97,100,0,3,98,97,114].pack('c*')
      assert_equal t[:foo, [97, 97], :bar], BERT::Decoder.decode(bert)
    end

    should "handle massive binaries" do
      bert = [131,109,0,128,0,0].pack('c*') + ('a' * (8 * 1024 * 1024))
      assert_equal (8 * 1024 * 1024), BERT::Decoder.decode(bert).size
    end
  end
end
