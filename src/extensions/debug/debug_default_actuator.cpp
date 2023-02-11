#include "debug_default_actuator.h"

#include <argos3/core/utility/logging/argos_log.h>
#include <argos3/core/simulator/entity/composable_entity.h>

#ifdef ARGOS_WITH_LUA
#include <argos3/core/wrappers/lua/lua_utility.h>
#include <argos3/core/wrappers/lua/lua_vector3.h>
#endif

namespace argos {

   /****************************************/
   /****************************************/

#ifdef ARGOS_WITH_LUA
   int CDebugDefaultActuator::LuaDrawArrow(lua_State* pt_lua_state) {
      /* check parameters */
      int nArgCount = lua_gettop(pt_lua_state);
      if(nArgCount != 3 && nArgCount != 5) {
         const char* pchErrMsg = "robot.debug.draw_arrow() expects a 3 or 5 arguments";
         return luaL_error(pt_lua_state, pchErrMsg);
      }
      luaL_checktype(pt_lua_state, 1, LUA_TUSERDATA);
      const CVector3& cFrom = CLuaVector3::ToVector3(pt_lua_state, 1);
      luaL_checktype(pt_lua_state, 2, LUA_TUSERDATA);
      const CVector3& cTo = CLuaVector3::ToVector3(pt_lua_state, 2);
      /* Get color */
      CColor cColor;
      if(nArgCount == 3) {
         luaL_checktype(pt_lua_state, 3, LUA_TSTRING);
         try {
            cColor.Set(lua_tostring(pt_lua_state, 3));
         }
         catch(CARGoSException& ex) {
            return luaL_error(pt_lua_state, ex.what());
         }
      }
      else {
         luaL_checktype(pt_lua_state, 3, LUA_TNUMBER);
         luaL_checktype(pt_lua_state, 4, LUA_TNUMBER);
         luaL_checktype(pt_lua_state, 5, LUA_TNUMBER);
         cColor.Set(lua_tonumber(pt_lua_state, 3),
                    lua_tonumber(pt_lua_state, 4),
                    lua_tonumber(pt_lua_state, 5));
      }
      /* write to the actuator */
      CDebugDefaultActuator* pcDebugActuator = 
         CLuaUtility::GetDeviceInstance<CDebugDefaultActuator>(pt_lua_state, "debug");
      pcDebugActuator->m_pvecArrows->emplace_back(cFrom, cTo, cColor);
      return 0;
   }
#endif
   
   /****************************************/
   /****************************************/

#ifdef ARGOS_WITH_LUA
   int CDebugDefaultActuator::LuaDrawRing(lua_State* pt_lua_state) {
      /* check parameters */
      int nArgCount = lua_gettop(pt_lua_state);
      if(nArgCount != 3 && nArgCount != 5) {
         const char* pchErrMsg = "robot.debug.draw_ring() expects a 3 or 5 arguments";
         return luaL_error(pt_lua_state, pchErrMsg);
      }
      luaL_checktype(pt_lua_state, 1, LUA_TUSERDATA);
      const CVector3& cCenter = CLuaVector3::ToVector3(pt_lua_state, 1);
      luaL_checktype(pt_lua_state, 2, LUA_TNUMBER);
      Real fRadius = lua_tonumber(pt_lua_state, 2);
      /* Get color */
      CColor cColor;
      if(nArgCount == 3) {
         luaL_checktype(pt_lua_state, 3, LUA_TSTRING);
         try {
            cColor.Set(lua_tostring(pt_lua_state, 3));
         }
         catch(CARGoSException& ex) {
            return luaL_error(pt_lua_state, ex.what());
         }
      }
      else {
         luaL_checktype(pt_lua_state, 3, LUA_TNUMBER);
         luaL_checktype(pt_lua_state, 4, LUA_TNUMBER);
         luaL_checktype(pt_lua_state, 5, LUA_TNUMBER);
         cColor.Set(lua_tonumber(pt_lua_state, 3),
                    lua_tonumber(pt_lua_state, 4),
                    lua_tonumber(pt_lua_state, 5));
      }
      /* write to the actuator */
      CDebugDefaultActuator* pcDebugActuator = 
         CLuaUtility::GetDeviceInstance<CDebugDefaultActuator>(pt_lua_state, "debug");
      pcDebugActuator->m_pvecRings->emplace_back(cCenter, fRadius, cColor);
      return 0;
   }
#endif

   /****************************************/
   /****************************************/

#ifdef ARGOS_WITH_LUA
   int CDebugDefaultActuator::LuaWrite(lua_State* pt_lua_state) {
      /* check parameters */
      int nArgCount = lua_gettop(pt_lua_state);
      if(nArgCount != 1) {
         const char* pchErrMsg = "robot.debug.write() expects a single argument";
         return luaL_error(pt_lua_state, pchErrMsg);
      }
      luaL_checktype(pt_lua_state, 1, LUA_TSTRING);   
      /* write to the actuator */
      CDebugDefaultActuator* pcDebugActuator = 
         CLuaUtility::GetDeviceInstance<CDebugDefaultActuator>(pt_lua_state, "debug");
      pcDebugActuator->m_pvecMessages->emplace_back(lua_tostring(pt_lua_state, 1));
      return 0;
   }
#endif

   /****************************************/
   /****************************************/

#ifdef ARGOS_WITH_LUA
   void CDebugDefaultActuator::CreateLuaState(lua_State* pt_lua_state) {
      CLuaUtility::OpenRobotStateTable(pt_lua_state, "debug");
      CLuaUtility::AddToTable(pt_lua_state, "_instance", this);
      CLuaUtility::AddToTable(pt_lua_state, "draw_arrow", CDebugDefaultActuator::LuaDrawArrow);
      CLuaUtility::AddToTable(pt_lua_state, "draw_ring", CDebugDefaultActuator::LuaDrawRing);
      CLuaUtility::AddToTable(pt_lua_state, "write", CDebugDefaultActuator::LuaWrite);
      CLuaUtility::CloseRobotStateTable(pt_lua_state);
   }
#endif

   /****************************************/
   /****************************************/

   REGISTER_ACTUATOR(CDebugDefaultActuator,
                     "debug", "default",
                     "Michael Allwright [allsey87@gmail.com]",
                     "1.0",
                     "The debug actuator.",
                     "This actuator enables debugging interfaces for a robot",
                     "Usable"
                     );

   /****************************************/
   /****************************************/
   
}



   
