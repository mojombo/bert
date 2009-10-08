require 'test_helper'

class BertTest < Test::Unit::TestCase
  context "BERT" do
    should "encode" do
      before = [:user, {:name => 'TPW', :nick => 'mojombo'}]
      after = "\203h\002d\000\004userh\003d\000\004dicth\002d\000\004namem\000\000\000\003TPWh\002d\000\004nickm\000\000\000\amojombo"
      assert_equal after, BERT.encode(before)
    end

    should "decode" do
      before = "\203h\002d\000\004userh\003d\000\004dicth\002d\000\004namem\000\000\000\003TPWh\002d\000\004nickm\000\000\000\amojombo"
      after = [:user, {:name => 'TPW', :nick => 'mojombo'}]
      assert_equal after, BERT.decode(before)
    end
  end
end
