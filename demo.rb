$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'image_resizer'
require 'pry'
require 'pry-nav'
require 'pry-stack_explorer'

original_path = File.expand_path(File.dirname(__FILE__)) + '/tmp/test.jpg'
modified_path = File.expand_path(File.dirname(__FILE__)) + '/tmp/test_output.jpg'

temp_object = ImageResizer::TempObject.new(File.new(original_path))
processor = ImageResizer::Processor.new


upper_left = [0.25, 0.15]
lower_right = [0.75, 0.95]

# upper_left = [0, 0]
# lower_right = [0.50, 0.50]

width = 320
# width = 160

# processed = processor.crop_to_frame_and_scale(temp_object,
#                                   :upper_left => upper_left,
#                                   :lower_right => lower_right,
#                                   :width => width
#                                   )

height = 400
point = [0.9, 0.1]
processed = processor.resize_and_crop_around_point(temp_object,
                                  :point => point,
                                  :width => width,
                                  :height => height
                                  )

File.open(modified_path, 'wb') { |f| f.write(File.read(processed)) }
