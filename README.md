ReShade Framework
=================

The ReShade Framework combines the standalone ReShade injector with a shader framework to easily manage all kings of different effects.

## Contributing

Adding a new effect is as simple as creating a new folder with your name in the [ReShade](/ReShade) directory, putting the shader code in a ReShade FX file in there and adding a matching line to [Pipeline.cfg](/ReShade/Pipeline.cfg).

Say you created a shader at "ReShade\YourName\YourShader.fx". The line in Pipeline.cfg would look like this: ```#include EFFECT(YourName, YourShader)```

Check out [REFERENCE.txt](REFERENCE.txt) and the shader files in this repository to get started!
