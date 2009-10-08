require 'test_helper'

class BertTest < Test::Unit::TestCase
  context "BERT" do
    should "encode" do
      before = [:user, {:name => 'TPW'}]
      after = "\203h\002d\000\004userh\002d\000\004dictl\000\000\000\002d\000\004namem\000\000\000\003TPWj"
      assert_equal after, BERT.encode(before)
    end

    should "decode" do
      before = "\203h\002d\000\004userh\002d\000\004dictl\000\000\000\002d\000\004namem\000\000\000\003TPWj"
      after = [:user, {:name => 'TPW'}]
      assert_equal after, BERT.decode(before)
    end

    should "ebin" do
      before = "\203h\002d\000\004userh\002d\000\004dictl\000\000\000\002d\000\004namem\000\000\000\003TPWj"
      after = "<<131,104,2,100,0,4,117,115,101,114,104,2,100,0,4,100,105,99,116,108,0,0,0,2,100,0,4,110,97,109,101,109,0,0,0,3,84,80,87,106>>"
      assert_equal after, BERT.ebin(before)
    end
  end
end
