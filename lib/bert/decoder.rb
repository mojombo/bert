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
        when [:nil, :nil]
          nil
        when Erl::List
          item.map { |x| convert(x) }
        when Array
          case item.first
            when :dict
              item[1].inject({}) do |acc, x|
                acc[convert(x[0])] = convert(x[1]); acc
              end
            when :bool
              item[1]
            when :time
              Time.at(item[1] * 1_000_000 + item[2], item[3])
            when :regex
              options = 0
              options |= Regexp::EXTENDED if item[2].include?(:extended)
              options |= Regexp::IGNORECASE if item[2].include?(:caseless)
              options |= Regexp::MULTILINE if item[2].include?(:multiline)
              Regexp.new(item[1], options)
            else
              Tuple.new(item.map { |x| convert(x) })
          end
        else
          item
      end
    end
  end
end