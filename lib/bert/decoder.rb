module BERT
  class Decoder
    # Decode a BERT into a Ruby object.
    #   +bert+ is the BERT String
    #
    # Returns a Ruby object
    def self.decode(bert)
      simple_ruby = Erlectricity::Decoder.decode(bert)
      convert(simple_ruby)
    end

    # Convert Erlectricity representation of BERT complex types into
    # corresponding Ruby types.
    #   +item+ is the Ruby object to convert
    #
    # Returns the converted Ruby object
    def self.convert(item)
      case item
        when [:nil, :nil]
          nil
        when Array
          if item.first == :dict
            item[1..-1].inject({}) do |acc, x|
              acc[convert(x[0])] = convert(x[1]); acc
            end
          else
            item.map { |x| convert(x) }
          end
        else
          item
      end
    end
  end
end