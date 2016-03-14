ReShade Framework
=================

The ReShade Framework combines the standalone ReShade injector with a shader framework to easily manage all kinds of different effects.

## Contributing

Adding a new effect is as simple as creating a new folder with your name in the [shaders](/ReShade/Shaders) directory, putting the shader code in a ReShade FX file in there and adding a matching line to [Pipeline.cfg](/ReShade/Presets/Default/Pipeline.cfg).

Say you created a new shader at "ReShade\Shaders\YourName\YourShader.fx". The associated line in Pipeline.cfg would then look like this: ```#include EFFECT(YourName, YourShader)```

Check out [REFERENCE.md](REFERENCE.md) and the shader files in this repository to get started!
