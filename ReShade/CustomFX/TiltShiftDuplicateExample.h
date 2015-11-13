//This is an example on how to create a duplicate Shader
//This is possible for the following shader
/*
TilftShift from CustomFX Suite

All shader in GemFX Suite

HeatHaze and FishEye in McFX Suite

Explosion and CA in SweetFX Suite
*/
//Include the duplicate shader in EffectOrdering.cfg -> e.g. #include EFFECT(CustomFX, TiltShiftDuplicateExample)
//Note that values for duplicate shader are not yet configurable in the mediator -> changes in the EffectOrdering.cfg will be overwritten in the mediator

#define RFX_duplicate
////-------------//
///**TILTSHIFT**///
//-------------////
#define USE_TILTSHIFT 0 //[TiltShift] //-TiltShift effect based of GEMFX

//>TiltShift Settings<\\
#define TiltShiftPower 5.0 //[0.0:100.0] //-Amount of blur applied to the screen edges
#define TiltShiftCurve 3.0 //[0.0:10.0] //-Defines the sharp focus / blur radius
#define TiltShiftOffset -0.6 //[-5.0:5.0] //-Defines the sharp focus aligned to the y-axis
#define TiltShift_TimeOut 0 //[0:100000] //-Defined Toggle Key will activate the shader until time (in ms) runs out. "0" deactivates the timeout feature.
#define TiltShift_ToggleKey VK_SPACE //[undef] //-

#include "ReShade/CustomFX/TiltShift.h

#undef USE_TILTSHIFT
#undef TiltShiftPower
#undef TiltShiftCurve
#undef TiltShiftOffset
#undef TiltShift_TimeOut
#undef TiltShift_ToggleKey
#undef RFX_duplicate