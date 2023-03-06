require "./spec_helper"

describe BMP do
  # Colors determined by opening in GIMP
  it "Open a simple bmp" do
    bmp = BMP.from_file "spec/sample_640×426.bmp"
    bmp.color(639, 425).red.should eq 58
    bmp.color(0, 0).green.should eq 130
  end

  it "Open a bigger bmp" do
    bmp = BMP.from_file "spec/sample_1280×853.bmp"
  end

  it "Open an even bigger bmp" do
    bmp = BMP.from_file "spec/sample_1920×1280.bmp"
  end

  it "Open a very very large bmp" do
    bmp = BMP.from_file "spec/sample_5184×3456.bmp"
  end

  it "Open a bmp with an info header v1, color depth of 24 and BI_RGB compression" do
    bmp = BMP.from_file "spec/w3c_home.bmp"
  end

  it "Open a bmp with an info header v1, color depth of 2 and BI_RGB compression" do
    bmp = BMP.from_file "spec/w3c_home_2.bmp"
  end

  it "Open a bmp with an info header v1, color depth of 8 and BI_RGB compression" do
    bmp = BMP.from_file "spec/w3c_home_256.bmp"
  end

  it "Open a bmp with a reduced OSX header, no padding, color depth of 8 and BI_RGB compression" do
    bmp = BMP.from_file "spec/pal8os2v2-16.bmp"
  end

  it "Can write a bmp to a file" do
    bmp = BMP.from_file "spec/pal8os2v2-16.bmp"
    bmp.to_file "/tmp/wololo.bmp"
  end

  it "Can build a simple valid BMP file" do
    bmp = BMP.new 100, 100, :depth_16
    bmp.color 0, 0, BMP::Color.new red: 0, green: 255, blue: 0
    bmp.to_file "/tmp/wololo.bmp"
  end
end
