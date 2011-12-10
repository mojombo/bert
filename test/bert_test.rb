require 'test_helper'

class BertTest < Test::Unit::TestCase
  context "BERT" do
    setup do
      time = Time.at(1254976067)
      @ruby = t[:user, {:name => 'TPW'}, [/cat/i, 9.9], time, nil, true, false, :true, :false]
      @bert = "\203h\td\000\004userh\003d\000\004bertd\000\004dictl\000\000\000\001h\002d\000\004namem\000\000\000\003TPWjl\000\000\000\002h\004d\000\004bertd\000\005regexm\000\000\000\003catl\000\000\000\001d\000\bcaselessjc9.900000000000000e+00\000\000\000\000\000\000\000\000\000\000jh\005d\000\004bertd\000\004timeb\000\000\004\346b\000\016\344\303a\000h\002d\000\004bertd\000\003nilh\002d\000\004bertd\000\004trueh\002d\000\004bertd\000\005falsed\000\004trued\000\005false"
      @ebin = "<<131,104,9,100,0,4,117,115,101,114,104,3,100,0,4,98,101,114,116,100,0,4,100,105,99,116,108,0,0,0,1,104,2,100,0,4,110,97,109,101,109,0,0,0,3,84,80,87,106,108,0,0,0,2,104,4,100,0,4,98,101,114,116,100,0,5,114,101,103,101,120,109,0,0,0,3,99,97,116,108,0,0,0,1,100,0,8,99,97,115,101,108,101,115,115,106,99,57,46,57,48,48,48,48,48,48,48,48,48,48,48,48,48,48,101,43,48,48,0,0,0,0,0,0,0,0,0,0,106,104,5,100,0,4,98,101,114,116,100,0,4,116,105,109,101,98,0,0,4,230,98,0,14,228,195,97,0,104,2,100,0,4,98,101,114,116,100,0,3,110,105,108,104,2,100,0,4,98,101,114,116,100,0,4,116,114,117,101,104,2,100,0,4,98,101,114,116,100,0,5,102,97,108,115,101,100,0,4,116,114,117,101,100,0,5,102,97,108,115,101>>"
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

    should "do roundtrips" do
      dd = []
      dd << 1
      dd << 1.0
      dd << :a
      dd << t[]
      dd << t[:a]
      dd << t[:a, :b]
      dd << t[t[:a, 1], t[:b, 2]]
      dd << []
      dd << [:a]
      dd << [:a, 1]
      dd << [[:a, 1], [:b, 2]]
      dd << "a"

      dd << nil
      dd << true
      dd << false
      dd << {}
      dd << {:a => 1}
      dd << {:a => 1, :b => 2}
      dd << Time.now
      dd << /^c(a)t$/i

      dd << 178
      dd << 256**256 - 1

      dd << :true
      dd << :false
      dd << :nil

      dd.each do |d|
        assert_equal d, BERT.decode(BERT.encode(d))
      end
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
