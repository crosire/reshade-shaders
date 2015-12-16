//Stuff all/most of YourName shared shaders need
NAMESPACE_ENTER(YourName)
#define YourName_SETTINGS_DEF "ReShade/YourName.cfg"
#define YourName_SETTINGS_UNDEF "ReShade/YourName.undef" 

#include YourName_SETTINGS_DEF

//put your custom stuff here

#include YourName_SETTINGS_UNDEF
NAMESPACE_LEAVE()