# Persist a BMP file.
class BMP
  abstract class Header
    abstract def write(io : IO)
  end

  class CoreHeader < Header
    def write(io : IO)
      @width.to_io io, IO::ByteFormat::LittleEndian
      @height.to_io io, IO::ByteFormat::LittleEndian
      @planes.to_io io, IO::ByteFormat::LittleEndian
      @bit_per_pixel.value.to_i16.to_io io, IO::ByteFormat::LittleEndian
    end
  end

  class InfoHeader < Header
    def write(io : IO)
      @width.to_io io, IO::ByteFormat::LittleEndian
      @height.to_io io, IO::ByteFormat::LittleEndian
      @planes.to_io io, IO::ByteFormat::LittleEndian
      @bit_per_pixel.value.to_i16.to_io io, IO::ByteFormat::LittleEndian
      @compression.value.to_i32.to_io io, IO::ByteFormat::LittleEndian
      @image_size.to_io io, IO::ByteFormat::LittleEndian
      @x_pixel_per_m.to_io io, IO::ByteFormat::LittleEndian
      @y_pixel_per_m.to_io io, IO::ByteFormat::LittleEndian
      @colors_used.to_io io, IO::ByteFormat::LittleEndian
      @important_colors.to_io io, IO::ByteFormat::LittleEndian
    end
  end

  class InfoHeaderV2 < InfoHeader
    def write(io : IO)
      super
      @red_bitmask.to_io io, IO::ByteFormat::LittleEndian
      @green_bitmask.to_io io, IO::ByteFormat::LittleEndian
      @blue_bitmask.to_io io, IO::ByteFormat::LittleEndian
    end
  end

  class InfoHeaderV3 < InfoHeaderV2
    def write(io : IO)
      super
      @alpha_bitmask.to_io io, IO::ByteFormat::LittleEndian
    end
  end

  class ColorCoordinate
    def write(io : IO)
      @x.to_io io, IO::ByteFormat::LittleEndian
      @y.to_io io, IO::ByteFormat::LittleEndian
      @z.to_io io, IO::ByteFormat::LittleEndian
    end
  end

  class ColorsCoordinates
    def write(io : IO)
      @red.write io
      @green.write io
      @blue.write io
    end
  end

  class InfoHeaderV4 < InfoHeaderV3
    def write(io : IO)
      super
      @color_space.value.to_i32.to_io io, IO::ByteFormat::LittleEndian
      @endpoints.write io
      @gamma_red.to_io io, IO::ByteFormat::LittleEndian
      @gamma_green.to_io io, IO::ByteFormat::LittleEndian
      @gamma_blue.to_io io, IO::ByteFormat::LittleEndian
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
    def write(io : IO)
      super
      @resolution_unit.value.to_i16.to_io io, IO::ByteFormat::LittleEndian
      @padding.to_io io, IO::ByteFormat::LittleEndian
      @bit_fill_origin.value.to_i16.to_io io, IO::ByteFormat::LittleEndian
      @halftoning.value.to_i16.to_io io, IO::ByteFormat::LittleEndian
      @halftoning_parameter_1.to_io io, IO::ByteFormat::LittleEndian
      @halftoning_parameter_2.to_io io, IO::ByteFormat::LittleEndian
      @app_identifier.to_io io, IO::ByteFormat::LittleEndian
    end
  end

  # TODO: if mutated any other field, transform, call `OSXInfoHeader.write` instead ?
  class LightOSXInfoHeader < OSXInfoHeader
    def write(io : IO)
      @width.to_io io, IO::ByteFormat::LittleEndian
      @height.to_io io, IO::ByteFormat::LittleEndian
      @planes.to_io io, IO::ByteFormat::LittleEndian
      @bit_per_pixel.value.to_i16.to_io io, IO::ByteFormat::LittleEndian
    end
  end

  class Color
    def write(io : IO)
      @blue.to_io io, IO::ByteFormat::LittleEndian
      @green.to_io io, IO::ByteFormat::LittleEndian
      @red.to_io io, IO::ByteFormat::LittleEndian
      @reserved.to_io io, IO::ByteFormat::LittleEndian
    end
  end

  def write(io : IO)
    @signature.to_io io, IO::ByteFormat::LittleEndian
    @file_size.to_io io, IO::ByteFormat::LittleEndian
    @reserved.to_io io, IO::ByteFormat::LittleEndian
    @data_offset.to_io io, IO::ByteFormat::LittleEndian
    @header_type.value.to_i32.to_io io, IO::ByteFormat::LittleEndian
    @header.write io
    @color_table.each &.write io
    io.write @pixel_data
  end

  def to_file(io : IO)
    write io
  end
  
  def to_file(path : String | Path)
    File.open path, "w" do |io|
      write io
    end
  end
end
