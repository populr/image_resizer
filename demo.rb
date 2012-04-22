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


upper_left = ['25%', '25%']
lower_right = ['75%', '75%']

# upper_left = ['0%', '0%']
# lower_right = ['50%', '50%']

width = 320
height = 180

width = 160
height = 90
processed = processor.crop_to_frame_and_scale(temp_object,
                                  :upper_left => upper_left,
                                  :lower_right => lower_right,
                                  :width => width,
                                  :height => height
                                  )
File.open(modified_path, 'wb') { |f| f.write(File.read(processed)) }
