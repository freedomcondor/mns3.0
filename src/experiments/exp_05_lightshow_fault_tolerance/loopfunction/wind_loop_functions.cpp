#include "wind_loop_functions.h"
#include "debug/debug_entity.h"

namespace argos {

   /****************************************/
   /****************************************/

   void CMyLoopFunctions::Init(TConfigurationNode& t_tree) {
      m_unStepCount = 0;
      m_pcRNG = CRandom::CreateRNG("argos");
      m_bWindSignal = false;
      m_unWindEndStep = 0;

      /* Remove old logs folder and create a new one */
      int intSystemReturn;
      intSystemReturn = system("rm -rf logs");
      if (intSystemReturn != 0) std::cout << "[warning]: Removing old logs folder didn't return success." << std::endl;
      intSystemReturn = system("mkdir -p logs");
      if (intSystemReturn != 0) std::cout << "[warning]: Creating new logs folder didn't return success." << std::endl;

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
      UInt32 unWindPeriod = 150;
      Real fEffectLowest = 2;
      if ((m_bWindSignal == true) && (m_unStepCount < m_unWindEndStep))
         for(STrackedEntity& s_tracked_entity : m_vecTrackedEntities) {
            Real fCurrentHeight = s_tracked_entity.EmbodiedEntity->GetOriginAnchor().Position.GetZ();
            if (fCurrentHeight > fEffectLowest) {
               CVector3 cCurrentPositionV3 = s_tracked_entity.EmbodiedEntity->GetOriginAnchor().Position;
               CQuaternion cCurrentOrientationQ = s_tracked_entity.EmbodiedEntity->GetOriginAnchor().Orientation;

               Real fSideWind = m_pcRNG->Uniform(CRange<Real>(-fWindDiviation, fWindDiviation));
               CVector3 cWind = cWindBaseNormalVector + CVector3(fSideWind, fSideWind, fSideWind/3);
               cWind = cWind.Normalize() * fWindSpeed;
               if (s_tracked_entity.Entity->GetId() == m_strNewBrain ) { cWind.SetY(0); cWind.SetZ(0);}

               CVector3 v3NewPosition = cCurrentPositionV3 + cWind;
               if (v3NewPosition.GetZ() < fEffectLowest) v3NewPosition.SetZ(fEffectLowest);
               s_tracked_entity.EmbodiedEntity->MoveTo(v3NewPosition,
                                                       cCurrentOrientationQ);
            }
         }

      // log locations
      for(STrackedEntity& s_tracked_entity : m_vecTrackedEntities) {
         SAnchor& s_origin_anchor = s_tracked_entity.EmbodiedEntity->GetOriginAnchor();
         s_tracked_entity.LogFile << s_origin_anchor.Position << ',' << s_origin_anchor.Orientation;
         if(s_tracked_entity.DebugEntity) {
            CDebugEntity::TMessageVec& tMessageVec = s_tracked_entity.DebugEntity->GetMessages();
            // Parse message and check for wind signal
            for(std::string strMessage: tMessageVec) {
               if (strMessage == "wind") {
                  m_bWindSignal = true;
                  m_unWindEndStep = m_unStepCount + unWindPeriod;
               }
               else if (strMessage.rfind("newBrain:", 0) == 0) {
                  std::string prefix = "newBrain:";
                  m_strNewBrain = strMessage.erase(0, prefix.length());
                  std::cout << m_strNewBrain << std::endl;
               }
               else {
                  s_tracked_entity.LogFile << ',' << strMessage;
               }
            }
         }
         s_tracked_entity.LogFile << std::endl;
      }
   }
   
   /****************************************/
   /****************************************/

   REGISTER_LOOP_FUNCTIONS(CMyLoopFunctions, "exp_05_wind_loop_functions");
}
