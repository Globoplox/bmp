# bmp

Parse and build BMP files in crystal lang. No dependency.
Allows to read most BMP file with [Pluto](https://github.com/phenopolis/pluto).

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     bmp:
       github: globoplox/bmp
   ```

2. Run `shards install`

## Usage

```crystal
require "bmp"

bmp = BMP.from_file "spec/sample_640×426.bmp"
bmp.color_at(639, 425).red.should eq 58
bmp.color_at(0, 0).green.should eq 130
```

### With Pluto

Note that pluto is not listed as a dependency.

```
require "pluto"
require "bmp/pluto"

Pluto::ImageRGBA.from_bmp buffer
```

## Contributors

- [Globoplox](https://github.com/globoplox) - creator and maintainer
