module BERT
  class Encode
    include Types

    class V2 < Encode
      def write_binary(data)
        enc = data.encoding
        case enc
        when ::Encoding::UTF_8, ::Encoding::US_ASCII
          write_unicode_string data
        when ::Encoding::ASCII_8BIT
          super
        else
          write_enc_string data
        end
      end

      private

      def write_unicode_string(data)
        write_1 UNICODE_STRING
        write_4 data.bytesize
        write_string data
      end

      def write_enc_string(data)
        write_1 ENC_STRING
        write_4 data.bytesize
        write_string data
        enc = data.encoding.name
        write_1 BIN
        write_4 enc.bytesize
        write_string enc
      end

      def version_header
        VERSION_2
      end
    end

    class << self
      attr_accessor :version
    end
    self.version = :v1

    attr_accessor :out

    def initialize(out)
      self.out = out
    end

    def self.encode(data)
      io = StringIO.new
      io.set_encoding('binary') if io.respond_to?(:set_encoding)

      if version == :v2
        Encode::V2.new(io).write_any(data)
      else
        new(io).write_any(data)
      end

      io.string
    end

    def write_any obj
      write_1 version_header
      write_any_raw obj
    end

    def write_any_raw obj
      case obj
        when Symbol then write_symbol(obj)
        when Fixnum, Bignum then write_fixnum(obj)
        when Float then write_float(obj)
        when Tuple then write_tuple(obj)
        when Array then write_list(obj)
        when String then write_binary(obj)
        else
          fail(obj)
      end
    end

    def write_1(byte)
      out.write([byte].pack("C"))
    end

    def write_2(short)
      out.write([short].pack("n"))
    end

    def write_4(long)
      out.write([long].pack("N"))
    end

    def write_string(string)
      out.write(string)
    end

    def write_boolean(bool)
      write_symbol(bool.to_s.to_sym)
    end

    def write_symbol(sym)
      fail(sym) unless sym.is_a?(Symbol)
      data = sym.to_s
      write_1 ATOM
      write_2 data.bytesize
      write_string data
    end

    def write_fixnum(num)
      if num >= 0 && num < 256
        write_1 SMALL_INT
        write_1 num
      elsif num <= MAX_INT && num >= MIN_INT
        write_1 INT
        write_4 num
      else
        write_bignum num
      end
    end

    def write_float(float)
      write_1 FLOAT
      write_string format("%15.15e", float).ljust(31, "\000")
    end

    def write_bignum(num)
      n = (num.abs.to_s(2).size / 8.0).ceil
      if n < 256
        write_1 SMALL_BIGNUM
        write_1 n
        write_bignum_guts(num)
      else
        write_1 LARGE_BIGNUM
        write_4 n
        write_bignum_guts(num)
      end
    end

    def write_bignum_guts(num)
      write_1 (num >= 0 ? 0 : 1)
      num = num.abs
      while num != 0
        rem = num % 256
        write_1 rem
        num = num >> 8
      end
    end

    def write_tuple(data)
      fail(data) unless data.is_a? Array

      if data.length < 256
        write_1 SMALL_TUPLE
        write_1 data.length
      else
        write_1 LARGE_TUPLE
        write_4 data.length
      end

      data.each { |e| write_any_raw e }
    end

    def write_list(data)
      fail(data) unless data.is_a? Array
      write_1 NIL and return if data.empty?
      write_1 LIST
      write_4 data.length
      data.each{|e| write_any_raw e }
      write_1 NIL
    end

    def write_binary(data)
      write_1 BIN
      write_4 data.bytesize
      write_string data
    end

    private

    def version_header
      MAGIC
    end

    def fail(obj)
      raise "Cannot encode to erlang external format: #{obj.inspect}"
    end
  end
end
