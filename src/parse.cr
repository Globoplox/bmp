# TODO: handle signed width/height for moving origin/pixel order
class BMP
  UNSUPPORTED_COMPRESSION = [
    Compression::BI_BITFIELDS, Compression::BI_ALPHABITFIELDS,
    Compression::BI_RLE4, Compression::BI_RLE8,
    Compression::BI_JPEG, Compression::BI_PNG,
    Compression::BI_CMYK, Compression::BI_CMYKRLE8, Compression::BI_CMYKRLE4,
  ]

  class CoreHeader < Header
    def initialize(io : IO)
      @width = io.read_bytes typeof(@width), IO::ByteFormat::LittleEndian
      @height = io.read_bytes typeof(@height), IO::ByteFormat::LittleEndian
      @planes = io.read_bytes typeof(@planes), IO::ByteFormat::LittleEndian
      @bit_per_pixel = BitPerPixel.from_value io.read_bytes Int16, IO::ByteFormat::LittleEndian

      unless @bit_per_pixel.in? [BitPerPixel::DEPTH_16, BitPerPixel::DEPTH_24]
        raise "Invalid bit per pixel value #{@bit_per_pixel} for core header bitmap without support for color tables"
      end
    end
  end

  class InfoHeader < Header
    def initialize(io : IO)
      @width = io.read_bytes typeof(@width), IO::ByteFormat::LittleEndian
      @height = io.read_bytes typeof(@height), IO::ByteFormat::LittleEndian
      @planes = io.read_bytes typeof(@planes), IO::ByteFormat::LittleEndian
      @bit_per_pixel = BitPerPixel.from_value io.read_bytes Int16, IO::ByteFormat::LittleEndian
      @compression = Compression.from_value io.read_bytes Int32, IO::ByteFormat::LittleEndian
      raise "Compression mode #{@compression} is not supported" if @compression.in? UNSUPPORTED_COMPRESSION
      @image_size = io.read_bytes typeof(@image_size), IO::ByteFormat::LittleEndian
      @x_pixel_per_m = io.read_bytes typeof(@x_pixel_per_m), IO::ByteFormat::LittleEndian
      @y_pixel_per_m = io.read_bytes typeof(@y_pixel_per_m), IO::ByteFormat::LittleEndian
      @colors_used = io.read_bytes typeof(@colors_used), IO::ByteFormat::LittleEndian
      @important_colors = io.read_bytes typeof(@important_colors), IO::ByteFormat::LittleEndian

      if @colors_used == 0
        case @bit_per_pixel
        when BitPerPixel::MONOCHROME then @colors_used = 2
        when BitPerPixel::DEPTH_4    then @colors_used = 16
        when BitPerPixel::DEPTH_8    then @colors_used = 256
        end
      else
        case @bit_per_pixel
        in BitPerPixel::MONOCHROME then raise "Bad palette size #{@colors_used} for monochrome bmp, expected 2" unless @colors_used == 2
        in BitPerPixel::DEPTH_4    then raise "Bad palette size #{@colors_used} for 4bpp bmp, expected up to 16" unless @colors_used <= 16
        in BitPerPixel::DEPTH_8    then raise "Bad palette size #{@colors_used} for 8bpp bmp, expected up to 256" unless @colors_used <= 256
        in BitPerPixel::DEPTH_16
          case @compression
          when Compression::BI_RGB then raise "Bad palette size #{@colors_used} for 16bpp bmp with RGB compression, expected 0" unless @colors_used == 0
          else                          raise "Unsupported compression #{@compression}"
          end
        in BitPerPixel::DEPTH_24 then raise "Bad palette size #{@colors_used} for 24bpp bmp, expected 0" unless @colors_used == 0
        in BitPerPixel::DEPTH_32 then raise "Unsupported color depth: #{@bit_per_pixel}"
        end
      end

      raise "Bad compression #{@compression} for #{self} header type" if @compression.in? [Compression::BI_BITFIELDS, Compression::BI_ALPHABITFIELDS]
    end
  end

  class InfoHeaderV2 < InfoHeader
    def initialize(io)
      super(io)
      @red_bitmask = io.read_bytes typeof(@red_bitmask), IO::ByteFormat::LittleEndian
      @green_bitmask = io.read_bytes typeof(@green_bitmask), IO::ByteFormat::LittleEndian
      @blue_bitmask = io.read_bytes typeof(@blue_bitmask), IO::ByteFormat::LittleEndian
      raise "Bad compression #{@compression} for #{self} header type" if @compression == Compression::BI_ALPHABITFIELDS
    end
  end

  class InfoHeaderV3 < InfoHeaderV2
    def initialize(io)
      super(io)
      @alpha_bitmask = io.read_bytes typeof(@alpha_bitmask), IO::ByteFormat::LittleEndian
    end
  end

  class ColorCoordinate
    def initialize(io)
      @x = io.read_bytes typeof(@x), IO::ByteFormat::LittleEndian
      @y = io.read_bytes typeof(@y), IO::ByteFormat::LittleEndian
      @z = io.read_bytes typeof(@z), IO::ByteFormat::LittleEndian
    end
  end

  class ColorsCoordinates
    def initialize(io)
      @red = ColorCoordinate.new io
      @green = ColorCoordinate.new io
      @blue = ColorCoordinate.new io
    end
  end

  class InfoHeaderV4 < InfoHeaderV3
    def initialize(io)
      super(io)
      @color_space = ColorSpace.from_value io.read_bytes Int32, IO::ByteFormat::LittleEndian
      @endpoints = ColorsCoordinates.new io
      @gamma_red = io.read_bytes typeof(@gamma_red), IO::ByteFormat::LittleEndian
      @gamma_green = io.read_bytes typeof(@gamma_green), IO::ByteFormat::LittleEndian
      @gamma_blue = io.read_bytes typeof(@gamma_blue), IO::ByteFormat::LittleEndian
    end
  end

  class InfoHeaderV5 < InfoHeaderV4
    def initialize(io)
      super(io)
      @intent = Intent.from_value io.read_bytes Int32, IO::ByteFormat::LittleEndian
      @profile_data = io.read_bytes typeof(@profile_data), IO::ByteFormat::LittleEndian
      @profile_size = io.read_bytes typeof(@profile_size), IO::ByteFormat::LittleEndian
      @reserved = io.read_bytes typeof(@reserved), IO::ByteFormat::LittleEndian
    end
  end

  class OSXInfoHeader < InfoHeader
    def initialize(io : IO)
      super(io)
      @resolution_unit = ResolutionUnit.from_value io.read_bytes Int16, IO::ByteFormat::LittleEndian
      @padding = io.read_bytes typeof(@padding), IO::ByteFormat::LittleEndian
      # Suspicious if not 0
      @bit_fill_origin = BitFillOrigin.from_value io.read_bytes Int16, IO::ByteFormat::LittleEndian
      @halftoning = HalftoningAlgorithm.from_value io.read_bytes Int16, IO::ByteFormat::LittleEndian
      @halftoning_parameter_1 = io.read_bytes typeof(@halftoning_parameter_1), IO::ByteFormat::LittleEndian
      @halftoning_parameter_2 = io.read_bytes typeof(@halftoning_parameter_2), IO::ByteFormat::LittleEndian
      @color_table_encoding = ColorTableEncoding.from_value io.read_bytes Int32, IO::ByteFormat::LittleEndian
      @app_identifier = io.read_bytes typeof(@app_identifier), IO::ByteFormat::LittleEndian
    end
  end

  class LightOSXInfoHeader < OSXInfoHeader
    def initialize(io : IO)
      @width = io.read_bytes typeof(@width), IO::ByteFormat::LittleEndian
      @height = io.read_bytes typeof(@height), IO::ByteFormat::LittleEndian
      @planes = io.read_bytes typeof(@planes), IO::ByteFormat::LittleEndian
      @bit_per_pixel = BitPerPixel.from_value io.read_bytes Int16, IO::ByteFormat::LittleEndian
      @compression = Compression::BI_RGB
      raise "Compression mode #{@compression} is not supported" if @compression.in? UNSUPPORTED_COMPRESSION
      @image_size = 0
      @x_pixel_per_m = 0
      @y_pixel_per_m = 0
      case @bit_per_pixel
      when BitPerPixel::MONOCHROME then @colors_used = 2
      when BitPerPixel::DEPTH_4    then @colors_used = 16
      when BitPerPixel::DEPTH_8    then @colors_used = 256
      else                              @colors_used = 0
      end
      @important_colors = 0
      @resolution_unit = ResolutionUnit::PIXEL_PER_METER
      @padding = 0
      @bit_fill_origin = BitFillOrigin::BOTTOM_LEFT
      @halftoning = HalftoningAlgorithm::NONE
      @halftoning_parameter_1 = 0
      @halftoning_parameter_2 = 0
      @color_table_encoding = ColorTableEncoding::RGB
      @app_identifier = 0
    end
  end

  class Color
    def initialize(io : IO)
      @blue = io.read_bytes typeof(@blue), IO::ByteFormat::LittleEndian
      @green = io.read_bytes typeof(@green), IO::ByteFormat::LittleEndian
      @red = io.read_bytes typeof(@red), IO::ByteFormat::LittleEndian
      @reserved = io.read_bytes typeof(@reserved), IO::ByteFormat::LittleEndian
    end

    def initialize(@red, @green, @blue, @reserved = 0u8)
    end

    def initialize(data : UInt32)
      @reserved = ((data & 0xff000000) >> 24).to_u8
      @blue = ((data & 0xff0000) >> 16).to_u8
      @green = ((data & 0xff00) >> 8).to_u8
      @red = (data & 0xff).to_u8
    end
  end

  def initialize(io : IO)
    @signature = io.read_bytes typeof(@signature), IO::ByteFormat::LittleEndian

    raise "bad signature: 0x#{@signature.to_s(16)}" unless @signature == SIGNATURE

    @file_size = io.read_bytes typeof(@file_size), IO::ByteFormat::LittleEndian
    @reserved = io.read_bytes typeof(@reserved), IO::ByteFormat::LittleEndian
    @data_offset = io.read_bytes typeof(@data_offset), IO::ByteFormat::LittleEndian

    @header_type = HeaderType.from_value io.read_bytes Int32, IO::ByteFormat::LittleEndian
    @header = case @header_type
              in HeaderType::CORE_HEADER           then CoreHeader.new io
              in HeaderType::OSX_INFO_HEADER       then OSXInfoHeader.new io
              in HeaderType::LIGHT_OSX_INFO_HEADER then LightOSXInfoHeader.new io
              in HeaderType::INFO_HEADER           then InfoHeader.new io
              in HeaderType::INFO_HEADER_V2        then InfoHeaderV2.new io
              in HeaderType::INFO_HEADER_V3        then InfoHeaderV3.new io
              in HeaderType::INFO_HEADER_V4        then InfoHeaderV4.new io
              in HeaderType::INFO_HEADER_V5        then InfoHeaderV5.new io
              end

    @color_table = @header.as?(InfoHeader).try do |header|
      Array(Color).new header.colors_used do
        Color.new io
      end
    end || [] of Color

    io.seek @data_offset if io.pos != @data_offset

    scan_line_size_byte = (width * @header.bit_per_pixel.value + padding) // 8
    @pixel_data = Bytes.new(scan_line_size_byte * height)
    io.read_fully(@pixel_data)

    # ICC data, but I couldnt find meaningful doc about it.
  end

  def self.from_file(path)
    File.open path, "r" do |io|
      self.new io
    end
  end
end
