
require 'stringio'

$:.unshift File.join(File.dirname(__FILE__), *%w[.. ext])

require 'bert/bert'
require 'bert/types'

begin
  # try to load the C extension
  require 'bert/c/decode'
rescue LoadError
  # fall back on the pure ruby version
  require 'bert/decode'
end

require 'bert/encode'

require 'bert/encoder'
require 'bert/decoder'

# Global method for specifying that an array should be encoded as a tuple.
def t
  BERT::Tuple
end
