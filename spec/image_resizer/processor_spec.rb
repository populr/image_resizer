require 'spec_helper'

describe ImageResizer::Processor do

  before(:each) do
    @image = ImageResizer::TempObject.new(SAMPLES_DIR.join('beach.png')) # 280x355
    @processor = ImageResizer::Processor.new
  end

  describe "_resize" do

    it "should work correctly with xNN" do
      image = @processor._resize(@image, 'x30')
      image.should have_width(24)
      image.should have_height(30)
    end

    it "should work correctly with NNx" do
      image = @processor._resize(@image, '30x')
      image.should have_width(30)
      image.should have_height(38)
    end

    it "should work correctly with NNxNN" do
      image = @processor._resize(@image, '30x30')
      image.should have_width(24)
      image.should have_height(30)
    end

    it "should work correctly with NNxNN!" do
      image = @processor._resize(@image, '30x30!')
      image.should have_width(30)
      image.should have_height(30)
    end

    it "should work correctly with NNxNN%" do
      image = @processor._resize(@image, '25x50%')
      image.should have_width(70)
      image.should have_height(178)
    end

    describe "NNxNN>" do

      it "should not resize if the image is smaller than specified" do
        image = @processor._resize(@image, '1000x1000>')
        image.should have_width(280)
        image.should have_height(355)
      end

      it "should resize if the image is larger than specified" do
        image = @processor._resize(@image, '30x30>')
        image.should have_width(24)
        image.should have_height(30)
      end

    end

    describe "NNxNN<" do

      it "should not resize if the image is larger than specified" do
        image = @processor._resize(@image, '10x10<')
        image.should have_width(280)
        image.should have_height(355)
      end

      it "should resize if the image is smaller than specified" do
        image = @processor._resize(@image, '400x400<')
        image.should have_width(315)
        image.should have_height(400)
      end

    end

  end

  describe "crop" do # Difficult to test here other than dimensions

    it "should not crop if no args given" do
      image = @processor.crop(@image)
      image.should have_width(280)
      image.should have_height(355)
    end

    it "should crop using the offset given" do
      image = @processor.crop(@image, :x => '7', :y => '12')
      image.should have_width(273)
      image.should have_height(343)
    end

    it "should crop using the dimensions given" do
      image = @processor.crop(@image, :width => '10', :height => '20')
      image.should have_width(10)
      image.should have_height(20)
    end

    it "should crop in one dimension if given" do
      image = @processor.crop(@image, :width => '10')
      image.should have_width(10)
      image.should have_height(355)
    end

    it "should take into account the gravity given" do
      image1 = @processor.crop(@image, :width => '10', :height => '10', :gravity => 'nw')
      image2 = @processor.crop(@image, :width => '10', :height => '10', :gravity => 'se')
      image1.should_not equal_image(image2)
    end

    it "should clip bits of the image outside of the requested crop area when not nw gravity" do
      # Rmagick was previously throwing an error when the cropping area was outside the image size, when
      # using a gravity other than nw
      image = @processor.crop(@image, :width => '500', :height => '1000', :x => '100', :y => '200', :gravity => 'se')
      image.should have_width(180)
      image.should have_height(155)
    end

    it "should crop twice in a row correctly" do
      image1 = @processor.crop(@image,  :x => '10', :y => '10', :width => '100', :height => '100')
      image2 = @processor.crop(ImageResizer::TempObject.new(image1), :x => '0' , :y => '0' , :width => '50' , :height => '50' )
      image2.should have_width(50)
      image2.should have_height(50)
    end

    it "should crop twice in a row while consciously keeping page geometry" do
      # see http://www.imagemagick.org/Usage/crop/#crop_page
      # it explains how cropping multiple times without resetting geometry behaves
      image1 = @processor.crop(@image,  :x => '10', :y => '10', :width => '100', :height => '100', :repage => false)
      image2 = @processor.crop(ImageResizer::TempObject.new(image1), :x => '0' , :y => '0' , :width => '50' , :height => '50')
      image2.should have_width(40)
      image2.should have_height(40)
    end

  end


  describe "#resize(temp_object, width, height)" do
    context "when both the width and the height are non-zero" do
      it "should crop and scale to the specified dimensions" do
        @processor.should_receive(:resize_and_crop).with(@image, :width => 77, :height => 33, :gravity => 'c')
        @processor.resize(@image, :width => 77, :height => 33)
      end

      context "with the crop_from_top_if_portrait option" do
        context "with a portrait oriented image" do
          it "should resize and crop with a gravity of 'n'" do
            @processor.should_receive(:resize_and_crop).with(@image, :width => 77, :height => 33, :gravity => 'n')
            @processor.resize(@image, :width => 77, :height => 33, :crop_from_top_if_portrait => true)
          end
        end

        context "with a landscape oriented image" do
          it "should resize and crop with a gravity of 'c'" do
            @image = ImageResizer::TempObject.new(SAMPLES_DIR.join('landscape.png')) # 355x280
            @processor.should_receive(:resize_and_crop).with(@image, :width => 77, :height => 33, :gravity => 'c')
            @processor.resize(@image, :width => 77, :height => 33, :crop_from_top_if_portrait => true)
          end
        end
      end
    end

    context "when the height is 0, nil, or not present" do
      it "should restrict only in the horizontal dimension" do
        @processor.should_receive(:_resize).with(@image, '77x').exactly(3).times
        @processor.resize(@image, :width => 77, :height => 0)
        @processor.resize(@image, :width => 77, :height => nil)
        @processor.resize(@image, :width => 77)
      end
    end

    context "when the width is 0, nil, or not present" do
      it "should restrict only in the vertical dimension" do
        @processor.should_receive(:_resize).with(@image, 'x33').exactly(3).times
        @processor.resize(@image, :width => 0, :height => 33)
        @processor.resize(@image, :width => nil, :height => 33)
        @processor.resize(@image, :height => 33)
      end
    end

    context "when both height and width are 0, nil, or not present" do
      it "should return the original image file" do
        @image.should_receive(:file).exactly(3).times
        @processor.should_not_receive(:_resize)
        @processor.resize(@image, :width => 0, :height => 0)
        @processor.resize(@image, :width => nil, :height => nil)
        @processor.resize(@image)
      end
    end
  end




  describe "#resize_and_crop_around_point(:point => [x%, y%], :width => w, :height => h" do
    context "when the source image is portrait, but the requested ratio is landscape" do
      it "should call crop_to_frame_and_resize with a frame that is vertically centered on the focus point" do
        # original is 280px x 355px
        @processor.should_receive(:crop_to_frame_and_resize ).with(@image,
                                                                  :width => 100,
                                                                  :height => 60,
                                                                  :upper_left => [0.0, 0.5 - 280 * 0.6 / 355 / 2.0],
                                                                  :lower_right => [1.0, 0.5 + 280 * 0.6 / 355 / 2.0])
        @processor.resize_and_crop_around_point(@image,
                                            :point => [0.5, 0.5],
                                            :width => 100,
                                            :height => 60
                                          )
      end

      context "when the focus point is too close to the top to be the vertical center" do
        it "should call crop_to_frame_and_resize with a frame that is pinned at the top of the image" do
          # original is 280px x 355px
          @processor.should_receive(:crop_to_frame_and_resize ).with(@image,
                                                                    :width => 100,
                                                                    :height => 60,
                                                                    :upper_left => [0.0, 0.0],
                                                                    :lower_right => [1.0, 280 * 0.6 / 355])
          @processor.resize_and_crop_around_point(@image,
                                              :point => [0.5, 0.1],
                                              :width => 100,
                                              :height => 60
                                            )
        end
      end

      context "when the focus point is too close to the bottom to be the vertical center" do
        it "should call crop_to_frame_and_resize with a frame that is pinned at the bottom of the image" do
          # original is 280px x 355px
          @processor.should_receive(:crop_to_frame_and_resize ).with(@image,
                                                                    :width => 100,
                                                                    :height => 60,
                                                                    :upper_left => [0.0, 1 - 280 * 0.6 / 355],
                                                                    :lower_right => [1.0, 1.0])
          @processor.resize_and_crop_around_point(@image,
                                              :point => [0.5, 0.9],
                                              :width => 100,
                                              :height => 60
                                            )
        end
      end
    end

    context "when the source image is landscape, but the requested ratio is portrait" do
      before(:each) do
        @image = ImageResizer::TempObject.new(SAMPLES_DIR.join('landscape.png')) # 355x280
      end

      it "should call crop_to_frame_and_resize with a frame that is vertically centered on the focus point" do
        # original is 355px x 280px
        @processor.should_receive(:crop_to_frame_and_resize ).with(@image,
                                                                  :width => 60,
                                                                  :height => 100,
                                                                  :upper_left => [0.5 - 280 * 0.6 / 355 / 2.0, 0.0],
                                                                  :lower_right => [0.5 + 280 * 0.6 / 355 / 2.0, 1.0])
        @processor.resize_and_crop_around_point(@image,
                                            :point => [0.5, 0.5],
                                            :width => 60,
                                            :height => 100
                                          )
      end

      context "when the focus point is too close to the left to be the vertical center" do
        it "should call crop_to_frame_and_resize with a frame that is pinned at the left of the image" do
          # original is 355px x 280px
          @processor.should_receive(:crop_to_frame_and_resize ).with(@image,
                                                                    :width => 60,
                                                                    :height => 100,
                                                                    :upper_left => [0.0, 0.0],
                                                                    :lower_right => [280 * 0.6 / 355, 1.0])
          @processor.resize_and_crop_around_point(@image,
                                              :point => [0.1, 0.5],
                                              :width => 60,
                                              :height => 100
                                            )
        end
      end

      context "when the focus point is too close to the right to be the vertical center" do
        it "should call crop_to_frame_and_resize with a frame that is pinned at the right of the image" do
          # original is 355px x 280px
          @processor.should_receive(:crop_to_frame_and_resize ).with(@image,
                                                                    :width => 60,
                                                                    :height => 100,
                                                                    :upper_left => [1.0 - 280 * 0.6 / 355, 0.0],
                                                                    :lower_right => [1.0, 1.0])
          @processor.resize_and_crop_around_point(@image,
                                              :point => [0.9, 0.5],
                                              :width => 60,
                                              :height => 100
                                            )
        end
      end
    end

    context "when the specified width is 0" do
      it "should not raise an exception" do
        lambda {
          @processor.resize_and_crop_around_point(@image,
                                        :point => [0.20, 0.30],
                                        :width => 0,
                                        :height => 80
                                      )
        }.should_not raise_error
      end
    end

    context "when the specified height is 0" do
      it "should not raise an exception" do
        lambda {
          @processor.resize_and_crop_around_point(@image,
                                        :point => [0.20, 0.30],
                                        :width => 80,
                                        :height => 0
                                      )
        }.should_not raise_error
      end
    end
  end

  describe "#crop_to_frame_and_resize(:upper_left => [x%, y%], :lower_right => [x%, y%], :width => w, :height => h" do
    it "should call #crop with the :x & :y and :width & :height expressed in pixels and :width and :height determined by the frame bounds (not the width and height we pass in), and :resize expressed as widthxheight" do
      # original is 280px x 355px
      @processor.should_receive(:convert).with(@image, "-crop 140x178+56+107 -resize 70x89 +repage")
      @processor.crop_to_frame_and_resize(@image,
                                          :upper_left => [0.20, 0.30],
                                          :lower_right => [0.70, 0.80],
                                          :width => 70,
                                          :height => 89
                                        )
    end

    context "when width is 0, nil, or not present as an option" do
      it "should use the ratio defined by the upper_left and lower_right points to determine the width from the height" do
        # original is 280px x 355px
        @processor.should_receive(:convert).with(@image, "-crop 140x178+56+107 -resize 70x89 +repage").exactly(3).times
        @processor.crop_to_frame_and_resize(@image,
                                            :upper_left => [0.20, 0.30],
                                            :lower_right => [0.70, 0.80],
                                            :width => 0,
                                            :height => 89
                                          )

        @processor.crop_to_frame_and_resize(@image,
                                            :upper_left => [0.20, 0.30],
                                            :lower_right => [0.70, 0.80],
                                            :width => nil,
                                            :height => 89
                                          )

        @processor.crop_to_frame_and_resize(@image,
                                            :upper_left => [0.20, 0.30],
                                            :lower_right => [0.70, 0.80],
                                            :height => 89
                                          )
      end

    end

    context "when height is 0, nil, or not present as an option" do
      it "should use the ratio defined by the upper_left and lower_right points to determine the height from the width" do
        # original is 280px x 355px
        @processor.should_receive(:convert).with(@image, "-crop 140x178+56+107 -resize 70x89 +repage").exactly(3).times
        @processor.crop_to_frame_and_resize(@image,
                                            :upper_left => [0.20, 0.30],
                                            :lower_right => [0.70, 0.80],
                                            :width => 70,
                                            :height => 0
                                          )

        @processor.crop_to_frame_and_resize(@image,
                                            :upper_left => [0.20, 0.30],
                                            :lower_right => [0.70, 0.80],
                                            :width => 70,
                                            :height => nil
                                          )

        @processor.crop_to_frame_and_resize(@image,
                                            :upper_left => [0.20, 0.30],
                                            :lower_right => [0.70, 0.80],
                                            :width => 70
                                          )
      end
    end

    context "when both width and heigth are 0 or nil" do
      it "should not raise an exception" do
        lambda {
          @processor.crop_to_frame_and_resize(@image,
                                              :upper_left => [0.20, 0.30],
                                              :lower_right => [0.70, 0.80],
                                              :width => 0,
                                              :height => 0
                                            )
        }.should_not raise_error

        lambda {
          @processor.crop_to_frame_and_resize(@image,
                                              :upper_left => [0.20, 0.30],
                                              :lower_right => [0.70, 0.80]
                                            )
        }.should_not raise_error
      end

      context "when the frame specifies a width of 0" do
        it "should not raise an exception" do
          lambda {
            @processor.crop_to_frame_and_resize(@image,
                                                :upper_left => [0.20, 0.30],
                                                :lower_right => [0.20, 0.80],
                                                :width => 0,
                                                :height => 0
                                              )
          }.should_not raise_error
        end
      end

      context "when the frame specifies a height of 0" do
        it "should not raise an exception" do
          lambda {
            @processor.crop_to_frame_and_resize(@image,
                                                :upper_left => [0.20, 0.30],
                                                :lower_right => [0.70, 0.30],
                                                :width => 0,
                                                :height => 0
                                              )
          }.should_not raise_error
        end
      end
    end

  end

  describe "greyscale" do
    it "should not raise an error" do
      # Bit tricky to test
      @processor.greyscale(@image)
    end
  end

  describe "resize_and_crop" do

    it "should do nothing if no args given" do
      image = @processor.resize_and_crop(@image)
      image.should have_width(280)
      image.should have_height(355)
    end

    it "should do nothing if called without width and height" do
      image = @processor.resize_and_crop(@image)
      image.should have_width(280)
      image.should have_height(355)
      image.should eq @image
    end

    it "should crop to the correct dimensions" do
      image = @processor.resize_and_crop(@image, :width => '100', :height => '100')
      image.should have_width(100)
      image.should have_height(100)
    end

    it "should actually resize before cropping" do
      image1 = @processor.resize_and_crop(@image, :width => '100', :height => '100')
      image2 = @processor.crop(@image, :width => '100', :height => '100', :gravity => 'c')
      image1.should_not equal_image(image2)
    end

    it "should allow cropping in one dimension" do
      image = @processor.resize_and_crop(@image, :width => '100')
      image.should have_width(100)
      image.should have_height(355)
    end

    it "should take into account the gravity given" do
      image1 = @processor.resize_and_crop(@image, :width => '10', :height => '10', :gravity => 'nw')
      image2 = @processor.resize_and_crop(@image, :width => '10', :height => '10', :gravity => 'se')
      image1.should_not equal_image(image2)
    end

  end

  describe "rotate" do

    it "should rotate by 90 degrees" do
      image = @processor.rotate(@image, 90)
      image.should have_width(355)
      image.should have_height(280)
    end

    it "should not rotate given a larger height and the '>' qualifier" do
      image = @processor.rotate(@image, 90, :qualifier => '>')
      image.should have_width(280)
      image.should have_height(355)
    end

    it "should rotate given a larger height and the '<' qualifier" do
      image = @processor.rotate(@image, 90, :qualifier => '<')
      image.should have_width(355)
      image.should have_height(280)
    end

  end

  describe "strip" do
    it "should strip exif data" do
      jpg = ImageResizer::TempObject.new(SAMPLES_DIR.join('taj.jpg'))
      image = @processor.strip(jpg)
      image.should have_width(300)
      image.should have_height(300)
      image.size.should < jpg.size
    end
  end

  describe "thumb" do
    it "should call resize if the correct string given" do
      @processor.should_receive(:resize).with(@image, '30x40').and_return(image = mock)
      @processor.thumb(@image, '30x40').should == image
    end
    it "should call resize_and_crop if the correct string given" do
      @processor.should_receive(:resize_and_crop).with(@image, :width => '30', :height => '40', :gravity => 'se').and_return(image = mock)
      @processor.thumb(@image, '30x40#se').should == image
    end
    it "should call crop if x and y given" do
      @processor.should_receive(:crop).with(@image, :width => '30', :height => '40', :x => '+10', :y => '+20', :gravity => nil).and_return(image = mock)
      @processor.thumb(@image, '30x40+10+20').should == image
    end
    it "should call crop if just gravity given" do
      @processor.should_receive(:crop).with(@image, :width => '30', :height => '40', :x => nil, :y => nil, :gravity => 'sw').and_return(image = mock)
      @processor.thumb(@image, '30x40sw').should == image
    end
    it "should call crop if x, y and gravity given" do
      @processor.should_receive(:crop).with(@image, :width => '30', :height => '40', :x => '-10', :y => '-20', :gravity => 'se').and_return(image = mock)
      @processor.thumb(@image, '30x40-10-20se').should == image
    end
    it "should raise an argument error if an unrecognized string is given" do
      lambda{ @processor.thumb(@image, '30x40#ne!') }.should raise_error(ArgumentError)
    end
  end

  describe "auto-orient" do
    it "should rotate an image according to exif information" do
      @image = ImageResizer::TempObject.new(SAMPLES_DIR.join('beach.jpg'))
      @image.should have_width(355)
      @image.should have_height(280)
      image = @processor.auto_orient(@image)
      image.should have_width(280)
      image.should have_height(355)
    end
  end

  describe "flip" do
    it "should flip the image, leaving the same dimensions" do
      image = @processor.flip(@image)
      image.should have_width(280)
      image.should have_height(355)
    end
  end

  describe "flop" do
    it "should flop the image, leaving the same dimensions" do
      image = @processor.flop(@image)
      image.should have_width(280)
      image.should have_height(355)
    end
  end

  describe "convert" do
    it "should allow for general convert commands" do
      image = @processor.convert(@image, '-scale 56x71')
      image.should have_width(56)
      image.should have_height(71)
    end

    it "should allow for general convert commands with added format" do
      image, extra = @processor.convert(@image, '-scale 56x71', :gif)
      image.should have_width(56)
      image.should have_height(71)
      image.should have_format('gif')
      extra[:format].should == :gif
    end

    it "should work for commands with parenthesis" do
      image = @processor.convert(@image, "\\( +clone -sparse-color Barycentric '0,0 black 0,%[fx:h-1] white' -function polynomial 2,-2,0.5 \\) -compose Blur -set option:compose:args 15 -composite")
      image.should have_width(280)
    end

    it "should work for files with spaces in the name" do
      image = ImageResizer::TempObject.new(SAMPLES_DIR.join('white pixel.png'))
      @processor.convert(image, "-resize 2x2!").should have_width(2)
    end

    it "should allow an array of image files as the first parameter" do
      image1 = double('image1')
      image2 = double('image2')
      tempfile = double('tempfile')

      image1.stub(:path).and_return('hello world')
      image2.stub(:path).and_return('goodbye')
      tempfile.stub(:path).and_return('output path')

      @processor.stub(:new_tempfile).and_return(tempfile)
      @processor.should_receive(:run).with('convert', "'hello world' 'goodbye'  'output path'")
      image = @processor.convert([image1, image2])
    end
  end

  describe "#generate_icon" do
    it "it should create a multi-sized ico file from the source file" do
      two_fifty_six_png = double('256')
      @processor.should_receive(:convert).with(@image, '-resize 256x256! -transparent white', :png).and_return([two_fifty_six_png, :format => :png])
      sixteen_png = double('16')
      @processor.should_receive(:convert).with(two_fifty_six_png, '-resize 16x16! -transparent white').and_return(sixteen_png)
      thirty_two_png = double('32')
      @processor.should_receive(:convert).with(two_fifty_six_png, '-resize 32x32! -transparent white').and_return(thirty_two_png)
      sixty_four_png = double('64')
      @processor.should_receive(:convert).with(two_fifty_six_png, '-resize 64x64! -transparent white').and_return(sixty_four_png)
      one_twenty_eight_png = double('128')
      @processor.should_receive(:convert).with(two_fifty_six_png, '-resize 128x128! -transparent white').and_return(one_twenty_eight_png)

      ico = double('ico')
      @processor.should_receive(:convert).with([sixteen_png, thirty_two_png, sixty_four_png, one_twenty_eight_png, two_fifty_six_png],
                                                '', :ico).and_return([ico, :format => :ico])
      @processor.generate_icon(@image)
    end

    it "it should accept a :max_resolution option to limit the number of formats" do
      two_fifty_six_png = double('256')
      @processor.should_receive(:convert).with(@image, '-resize 256x256! -transparent white', :png).and_return([two_fifty_six_png, :format => :png])
      sixteen_png = double('16')
      @processor.should_receive(:convert).with(two_fifty_six_png, '-resize 16x16! -transparent white').and_return(sixteen_png)
      thirty_two_png = double('32')
      @processor.should_receive(:convert).with(two_fifty_six_png, '-resize 32x32! -transparent white').and_return(thirty_two_png)

      @processor.should_not_receive(:convert).with(two_fifty_six_png, '-resize 64x64! -transparent white')

      ico = double('ico')
      @processor.should_receive(:convert).with([sixteen_png, thirty_two_png],
                                                '', :ico).and_return([ico, :format => :ico])
      @processor.generate_icon(@image, :max_resolution => 32)
    end
  end
end
