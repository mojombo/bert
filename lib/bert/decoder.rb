module BERT
  class Decoder
    # Decode a BERT into a Ruby object.
    #   +bert+ is the BERT String
    #
    # Returns a Ruby object
    def self.decode(bert)
      simple_ruby = Decode.decode(bert)
      convert(simple_ruby)
    end

    # Convert simple Ruby form into complex Ruby form.
    #   +item+ is the Ruby object to convert
    #
    # Returns the converted Ruby object
    def self.convert(item)
      if item.instance_of?(Array)
        item.map { |x| convert(x) }
      else
        item
      end
    end
  end
end