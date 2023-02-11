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

    abstract def get(x, y) : Color
  end

  @decoder : Decoder?

  def decoder
    @decoder ||= Decoder.build self
  end

  class Bpp1Decoder < Decoder
    def get(x, y) : Color
      @bmp.@color_table[(@bmp.@pixel_data[offset x, y] >> (7 - @bmp.width % 8)) & 1]
    end
  end

  class Bpp4Decoder < Decoder
    def get(x, y) : Color
      @bmp.@color_table[(@bmp.@pixel_data[offset x, y] >> (x.even? ? 4 : 0)) & 0xf]
    end
  end

  class Bpp8Decoder < Decoder
    def get(x, y) : Color
      @bmp.@color_table[@bmp.@pixel_data[offset x, y]]
    end
  end

  class Bpp16BIRGBDecoder < Decoder
    def get(x, y) : Color
      data = IO::ByteFormat::LittleEndian.decode UInt16, @bmp.@pixel_data + offset x, y
      Color.new(
        blue: (data & 0b11111).to_u8,
        green: ((data & 0b1111100000) >> 5).to_u8,
        red: ((data & 0b111110000000000) >> 10).to_u8,
      )
    end
  end

  class Bpp24BIRGBDecoder < Decoder
    def get(x, y) : Color
      Color.new IO::ByteFormat::LittleEndian.decode UInt32, @bmp.@pixel_data + offset x, y
    end
  end

  def color_at(x, y)
    decoder.get x, y
  end
end
