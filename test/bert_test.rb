require 'test_helper'

class BertTest < Test::Unit::TestCase
  context "BERT" do
    setup do
      time = Time.at(1254976067)
      @ruby = t[:user, {:name => 'TPW'}, [/cat/i, 9.9], nil, true, false, :true, :false]
      @bert = "\203h\bd\000\004userh\002d\000\004dictl\000\000\000\001h\002d\000\004namem\000\000\000\003TPWjl\000\000\000\002h\003d\000\005regexm\000\000\000\003catm\000\000\000\001ic9.900000000000000e+00\000\000\000\000\000\000\000\000\000\000jh\002d\000\003nild\000\003nilh\002d\000\004boold\000\004trueh\002d\000\004boold\000\005falsed\000\004trued\000\005false"
      @ebin = "<<131,104,8,100,0,4,117,115,101,114,104,2,100,0,4,100,105,99,116,108,0,0,0,1,104,2,100,0,4,110,97,109,101,109,0,0,0,3,84,80,87,106,108,0,0,0,2,104,3,100,0,5,114,101,103,101,120,109,0,0,0,3,99,97,116,109,0,0,0,1,105,99,57,46,57,48,48,48,48,48,48,48,48,48,48,48,48,48,48,101,43,48,48,0,0,0,0,0,0,0,0,0,0,106,104,2,100,0,3,110,105,108,100,0,3,110,105,108,104,2,100,0,4,98,111,111,108,100,0,4,116,114,117,101,104,2,100,0,4,98,111,111,108,100,0,5,102,97,108,115,101,100,0,4,116,114,117,101,100,0,5,102,97,108,115,101>>"
    end

    should "encode" do
      assert_equal @bert, BERT.encode(@ruby)
    end

    should "decode" do
      assert_equal @ruby, BERT.decode(@bert)
    end

    should "ebin" do
      assert_equal @ebin, BERT.ebin(@bert)
    end

    # should "let me inspect it" do
    #   puts
    #   p @ruby
    #   ruby2 = BERT.decode(@bert)
    #   p ruby2
    #   bert2 = BERT.encode(ruby2)
    #   ruby3 = BERT.decode(bert2)
    #   p ruby3
    # end
  end
end
