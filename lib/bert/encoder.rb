module BERT
  class Encoder
    # Encode a Ruby object into a BERT.
    #   +ruby+ is the Ruby object
    #
    # Returns a BERT
    def self.encode(ruby)
      complex_ruby = convert(ruby)
      Encode.encode(complex_ruby)
    end

    # Convert complex Ruby form in simple Ruby form.
    #   +item+ is the Ruby object to convert
    #
    # Returns the converted Ruby object
    def self.convert(item)
      case item
        when Hash
          pairs = List[]
          item.each_pair { |k, v| pairs << [convert(k), convert(v)] }
          [:bert, :dict, pairs]
        when Tuple
          item.map { |x| convert(x) }
        when Array
          List.new(item.map { |x| convert(x) })
        when nil
          [:bert, :nil]
        when TrueClass
          [:bert, :true]
        when FalseClass
          [:bert, :false]
        when Time
          [:bert, :time, item.to_i / 1_000_000, item.to_i % 1_000_000, item.usec]
        when Regexp
          options = List[]
          options << :caseless if item.options & Regexp::IGNORECASE > 0
          options << :extended if item.options & Regexp::EXTENDED > 0
          options << :multiline if item.options & Regexp::MULTILINE > 0
          [:bert, :regex, item.source, options]
        else
          item
      end
    end
  end
end