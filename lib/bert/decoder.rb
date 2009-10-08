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
          case item.first
            when :dict
              item[1..-1].inject({}) do |acc, x|
                acc[convert(x[0])] = convert(x[1]); acc
              end
            when :bool
              item[1] == :true
            when :time
              Time.at(item[1].to_i, item[2].to_i)
            else
              item.map { |x| convert(x) }
          end
        else
          item
      end
    end
  end
end