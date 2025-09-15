/*
Copyright(c) 2015-2025 Panos Karabelas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions :

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// = INCLUDES ========
#include "common.hlsl"
#include "fog.hlsl"
//====================

RWTexture2D<float4> slope_map : register(u13);

[numthreads(THREAD_GROUP_COUNT_X, THREAD_GROUP_COUNT_Y, 1)]
void main_cs(uint3 thread_id : SV_DispatchThreadID)
{
    // create surface
    float2 resolution_out;
    tex_uav.GetDimensions(resolution_out.x, resolution_out.y);
    Surface surface;
    surface.Build(thread_id.xy, resolution_out, true, false);

    // initialize
    float3 light_diffuse       = 0.0f;
    float3 light_specular      = 0.0f;
    float3 light_emissive      = 0.0f;
    float3 light_atmospheric   = 0.0f;
    float alpha                = 0.0f;
    float distance_from_camera = 0.0f;

    // during the compute pass, fill in the sky pixels
    if (surface.is_sky() && pass_is_opaque())
    {
        light_emissive       = tex2.SampleLevel(samplers[sampler_bilinear_clamp], direction_sphere_uv(surface.camera_to_pixel), 0).rgb;
        alpha                = 0.0f;
        distance_from_camera = FLT_MAX_16;
    }
    // for the opaque pass, fill in the opaque pixels, and for the transparent pass, fill in the transparent pixels
    else if ((pass_is_opaque() && surface.is_opaque()) || (pass_is_transparent() && surface.is_transparent()))
    {
        light_diffuse        = tex3.SampleLevel(samplers[sampler_point_clamp], surface.uv, 0).rgb;
        light_specular       = tex4.SampleLevel(samplers[sampler_point_clamp], surface.uv, 0).rgb;
        light_emissive       = surface.emissive * surface.albedo * 10.0f;
        alpha                = surface.alpha;
        distance_from_camera = surface.camera_to_pixel_length;
    }

    // fog
    {
        // sky color is used to light up the fog
        // occlusion is used to shadow it
        
        float max_mip         = pass_get_f3_value().x;
        float fog_density     = pass_get_f3_value().y * 0.5f;
        float3 sky_color      = tex2.SampleLevel(samplers[sampler_trilinear_clamp], float2(0.5, 0.5), max_mip).rgb;
        float fog_atmospheric = get_fog_atmospheric(distance_from_camera, surface.position.y);
        float3 fog_emissive   = tex5.SampleLevel(samplers[sampler_point_clamp], surface.uv, 0).rgb;
        
        // additive: ambient in-scatter + volumetric, then scale by density
        float3 fog_inscatter = fog_atmospheric * sky_color; // ambient part
        light_atmospheric    = (fog_inscatter + fog_emissive) * fog_density;
    }

    float accumulate      = (pass_is_transparent() && !surface.is_transparent()) ? 1.0f : 0.0f; // transparent surfaces will sample the background via refraction, no need to blend
    tex_uav[thread_id.xy] = float4(light_diffuse * surface.albedo + light_specular + light_emissive + light_atmospheric, alpha) + tex_uav[thread_id.xy] * accumulate;

    if (surface.is_ocean())
    {
        //float3 foamColor = float3(1.0f, 0.0f, 0.0f);
        //
        //float4 ndcPos = mul(float4(surface.position, 1.0f), buffer_frame.view_projection);
        //
        //float2 uv = ndc_to_uv(ndcPos.xyz);
        //float foam = 1.0f;//slope_map[thread_id.xy].a;
        //tex_uav[thread_id.xy].rgb = lerp(tex_uav[thread_id.xy].rgb, foamColor, foam);
    	tex_uav[thread_id.xy].rgb = float3(0.0f, 1.0f, 0.0f);
	}
	else
	{
		tex_uav[thread_id.xy].rgb = float3(1.0f, 0.0f, 0.0f);
	}
}
