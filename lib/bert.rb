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

def l
  Erl::List
end