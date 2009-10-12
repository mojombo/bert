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
        when TrueClass, FalseClass
          item.to_s.to_sym
        when Erl::List
          item.map { |x| convert(x) }
        when Array
          if item[0] == :bert
            convert_bert(item)
          else
            Tuple.new(item.map { |x| convert(x) })
          end
        else
          item
      end
    end

    # Convert complex types.
    #   +item+ is the complex type array
    #
    # Returns the converted Ruby object
    def self.convert_bert(item)
      case item[1]
        when :nil
          nil
        when :dict
          item[2].inject({}) do |acc, x|
            acc[convert(x[0])] = convert(x[1]); acc
          end
        when TrueClass
          true
        when FalseClass
          false
        when :time
          Time.at(item[2] * 1_000_000 + item[3], item[4])
        when :regex
          options = 0
          options |= Regexp::EXTENDED if item[3].include?(:extended)
          options |= Regexp::IGNORECASE if item[3].include?(:caseless)
          options |= Regexp::MULTILINE if item[3].include?(:multiline)
          Regexp.new(item[2], options)
        else
          nil
      end
    end
  end
end