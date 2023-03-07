# File structure of a BMP file.
class BMP
  SIGNATURE = 0x4D42u16

  enum HeaderType
    CORE_HEADER           =  12
    INFO_HEADER           =  40
    LIGHT_OSX_INFO_HEADER =  16
    OSX_INFO_HEADER       =  64
    INFO_HEADER_V2        =  52
    INFO_HEADER_V3        =  56
    INFO_HEADER_V4        = 108
    INFO_HEADER_V5        = 124
  end

  enum Compression
    BI_RGB            =   0
    BI_BITFIELDS      =   3
    BI_RLE8           =   1
    BI_RLE4           =   2
    BI_JPEG           =   4
    BI_PNG            =   5
    BI_ALPHABITFIELDS =   6
    BI_CMYK           = 0xB
    BI_CMYKRLE8       = 0xC
    BI_CMYKRLE4       = 0xD
  end

  enum BitPerPixel
    MONOCHROME =  1
    DEPTH_4    =  4
    DEPTH_8    =  8
    DEPTH_16   = 16
    DEPTH_24   = 24
    DEPTH_32   = 32
  end

  abstract class Header
    abstract def width
    abstract def height
    abstract def bit_per_pixel
  end

  class CoreHeader < Header
    property width : UInt16
    property height : UInt16
    property planes : UInt16
    property bit_per_pixel : BitPerPixel
  end

  class InfoHeader < Header
    property width : UInt32
    property height : UInt32
    property planes : UInt16
    property bit_per_pixel : BitPerPixel
    property compression : Compression
    property image_size : UInt32
    property x_pixel_per_m : UInt32
    property y_pixel_per_m : UInt32
    property colors_used : UInt32
    property important_colors : UInt32
  end

  class InfoHeaderV2 < InfoHeader
    property red_bitmask : UInt32
    property green_bitmask : UInt32
    property blue_bitmask : UInt32
  end

  class InfoHeaderV3 < InfoHeaderV2
    property alpha_bitmask : UInt32
  end

  enum ColorSpace
    LCS_CALIBRATED_RGB = 0x73524742
  end

  class ColorCoordinate
    property x : UInt32
    property y : UInt32
    property z : UInt32
  end

  class ColorsCoordinates
    property red : ColorCoordinate
    property green : ColorCoordinate
    property blue : ColorCoordinate
  end

  class InfoHeaderV4 < InfoHeaderV3
    property color_space : ColorSpace
    property endpoints : ColorsCoordinates
    property gamma_red : UInt32
    property gamma_green : UInt32
    property gamma_blue : UInt32
  end

  enum Intent
    MATCH   = 8
    GRAPHIC = 1
    PROOF   = 2
    PICTURE = 4
  end

  class InfoHeaderV5 < InfoHeaderV4
    property intent : Intent
    property profile_data : UInt32
    property profile_size : UInt32
    property reserved : UInt32
  end

  enum ResolutionUnit
    PIXEL_PER_METER = 0
  end

  enum BitFillOrigin
    BOTTOM_LEFT = 0
  end

  enum HalftoningAlgorithm
    NONE            = 0
    ERROR_DIFFUSION = 1
    PANDA           = 2
    SUPER_CIRCLE    = 3
  end

  enum ColorTableEncoding
    RGB = 0
  end

  # OSX Variant
  class OSXInfoHeader < InfoHeader
    property resolution_unit : ResolutionUnit
    property padding : UInt16
    property bit_fill_origin : BitFillOrigin
    property halftoning : HalftoningAlgorithm
    property halftoning_parameter_1 : UInt32
    property halftoning_parameter_2 : UInt32
    property color_table_encoding : ColorTableEncoding
    property app_identifier : UInt32
  end

  class LightOSXInfoHeader < OSXInfoHeader
  end

  class Color
    property red : UInt8
    property green : UInt8
    property blue : UInt8
    property reserved : UInt8
  end

  # Bitmap file header
  property signature : UInt16
  property file_size : UInt32
  property reserved : UInt32
  property data_offset : UInt32

  # DIB header, there are multiple kind of headers.
  property header_type : HeaderType
  property header : Header

  property color_table : Array(Color)
  property pixel_data : Bytes

  def width
    @header.width.to_u32
  end

  def height
    @header.height.to_u32
  end

  @padding : UInt8?

  # Amount of padding bit at end of each scan lines.
  def padding
    @padding ||= @header.as?(OSXInfoHeader).try do |header|
      header.padding.to_u8
    end || begin
      bits = width * @header.bit_per_pixel.value % 32
      bits = 32 - bits if bits != 0
      bits.to_u8
    end
  end
end

require "./parse"
require "./decode"
require "./write"
require "./build"
