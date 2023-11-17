#include "wind_loop_functions.h"
#include "debug/debug_entity.h"

namespace argos {

   /****************************************/
   /****************************************/

   void CMyLoopFunctions::Init(TConfigurationNode& t_tree) {
      m_unStepCount = 0;
      m_pcRNG = CRandom::CreateRNG("argos");

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
      m_unStepCount++ ;

      // wind
      CVector3 cWindBaseNormalVector = CVector3(1, 0, 0).Normalize();
      Real fWindDiviation = 5;
      Real fWindSpeed = 0.5;
      UInt32 unWindStartStep = 3800;
      UInt32 unWindEndStep = 3950;
      if ((unWindStartStep < m_unStepCount) && (m_unStepCount < unWindEndStep))
         for(STrackedEntity& s_tracked_entity : m_vecTrackedEntities) {
            Real fCurrentHeight = s_tracked_entity.EmbodiedEntity->GetOriginAnchor().Position.GetZ();
            if (fCurrentHeight > 2) {
               CVector3 cCurrentPositionV3 = s_tracked_entity.EmbodiedEntity->GetOriginAnchor().Position;
               CQuaternion cCurrentOrientationQ = s_tracked_entity.EmbodiedEntity->GetOriginAnchor().Orientation;

               Real fSideWind = m_pcRNG->Uniform(CRange<Real>(-fWindDiviation, fWindDiviation));
               CVector3 cWind = cWindBaseNormalVector + CVector3(fSideWind, fSideWind, fSideWind/3);
               cWind = cWind.Normalize() * fWindSpeed;
               if (s_tracked_entity.Entity->GetId() == "drone1" ) { cWind.SetY(0); cWind.SetZ(0);}

               s_tracked_entity.EmbodiedEntity->MoveTo(cCurrentPositionV3 + cWind,
                                                       cCurrentOrientationQ);
            }
         }

      // log locations
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

   REGISTER_LOOP_FUNCTIONS(CMyLoopFunctions, "exp_05_wind_loop_functions");
}
