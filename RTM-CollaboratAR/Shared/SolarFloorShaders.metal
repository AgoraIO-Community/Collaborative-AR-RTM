//
//  SolarFloorShaders.metal
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 28/10/2021.
//

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>

using namespace metal;

constexpr sampler samplerBilinear(coord::normalized,
                                 address::repeat,
                                 filter::linear,
                                 mip_filter::nearest);

[[visible]]
void fadeCircle(realitykit::surface_parameters params)
{
    auto modelPos = params.geometry().model_position();
    float distance = sqrt(modelPos.x * modelPos.x + modelPos.z * modelPos.z);

    // Retrieve the base color tint from the entity's material.
    half3 baseColorTint = (half3)params.material_constants().base_color_tint();

    // Retrieve the entity's texture coordinates.
    float2 uv = params.geometry().uv0();

    // Sample a value from the material's base color texture based on the
    // UV coordinates.
    auto tex = params.textures();
    half3 color = (half3)tex.base_color().sample(samplerBilinear, uv);

    // Multiply the tint by the sampled value from the texture, and
    // assign the result to the shader's base color property.
    color *= baseColorTint;
    params.surface().set_base_color(color);
    if (distance > 0.7f) {
        params.surface().set_opacity(max(cos(2 * (distance - 0.7)), 0.f));
    }
}
