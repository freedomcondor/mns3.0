#include "replay_loop_functions.h"
#include "debug/debug_entity.h"

namespace argos {

   /****************************************/
   /****************************************/

   void CReplayLoopFunctions::Init(TConfigurationNode& t_tree) {
      /* read log file folder from replay_input_folder.txt */
      std::string strLogFolder = "./logs";
      std::ifstream infile("replay_input_folder.txt"); 
      if (!infile.fail())
         infile >> strLogFolder;

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
               m_vecTrackedEntities.emplace_back(pc_entity, &cBody, &cDebug, strLogFolder);
            }
            catch(CARGoSException& ex) {
               m_vecTrackedEntities.emplace_back(pc_entity, &cBody, nullptr, strLogFolder);
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

   void CReplayLoopFunctions::PreStep() {
      for(STrackedEntity& s_tracked_entity : m_vecTrackedEntities) {
         // read a line
         std::string strLine;
         if (!std::getline(s_tracked_entity.LogFile, strLine))
            exit(0);
         // split by ,
         std::vector<std::string> vecWordList;
         std::stringstream strstreamLineStream(strLine);
         while (strstreamLineStream.good()) {
            std::string substr;
            std::getline(strstreamLineStream, substr, ',' );
            vecWordList.push_back(substr);
         }
         CVector3 CPositionV3(0,0,0);
         CQuaternion COrientationQ(0,0,0,0);
         if (vecWordList.size() >= 3) {
            CPositionV3.SetX(std::stod(vecWordList[0]));
            CPositionV3.SetY(std::stod(vecWordList[1]));
            CPositionV3.SetZ(std::stod(vecWordList[2]));
         }
         if (vecWordList.size() >= 6) {
            COrientationQ.FromEulerAngles(
               CRadians(std::stod(vecWordList[3])),
               CRadians(std::stod(vecWordList[4])),
               CRadians(std::stod(vecWordList[5]))
            );
         }

         s_tracked_entity.EmbodiedEntity->MoveTo(CPositionV3, CQuaternion(1,0,0,1), false, true);
         //if (s_tracked_entity.DebugEntity != nullptr)
         //   s_tracked_entity.DebugEntity->GetArrows().emplace_back(CVector3(0,0,0), CVector3(1,0,0), CColor::BLUE);
      }
   }
   
   /****************************************/
   /****************************************/

   REGISTER_LOOP_FUNCTIONS(CReplayLoopFunctions, "replay_loop_functions");
}
