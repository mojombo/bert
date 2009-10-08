require 'rubygems'
require 'erlectricity'

require 'bert/encoder'
require 'bert/decoder'

module BERT
  def self.encode(ruby)
    Encoder.encode(ruby)
  end

  def self.decode(bert)
    Decoder.decode(bert)
  end

  def self.ebin(str)
    bytes = []
    str.each_byte { |b| bytes << b.to_s }
    "<<" + bytes.join(',') + ">>"
  end
end

module BERT
  class Tuple < Array
    def inspect
      "t#{super}"
    end
  end
end

def t
  BERT::Tuple
end