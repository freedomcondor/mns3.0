#include "my_loop_functions.h"
#include "debug/debug_entity.h"

namespace argos {

   /****************************************/
   /****************************************/

   // Declaration of static variables
   std::vector<CMyLoopFunctions::STrackedEntity> CMyLoopFunctions::m_vecTrackedEntities;
   std::map<std::string, UInt32> CMyLoopFunctions::m_mapEntityIDTrackedEntityIndex;

   /****************************************/
   /****************************************/

   void CMyLoopFunctions::EntityMultiThreadIteration(CControllableEntity* cControllableEntity) {
      /* get tracked entity from cControllableEntity id */
      STrackedEntity& s_tracked_entity = m_vecTrackedEntities[
         m_mapEntityIDTrackedEntityIndex[cControllableEntity->GetRootEntity().GetId()]
      ];
      /* Store position, orientation and debug message */
      SAnchor& s_origin_anchor = s_tracked_entity.EmbodiedEntity->GetOriginAnchor();
      s_tracked_entity.LogFile << s_origin_anchor.Position << ',' << s_origin_anchor.Orientation;
      if(s_tracked_entity.DebugEntity) {
         CDebugEntity::TMessageVec& tMessageVec = s_tracked_entity.DebugEntity->GetMessages();
         for(std::string strMessage: tMessageVec) {
            s_tracked_entity.LogFile << ',' << strMessage;
         }
      }
      s_tracked_entity.LogFile << std::endl;
   }

   /****************************************/
   /****************************************/

   void CMyLoopFunctions::Init(TConfigurationNode& t_tree) {
      /* Remove old logs folder and create a new one */
      int intSystemReturn;
      intSystemReturn = system("rm -rf logs");
      if (intSystemReturn != 0) std::cout << "[warning]: Removing old logs folder didn't return success." << std::endl;
      intSystemReturn = system("mkdir -p logs");
      if (intSystemReturn != 0) std::cout << "[warning]: Creating new logs folder didn't return success." << std::endl;

      /* create a vector of tracked entities */
      CEntity::TVector& tRootEntityVector = GetSpace().GetRootEntityVector();
      UInt32 unEntityCount = 0;
      for(CEntity* pc_entity : tRootEntityVector) {
         CComposableEntity* pcComposable = dynamic_cast<CComposableEntity*>(pc_entity);
         if(pcComposable == nullptr) {
            continue;
         }
         try {
            CEmbodiedEntity& cBody = pcComposable->GetComponent<CEmbodiedEntity>("body");
            try {
               CDebugEntity& cDebug = pcComposable->GetComponent<CDebugEntity>("debug");
               m_vecTrackedEntities.emplace_back(pc_entity, &cBody, &cDebug);
               m_mapEntityIDTrackedEntityIndex[pc_entity->GetId()] = unEntityCount;
               unEntityCount++;
            }
            catch(CARGoSException& ex) {
               //no debug entity, assuming it is an obstacle and not controllable
               m_vecTrackedNoDebugEntities.emplace_back(pc_entity, &cBody, nullptr);
            }
         }
         catch(CARGoSException& ex) {
            /* only track entities with bodies */
            continue;
         }
      }
   }

   /****************************************/
   /****************************************/

   void CMyLoopFunctions::PostStep() {
      /* iterate controllable entities through multi thread framework */
      GetSpace().IterateOverControllableEntities(EntityMultiThreadIteration);
      /* iterate non-controllable entities */
      for (STrackedEntity& s_tracked_entity : m_vecTrackedNoDebugEntities) {
         /* Store position, orientation and debug message */
         SAnchor& s_origin_anchor = s_tracked_entity.EmbodiedEntity->GetOriginAnchor();
         s_tracked_entity.LogFile << s_origin_anchor.Position << ',' << s_origin_anchor.Orientation;
         s_tracked_entity.LogFile << std::endl;
      }
   }
   
   /****************************************/
   /****************************************/

   REGISTER_LOOP_FUNCTIONS(CMyLoopFunctions, "my_loop_functions");
}
