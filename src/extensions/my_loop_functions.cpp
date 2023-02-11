#include "my_loop_functions.h"
#include "debug/debug_entity.h"

namespace argos {

   /****************************************/
   /****************************************/

   void CMyLoopFunctions::Init(TConfigurationNode& t_tree) {
      system("rm -rf logs");
      system("mkdir -p logs");
      /* create a vector of tracked entities */
      CEntity::TVector& tRootEntityVector = GetSpace().GetRootEntityVector();
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
            }
            catch(CARGoSException& ex) {
               m_vecTrackedEntities.emplace_back(pc_entity, &cBody, nullptr);
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
      for(STrackedEntity& s_tracked_entity : m_vecTrackedEntities) {
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
   }
   
   /****************************************/
   /****************************************/

   REGISTER_LOOP_FUNCTIONS(CMyLoopFunctions, "my_loop_functions");
}
