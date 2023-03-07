class BMP
  abstract class Decoder
    def initialize(@bmp : BMP)
    end

    def self.build(bmp : BMP)
      case {bmp.header.bit_per_pixel, bmp.header.as?(InfoHeader).try &.compression}
      when {BitPerPixel::MONOCHROME, _}                 then Bpp1Decoder.new bmp
      when {BitPerPixel::DEPTH_4, _}                    then Bpp4Decoder.new bmp
      when {BitPerPixel::DEPTH_8, _}                    then Bpp8Decoder.new bmp
      when {BitPerPixel::DEPTH_16, Compression::BI_RGB} then Bpp16BIRGBDecoder.new bmp
      when {BitPerPixel::DEPTH_24, Compression::BI_RGB} then Bpp24BIRGBDecoder.new bmp
      else
        raise "Unsupported BPP/Compression: #{bmp.header.bit_per_pixel}/#{bmp.header.as?(InfoHeader).try &.compression}'}"
      end
    end

    def offset(x, y)
      (((@bmp.width * @bmp.@header.bit_per_pixel.value + @bmp.padding) // 8) * (@bmp.height - y - 1)) + (@bmp.@header.bit_per_pixel.value * x // 8)
    end

    # Return an abstract representation of the pixel data
    abstract def data(x, y) : Bytes

    # Set abstract representation of the pixel data
    abstract def data(x, y, d : Bytes)

    # Return the pixel color
    abstract def color(x, y) : Color

    # Set the pixel color
    def color(x, y, color : Int32)
      raise "Bad color table index for no color table bmp"
    end

    def color(x, y, color : Color)
      raise "Bad color  for color table bmp"
    end
  end

  @decoder : Decoder?

  def decoder
    @decoder ||= Decoder.build self
  end

  class Bpp1Decoder < Decoder
    DATA_0 = Bytes.new 1, 0u8
    DATA_1 = Bytes.new 1, 0u8
    DATA   = [DATA_0, DATA_1]

    def data(x, y) : Bytes
      DATA[(@bmp.@pixel_data[offset x, y] >> (7 - @bmp.width % 8)) & 1]
    end

    def data(x, y, d : Bytes)
      @bmp.@pixel_data[offset x, y] = @bmp.@pixel_data[offset x, y] & ~(1 << (x % 8)) | (d[0] << (x % 8))
    end
      
    def color(x, y) : Color
      @bmp.@color_table[(@bmp.@pixel_data[offset x, y] >> (7 - @bmp.width % 8)) & 1]
    end

    def color(x, y, color : Int32)
      @bmp.@pixel_data[offset x, y] = @bmp.@pixel_data[offset x, y] & ~(1 << (x % 8)) | color << (x % 8)
    end
  end

  class Bpp4Decoder < Decoder
    DATA = {{(0...16).map { |i| "Bytes[#{i}u8]".id }}}

    def data(x, y) : Bytes
      DATA[(@bmp.@pixel_data[offset x, y] >> (x.even? ? 4 : 0)) & 0xf]
    end

    def data(x, y, d : Bytes)
      if x.even?
        @bmp.@pixel_data[offset x, y] = @bmp.@pixel_data[offset x, y] & 0b00001111 | (d[0] << 4)
      else
        @bmp.@pixel_data[offset x, y] = @bmp.@pixel_data[offset x, y] & 0b11110000 | d[0]
      end
    end

    def color(x, y) : Color
      @bmp.@color_table[(@bmp.@pixel_data[offset x, y] >> (x.even? ? 4 : 0)) & 0xf]
    end

    def color(x, y, color : Int32)
      if x.even?
        @bmp.@pixel_data[offset x, y] = @bmp.@pixel_data[offset x, y] & 0b00001111 | ((color & 0xf) << 4)
      else
        @bmp.@pixel_data[offset x, y] = @bmp.@pixel_data[offset x, y] & 0b11110000 | (color & 0xf)
      end
    end
  end

  class Bpp8Decoder < Decoder
    def data(x, y) : Bytes
      @bmp.@pixel_data[start: offset(x, y), count: 1]
    end

    def data(x, y, d : Bytes)
      @bmp.@pixel_data[offset x, y] = d[0]
    end

    def color(x, y) : Color
      @bmp.@color_table[@bmp.@pixel_data[offset x, y]]
    end

    def color(x, y, color : Int32)
      @bmp.@pixel_data[offset x, y] = color
    end
  end

  class Bpp16BIRGBDecoder < Decoder
    def data(x, y) : Bytes
      @bmp.@pixel_data[start: offset(x, y), count: 2]
    end

    def data(x, y, d : Bytes)
      @bmp.@pixel_data[offset x, y] = d[0]
      @bmp.@pixel_data[1 + offset x, y] = d[1]
    end

    def color(x, y) : Color
      data = IO::ByteFormat::LittleEndian.decode UInt16, @bmp.@pixel_data + offset x, y
      Color.new(
        blue: (data & 0b11111).to_u8,
        green: ((data & 0b1111100000) >> 5).to_u8,
        red: ((data & 0b111110000000000) >> 10).to_u8,
      )
    end

    def color(x, y, color : Color)
      @bmp.@pixel_data[offset x, y] = (color.blue & 0b11111) | ((color.green & 0b11) << 5)
      @bmp.@pixel_data[1 + offset x, y] = ((color.green & 0b11100) >> 2) | ((color.red & 0b11111) << 3)
    end
  end

  class Bpp24BIRGBDecoder < Decoder
    def data(x, y) : Bytes
      @bmp.@pixel_data[start: offset(x, y), count: 3]
    end

    def data(x, y, d : Bytes)
      @bmp.@pixel_data[offset x, y] = d[0]
      @bmp.@pixel_data[1 + offset x, y] = d[1]
      @bmp.@pixel_data[2 + offset x, y] = d[2]
    end

    def color(x, y) : Color
      o = offset x, y
      Color.new(
        blue: @bmp.@pixel_data[o],
        green: @bmp.@pixel_data[o + 1],
        red: @bmp.@pixel_data[o + 2],
      )
    end

    def color(x, y, color : Color)
      @bmp.@pixel_data[offset x, y] = color.red
      @bmp.@pixel_data[1 + offset x, y] = color.green
      @bmp.@pixel_data[2 + offset x, y] = color.blue
    end
  end

  def color(x, y) : Color
    decoder.color x, y
  end

  def color(x, y, color)
    decoder.color x, y, color
  end

  def data(x, y) : Bytes
    decoder.data x, y
  end

  def data(x, y, d : Bytes)
    decoder.data x, y, d
  end
end
