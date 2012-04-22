require 'spec_helper'

describe ImageResizer::Analyzer do

  before(:each) do
    @image = ImageResizer::TempObject.new(SAMPLES_DIR.join('beach.png'))
    @analyzer = ImageResizer::Analyzer.new
  end

  it "should return the width" do
    @analyzer.width(@image).should == 280
  end

  it "should return the height" do
    @analyzer.height(@image).should == 355
  end

  it "should return the aspect ratio" do
    @analyzer.aspect_ratio(@image).should == (280.0/355.0)
  end

  it "should say if it's portrait" do
    @analyzer.portrait?(@image).should be_true
  end

  it "should say if it's landscape" do
    @analyzer.landscape?(@image).should be_false
  end

  it "should return the number of colours" do
    @analyzer.number_of_colours(@image).should == 34703
  end

  it "should return the depth" do
    @analyzer.depth(@image).should == 8
  end

  it "should return the format" do
    @analyzer.format(@image).should == :png
  end

  %w(width height aspect_ratio number_of_colours depth format portrait? landscape?).each do |meth|
    it "should throw unable_to_handle in #{meth.inspect} if it's not an image file" do
      suppressing_stderr do
        temp_object = ImageResizer::TempObject.new('blah')
        lambda{
          @analyzer.send(meth, temp_object)
        }.should throw_symbol(:unable_to_handle)
      end
    end
  end

  it "should say if it's an image" do
    @analyzer.image?(@image).should == true
  end

  it "should say if it's not an image" do
    suppressing_stderr do
      @analyzer.image?(ImageResizer::TempObject.new('blah')).should == false
    end
  end

  it "should work for images with spaces in the filename" do
    image = ImageResizer::TempObject.new(SAMPLES_DIR.join('white pixel.png'))
    @analyzer.width(image).should == 1
  end

  it "should work (width) for images with capital letter extensions" do
    image = ImageResizer::TempObject.new(SAMPLES_DIR.join('DSC02119.JPG'))
    @analyzer.width(image).should == 1
  end

  it "should work (width) for images with numbers in the format" do
    image = ImageResizer::TempObject.new(SAMPLES_DIR.join('a.jp2'))
    @analyzer.width(image).should == 1
  end

end
