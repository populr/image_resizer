ImageResizer
============

Provides an interface to ImageMagick for extracting image information and resizing / cropping.


Usage
=====

In your Gemfile:

    gem 'image_resizer'

Example:

    image = ImageResizer::TempObject.new(File.new(path_to_image_file))
    processor = ImageResizer::Processor.new

    # resize to fit the specified width, maintaining the original ratio
    tempfile = processor.resize(temp_object, :width => 320)

    # resize to fit the specified height, maintaining the original ratio
    tempfile = processor.resize(temp_object, :height => 240)

    # resize to the specified dimensions, cropping around the center to avoid stretching
    tempfile = processor.resize(temp_object, :width => 320, :height => 240)

    # crop the original image to a frame and resize the result
    upper_left = [0.25, 0.15] # 25% from the left, 15% from the top 
    lower_right = [0.75, 0.95] # 75% from the left, 95% from the top
    width = 320
    tempfile = processor.crop_to_frame_and_resize(temp_object,
                                      :upper_left => upper_left,
                                      :lower_right => lower_right,
                                      :width => width
                                      )

    # crop the original image around a point and resize the result
    point = [0.8, 0.3] # 80% from the left, 30% from the top
    width = 320
    height = 400
    tempfile = processor.resize_and_crop_around_point(temp_object,
                                      :point => point,
                                      :width => width,
                                      :height => height
                                      )
    File.open(path_to_output_file, 'wb') { |f| f.write(File.read(tempfile)) }


    # generate a .ico file with 16, 32, 64, 128, and 256 pixel square sizes
    tempfile = processor.generate_icon(temp_object)
    File.open(path_to_output_file, 'wb') { |f| f.write(File.read(tempfile)) }

Any of the resizing and cropping methods accept an optional :format option that determines the output format of the file (:png, :jpg, etc.). If omitted, the original file format is maintained.


Credits
=======

This project is heavily indebted to [Dragonfly](https://github.com/markevans/dragonfly). We needed the ability to crop and resize images, but there didn't appear to be any gems devoted to just that. Paperclip and Dragonfly both perform scaling and cropping using ImageMagick, but both do so as part of a larger project. So we pulled the ImageMagick specific parts out of Dragonfly, added new specs and cropping options, and are releasing the result as a dedicated image resizing gem.



