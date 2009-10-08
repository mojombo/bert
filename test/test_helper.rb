require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'bert'

class Test::Unit::TestCase
end

# So I can easily see which arrays are Erl::List
module Erl
  class List
    def inspect
      "l#{super}"
    end
  end
end