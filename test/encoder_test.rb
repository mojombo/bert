# encoding: utf-8

require 'test_helper'

class EncoderTest < Test::Unit::TestCase
  context "BERT Encoder complex type converter" do
    should "convert nil" do
      assert_equal [:bert, :nil], BERT::Encoder.convert(nil)
    end

    should "convert nested nil" do
      before = [nil, [nil]]
      after = [[:bert, :nil], [[:bert, :nil]]]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "convert hashes" do
      before = {:foo => 'bar'}
      after = [:bert, :dict, [[:foo, 'bar']]]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "convert nested hashes" do
      before = {:foo => {:baz => 'bar'}}
      after = [:bert, :dict, [[:foo, [:bert, :dict, [[:baz, "bar"]]]]]]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "convert hash to tuple with array of tuples" do
      arr = BERT::Encoder.convert({:foo => 'bar'})
      assert arr.is_a?(Array)
      assert arr[2].is_a?(Array)
      assert arr[2][0].is_a?(Array)
    end

    should "convert tuple to array" do
      arr = BERT::Encoder.convert(t[:foo, 2])
      assert arr.is_a?(Array)
    end

    should "convert array to erl list" do
      list = BERT::Encoder.convert([1, 2])
      assert list.is_a?(Array)
    end

    should "convert an array in a tuple" do
      arrtup = BERT::Encoder.convert(t[:foo, [1, 2]])
      assert arrtup.is_a?(Array)
      assert arrtup[1].is_a?(Array)
    end

    should "convert true" do
      before = true
      after = [:bert, :true]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "convert false" do
      before = false
      after = [:bert, :false]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "convert times" do
      before = Time.at(1254976067)
      after = [:bert, :time, 1254, 976067, 0]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "convert regexen" do
      before = /^c(a)t$/ix
      after = [:bert, :regex, '^c(a)t$', [:caseless, :extended]]
      assert_equal after, BERT::Encoder.convert(before)
    end

    should "properly convert types" do
      ruby = t[:user, {:name => 'TPW'}, [/cat/i, 9.9], nil, true, false, :true, :false]
      cruby = BERT::Encoder.convert(ruby)
      assert cruby.instance_of?(BERT::Tuple)
      assert cruby[0].instance_of?(Symbol)
      assert cruby[1].instance_of?(BERT::Tuple)
    end

    should 'handle utf8 strings' do
      str = "été".encode 'UTF-8'
      bert = [131, 109, 0, 0, 0, 5, 195, 169, 116, 195, 169].pack('C*')
      assert_equal bert, BERT::Encoder.encode("été")
    end

    should 'handle utf8 symbols' do
      bert = [131, 100, 0, 5, 195, 169, 116, 195, 169].pack('C*')
      assert_equal bert, BERT::Encoder.encode(:'été')
    end

    should "handle bignums" do
      bert = [131,110,8,0,0,0,232,137,4,35,199,138].pack('c*')
      assert_equal bert, BERT::Encoder.encode(10_000_000_000_000_000_000)

      bert = [131,110,8,1,0,0,232,137,4,35,199,138].pack('c*')
      assert_equal bert, BERT::Encoder.encode(-10_000_000_000_000_000_000)
    end

    context "v2" do
      setup do
        @old_version = BERT::Encode.version
        BERT::Encode.version = :v2
      end

      teardown do
        BERT::Encode.version = @old_version
      end

      should 'handle utf8 strings' do
        str = "été".encode 'UTF-8'
        bert = [132, 113, 0, 0, 0, 5, 195, 169, 116, 195, 169].pack('C*')
        assert_equal bert, BERT::Encoder.encode("été")
      end

      should 'handle utf8 symbols' do
        bert = [132, 100, 0, 5, 195, 169, 116, 195, 169].pack('C*')
        assert_equal bert, BERT::Encoder.encode(:'été')
      end

      should "handle bignums" do
        bert = [132,110,8,0,0,0,232,137,4,35,199,138].pack('c*')
        assert_equal bert, BERT::Encoder.encode(10_000_000_000_000_000_000)

        bert = [132,110,8,1,0,0,232,137,4,35,199,138].pack('c*')
        assert_equal bert, BERT::Encoder.encode(-10_000_000_000_000_000_000)
      end
    end

    should "leave other stuff alone" do
      before = [1, 2.0, [:foo, 'bar']]
      assert_equal before, BERT::Encoder.convert(before)
    end
  end
end
