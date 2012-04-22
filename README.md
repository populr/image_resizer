Rationale
---------

A project we are working on needed the ability to crop and resize images. Paperclip and Dragonfly both perform scaling and cropping using ImageMagick, but both do so as part of a larger project. We initially included Dragonfly, and only used the analyze and process objects, but it felt wrong to use the tool in a way it wasn't intended. Then came the day when we needed more control over the cropping options that came with Dragonfly. So over the Hack Nashville weekend, we pulled the ImageMagick specific parts out of Dragonfly, got the specs to pass, and then added new specs and new cropping options

Dragonfly did a good job of modularizing the ImageMagick calls, so this project is essentially the Dragonfly ImageMagick modules abstracted into a more general purpose gem.


