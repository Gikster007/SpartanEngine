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

#pragma once

//= INCLUDES ===================
#include "../Math/BoundingBox.h"
//==============================

namespace spartan
{
    class Camera;
    class Light;

    class World
    {
    public:
        // system
        static void Initialize();
        static void Shutdown();
        static void Tick();

        // io
        static bool SaveToFile(std::string filePath);
        static bool LoadFromFile(const std::string& file_path);

        // entities
        static Entity* CreateEntity();
        static bool EntityExists(Entity* entity);
        static void RemoveEntity(Entity* entity);
        static void GetRootEntities(std::vector<Entity*>& entities);
        static Entity* GetEntityById(uint64_t id);
        static const std::vector<Entity*>& GetEntities();
        static const std::vector<Entity*>& GetEntitiesLights();

        // misc
        static std::string GetName();
        static const std::string& GetFilePath();
        static math::BoundingBox& GetBoundingBox();
        static Camera* GetCamera();
        static Light* GetDirectionalLight();
        static uint32_t GetLightCount();
        static uint32_t GetAudioSourceCount();
        static bool HaveMaterialsChangedThisFrame();
        static bool HaveLightsChangedThisFrame();

        // world time: 0.0 = midnight, 0.5 = noon, 1.0 = next midnight
        static float GetTimeOfDay(bool use_real_world_time = false);

    private:
        static void ProcessPendingRemovals();
        static void ProcessPendingAdditions();
    };
}
