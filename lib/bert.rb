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
end