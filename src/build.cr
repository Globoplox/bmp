# Create BMP file.
class BMP
  class InfoHeader < Header
    def initialize(@width, @height, @bit_per_pixel)
      @planes = 1
      @compression = Compression::BI_RGB
      @image_size = 0
      @x_pixel_per_m = 3780
      @y_pixel_per_m = 3780
      case @bit_per_pixel
      when BitPerPixel::MONOCHROME then @colors_used = 2
      when BitPerPixel::DEPTH_4    then @colors_used = 16
      when BitPerPixel::DEPTH_8    then @colors_used = 256
      else                              @colors_used = 0
      end
      @important_colors = @colors_used
    end
  end

  def initialize(width : UInt32, height : UInt32, bit_per_pixel : BMP::BitPerPixel)
    @signature = SIGNATURE
    @reserved = 0u32

    header = InfoHeader.new width, height, bit_per_pixel
    @header = header
    @header_type = HeaderType::INFO_HEADER
    @padding = nil

    @color_table = Array(Color).new header.colors_used do
      Color.new 0, 0, 0
    end
    scan_line_size_byte = (width * @header.bit_per_pixel.value + padding) // 8
    header.image_size = scan_line_size_byte * height
    @pixel_data = Bytes.new(scan_line_size_byte * height)

    @data_offset = 54u32 + @color_table.size * 4
    @file_size = @data_offset + @pixel_data.size
  end
end
