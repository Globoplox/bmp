require "../bmp"

module Pluto::Format::BMP
  macro included
    def self.from_bmp(image_data : Bytes) : self
      bmp = ::BMP.new IO::Memory.new image_data
      compression = bmp.header.as?(BMP::InfoHeader).try &.compression
      case {bmp.header.bit_per_pixel, compression}
      when {BMP::BitPerPixel::DEPTH_24, BMP::Compression::BI_RGB}
        r = Array(UInt8).new bmp.height * bmp.width, 0u8
        g = Array(UInt8).new bmp.height * bmp.width, 0u8
        b = Array(UInt8).new bmp.height * bmp.width, 0u8
        a = Array(UInt8).new bmp.height * bmp.width, 0u8
        (0...bmp.height).each do |y|
          (0...bmp.width).each do |x|
            r[(bmp.height - 1 -y) * bmp.width + x] = bmp.pixel_data[(y * bmp.width + x) * 3 + 2]
            g[(bmp.height - 1 -y) * bmp.width + x] = bmp.pixel_data[(y * bmp.width + x) * 3 + 1]
            b[(bmp.height - 1 -y) * bmp.width + x] = bmp.pixel_data[(y * bmp.width + x) * 3]
          end
        end
        return Pluto::ImageRGBA.new r, g, b, a, bmp.width.to_i32, bmp.height.to_i32
      else
        raise "Unsupported BPP/Compression: #{bmp.header.bit_per_pixel}/#{compression}"
      end
    end
  end
end

{% for subclass in Pluto::Image.subclasses %}
  class {{subclass}}
    include Pluto::Format::BMP
  end
{% end %}
