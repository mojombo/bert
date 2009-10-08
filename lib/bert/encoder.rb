module BERT
  class Encoder
    # Encode a Ruby object into a BERT.
    #   +ruby+ is the Ruby object
    #
    # Returns a BERT
    def self.encode(ruby)
      complex_ruby = convert(ruby)
      Erlectricity::Encoder.encode(complex_ruby)
    end

    # Convert Ruby types into corresponding Erlectricity representation
    # of BERT complex types.
    #   +item+ is the Ruby object to convert
    #
    # Returns the converted Ruby object
    def self.convert(item)
      case item
        when Hash
          a = [:dict]
          item.each_pair { |k, v| a << [convert(k), convert(v)] }
          a
        when Array
          item.map { |x| convert(x) }
        when nil
          [:nil, :nil]
        when TrueClass, FalseClass
          [:bool, item.to_s.to_sym]
        when Time
          [:time, item.to_i, item.usec]
        else
          item
      end
    end
  end
end