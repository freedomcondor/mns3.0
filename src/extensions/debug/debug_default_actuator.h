#ifndef DEBUG_DEFAULT_ACTUATOR_H
#define DEBUG_DEFAULT_ACTUATOR_H

namespace argos {
   class CDebugDefaultActuator;
}

#include <argos3/core/control_interface/ci_actuator.h>
#include <argos3/core/simulator/actuator.h>
#include <argos3/core/simulator/entity/composable_entity.h>
#include <argos3/core/utility/datatypes/color.h>

#include "debug_entity.h"

namespace argos {

   class CDebugDefaultActuator : public CSimulatedActuator,
                                 public CCI_Actuator {

   public:

      using TArrowVec = std::vector<std::tuple<CVector3, CVector3, CColor> >;
      using TRingVec = std::vector<std::tuple<CVector3, Real, CColor> >;
      using TMessageVec = std::vector<std::string>;
      
      CDebugDefaultActuator() :
         m_pcDebugEntity(nullptr) {}
      
      virtual ~CDebugDefaultActuator() {}

      virtual void SetRobot(CComposableEntity& c_entity) {
         /* insert a new debug entity into the component */
         m_pcDebugEntity = new CDebugEntity(&c_entity, "debug_0");
         c_entity.AddComponent(*m_pcDebugEntity);
      }

      virtual void Init(TConfigurationNode& t_tree) {
         m_pvecArrows = &m_pcDebugEntity->GetArrows();
         m_pvecRings = &m_pcDebugEntity->GetRings();
         m_pvecMessages = &m_pcDebugEntity->GetMessages();
      }

      virtual void Update() {
         m_pvecArrows->clear();
         m_pvecRings->clear();
         m_pvecMessages->clear();
      }

      virtual void Reset() {}

#ifdef ARGOS_WITH_LUA
      static int LuaDrawArrow(lua_State* pt_lua_state);
      static int LuaDrawRing(lua_State* pt_lua_state);
      static int LuaWrite(lua_State* pt_lua_state);
      virtual void CreateLuaState(lua_State* pt_lua_state);
#endif

   private:
      CDebugEntity* m_pcDebugEntity;
      
      TArrowVec* m_pvecArrows;
      TRingVec* m_pvecRings;
      TMessageVec* m_pvecMessages;
   };
}

#endif
