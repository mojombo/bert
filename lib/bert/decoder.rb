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
              if item[1]
                item[1].inject({}) do |acc, x|
                  acc[convert(x[0])] = convert(x[1]); acc
                end
              else
                {}
              end
            when :bool
              item[1]
            when :time
              Time.at(item[1].to_i, item[2].to_i)
            when :regex
              options = 0
              options |= Regexp::EXTENDED if item[2] =~ /x/
              options |= Regexp::IGNORECASE if item[2] =~ /i/
              options |= Regexp::MULTILINE if item[2] =~ /m/
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