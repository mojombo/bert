require 'test_helper'

class BertTest < Test::Unit::TestCase
  context "BERT" do
    should "encode" do
      before = [:user, {:name => 'TPW'}]
      after = "\203h\002d\000\004userh\002d\000\004dicth\002d\000\004namem\000\000\000\003TPW"
      assert_equal after, BERT.encode(before)
    end

    should "decode" do
      before = "\203h\002d\000\004userh\002d\000\004dicth\002d\000\004namem\000\000\000\003TPW"
      after = [:user, {:name => 'TPW'}]
      assert_equal after, BERT.decode(before)
    end

    should "ebin" do
      before = "\203h\002d\000\004userh\003d\000\004dicth\002d\000\004namem\000\000\000\003TPWh\002d\000\004nickm\000\000\000\amojombo"
      after = "<<131,104,2,100,0,4,117,115,101,114,104,3,100,0,4,100,105,99,116,104,2,100,0,4,110,97,109,101,109,0,0,0,3,84,80,87,104,2,100,0,4,110,105,99,107,109,0,0,0,7,109,111,106,111,109,98,111>>"
      assert_equal after, BERT.ebin(before)
    end
  end
end
