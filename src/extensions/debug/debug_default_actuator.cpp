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
      if((nArgCount != 3) && (nArgCount != 6)) {
         const char* pchErrMsg = "robot.debug.draw_arrow() expects a 3 or 6 arguments";
         return luaL_error(pt_lua_state, pchErrMsg);
      }
      /* Get from and to */
      luaL_checktype(pt_lua_state, 1, LUA_TUSERDATA);
      const CVector3& cFrom = CLuaVector3::ToVector3(pt_lua_state, 1);
      luaL_checktype(pt_lua_state, 2, LUA_TUSERDATA);
      const CVector3& cTo = CLuaVector3::ToVector3(pt_lua_state, 2);
      /* Get color */
      luaL_checktype(pt_lua_state, 3, LUA_TSTRING);
      std::stringstream strColorString(lua_tostring(pt_lua_state, 3));
      std::vector<std::string> vecColorParameters;
      while( strColorString.good() )
      {
         std::string substr;
         getline(strColorString, substr, ',');
         vecColorParameters.push_back(substr);
      }
      CColor cColor;
      if(vecColorParameters.size() == 1) {
         try {
            cColor.Set(vecColorParameters[0]);
         }
         catch(CARGoSException& ex) {
            return luaL_error(pt_lua_state, ex.what());
         }
      }
      else {
         cColor.Set(std::stoi(vecColorParameters[0]),
                    std::stoi(vecColorParameters[1]),
                    std::stoi(vecColorParameters[2]));
      }
      /* write to the actuator */
      CDebugDefaultActuator* pcDebugActuator = 
         CLuaUtility::GetDeviceInstance<CDebugDefaultActuator>(pt_lua_state, "debug");
      if (nArgCount == 3) {
         pcDebugActuator->m_pvecArrows->emplace_back(cFrom, cTo, cColor);
      }
      else {
         Real fBodyThinkness = lua_tonumber(pt_lua_state, 4);
         Real fHeadThinkness = lua_tonumber(pt_lua_state, 5);
         Real fColorTransparent = lua_tonumber(pt_lua_state, 6);
         pcDebugActuator->m_pvecCustomizeArrows->emplace_back(cFrom, cTo, cColor, fBodyThinkness, fHeadThinkness, fColorTransparent);
      }
      return 0;
   }
#endif
   
   /****************************************/
   /****************************************/

#ifdef ARGOS_WITH_LUA
   int CDebugDefaultActuator::LuaDrawRing(lua_State* pt_lua_state) {
      /* check parameters */
      int nArgCount = lua_gettop(pt_lua_state);
      if((nArgCount != 3) && (nArgCount != 6)) {
         const char* pchErrMsg = "robot.debug.draw_ring() expects a 3 or 6 arguments";
         return luaL_error(pt_lua_state, pchErrMsg);
      }
      /* Get middle and radius */
      luaL_checktype(pt_lua_state, 1, LUA_TUSERDATA);
      const CVector3& cCenter = CLuaVector3::ToVector3(pt_lua_state, 1);
      luaL_checktype(pt_lua_state, 2, LUA_TNUMBER);
      Real fRadius = lua_tonumber(pt_lua_state, 2);
      /* Get color */
      luaL_checktype(pt_lua_state, 3, LUA_TSTRING);
      std::stringstream strColorString(lua_tostring(pt_lua_state, 3));
      std::vector<std::string> vecColorParameters;
      while( strColorString.good() )
      {
         std::string substr;
         getline(strColorString, substr, ',');
         vecColorParameters.push_back(substr);
      }
      CColor cColor;
      if(vecColorParameters.size() == 1) {
         try {
            cColor.Set(vecColorParameters[0]);
         }
         catch(CARGoSException& ex) {
            return luaL_error(pt_lua_state, ex.what());
         }
      }
      else {
         cColor.Set(std::stoi(vecColorParameters[0]),
                    std::stoi(vecColorParameters[1]),
                    std::stoi(vecColorParameters[2]));
      }
      /* write to the actuator */
      CDebugDefaultActuator* pcDebugActuator = 
         CLuaUtility::GetDeviceInstance<CDebugDefaultActuator>(pt_lua_state, "debug");
      if (nArgCount == 3) {
         pcDebugActuator->m_pvecRings->emplace_back(cCenter, fRadius, cColor);
      }
      else {
         Real fThinkness = lua_tonumber(pt_lua_state, 4);
         Real fHeight = lua_tonumber(pt_lua_state, 5);
         Real fColorTransparent = lua_tonumber(pt_lua_state, 6);
         pcDebugActuator->m_pvecCustomizeRings->emplace_back(cCenter, fRadius, cColor, fThinkness, fHeight, fColorTransparent);
      }

      return 0;
   }
#endif

   /****************************************/
   /****************************************/

#ifdef ARGOS_WITH_LUA
   int CDebugDefaultActuator::LuaDrawHalo(lua_State* pt_lua_state) {
      /* check parameters */
      int nArgCount = lua_gettop(pt_lua_state);
      if(nArgCount != 5) {
         const char* pchErrMsg = "robot.debug.draw_halo() expects a 3 arguments";
         return luaL_error(pt_lua_state, pchErrMsg);
      }
      /* Get middle and radius */
      luaL_checktype(pt_lua_state, 1, LUA_TUSERDATA);
      const CVector3& cCenter = CLuaVector3::ToVector3(pt_lua_state, 1);
      luaL_checktype(pt_lua_state, 2, LUA_TNUMBER);
      Real fRadius = lua_tonumber(pt_lua_state, 2);
      /* Get halo radius and max transparency */
      luaL_checktype(pt_lua_state, 3, LUA_TNUMBER);
      Real fHaloRadius = lua_tonumber(pt_lua_state, 3);
      luaL_checktype(pt_lua_state, 4, LUA_TNUMBER);
      Real fMaxTransparency = lua_tonumber(pt_lua_state, 4);
      /* Get color */
      luaL_checktype(pt_lua_state, 5, LUA_TSTRING);
      std::stringstream strColorString(lua_tostring(pt_lua_state, 5));
      std::vector<std::string> vecColorParameters;
      while( strColorString.good() )
      {
         std::string substr;
         getline(strColorString, substr, ',');
         vecColorParameters.push_back(substr);
      }
      CColor cColor;
      if(vecColorParameters.size() == 1) {
         try {
            cColor.Set(vecColorParameters[0]);
         }
         catch(CARGoSException& ex) {
            return luaL_error(pt_lua_state, ex.what());
         }
      }
      else {
         cColor.Set(std::stoi(vecColorParameters[0]),
                    std::stoi(vecColorParameters[1]),
                    std::stoi(vecColorParameters[2]));
      }
      /* write to the actuator */
      CDebugDefaultActuator* pcDebugActuator =
         CLuaUtility::GetDeviceInstance<CDebugDefaultActuator>(pt_lua_state, "debug");
      pcDebugActuator->m_pvecHalos->emplace_back(cCenter, fRadius, fHaloRadius, fMaxTransparency, cColor);

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
      CLuaUtility::AddToTable(pt_lua_state, "draw_halo", CDebugDefaultActuator::LuaDrawHalo);
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



   
