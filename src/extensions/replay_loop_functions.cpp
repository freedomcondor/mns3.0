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
      std::map<std::string, CVector3> mapPosition;
      std::map<std::string, CQuaternion> mapOrientation;
      std::map<std::string, std::string> mapParent;
      bool bArrowsInLog = false;

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
         // get Position
         if (vecWordList.size() >= 3) {
            CPositionV3.SetX(std::stod(vecWordList[0]));
            CPositionV3.SetY(std::stod(vecWordList[1]));
            CPositionV3.SetZ(std::stod(vecWordList[2]));
         }
         // get Orientation
         if (vecWordList.size() >= 6) {
            CRadians CX, CY, CZ;
            CZ.FromValueInDegrees(std::stod(vecWordList[3]));
            CY.FromValueInDegrees(std::stod(vecWordList[4]));
            CX.FromValueInDegrees(std::stod(vecWordList[5]));
            COrientationQ.FromEulerAngles(CZ, CY, CX);
         }

         s_tracked_entity.EmbodiedEntity->MoveTo(CPositionV3, COrientationQ, false, true);

         //mapPosition.insert(std::make_pair(s_tracked_entity.EmbodiedEntity->GetId(), CPositionV3));
         std::string ID = s_tracked_entity.Entity->GetId();
         mapPosition[ID] = CPositionV3;
         mapOrientation[ID] = COrientationQ;

         if (vecWordList.size() > 6) {
            CQuaternion CVirtualOrientationQ(0,0,0,0);
            CVector3 CGoalPositionV3(0,0,0);
            CQuaternion CGoalOrientationQ(0,0,0,0);
            // get Virtual Orientation
            CRadians CX, CY, CZ;
            CZ.FromValueInDegrees(std::stod(vecWordList[6]));
            CY.FromValueInDegrees(std::stod(vecWordList[7]));
            CX.FromValueInDegrees(std::stod(vecWordList[8]));
            CVirtualOrientationQ.FromEulerAngles(CZ, CY, CX);

            // get Goal Position 
            CGoalPositionV3.SetX(std::stod(vecWordList[9]));
            CGoalPositionV3.SetY(std::stod(vecWordList[10]));
            CGoalPositionV3.SetZ(std::stod(vecWordList[11]));

            // get Goal Orientation
            //CRadians CX, CY, CZ;
            CZ.FromValueInDegrees(std::stod(vecWordList[12]));
            CY.FromValueInDegrees(std::stod(vecWordList[13]));
            CX.FromValueInDegrees(std::stod(vecWordList[14]));
            CGoalOrientationQ.FromEulerAngles(CZ, CY, CX);

            std::string strTarget = vecWordList[15];
            std::string strBrain = vecWordList[16];
         }

         if (vecWordList.size() >= 18) {
            std::string strParent = vecWordList[17];
            mapParent[ID] = strParent;
         }

         if (vecWordList.size() > 18) {
            bArrowsInLog = true;
            UInt32 nCurrentIdx = 18;
            while (nCurrentIdx < vecWordList.size()) {
               std::string strDrawType = vecWordList[nCurrentIdx];
               if (strDrawType == "ring") {
                  CVector3 cVecMiddle = CVector3(
                     std::stod(vecWordList[nCurrentIdx + 1]),
                     std::stod(vecWordList[nCurrentIdx + 2]),
                     std::stod(vecWordList[nCurrentIdx + 3])
                  );
                  Real fRadius = std::stod(vecWordList[nCurrentIdx + 4]);
                  nCurrentIdx += 5;
                  CColor cColor;
                  if (std::isdigit(vecWordList[nCurrentIdx][0])) {
                     cColor.Set(std::stod(vecWordList[nCurrentIdx]),
                                std::stod(vecWordList[nCurrentIdx + 1]),
                                std::stod(vecWordList[nCurrentIdx + 2])
                     );
                     nCurrentIdx += 3;
                  }
                  else {
                     cColor.Set(vecWordList[nCurrentIdx]);
                     nCurrentIdx ++;
                  }
                  s_tracked_entity.DebugEntity->GetRings().emplace_back(cVecMiddle, fRadius, cColor);
               }
               else if (strDrawType == "arrow") {
                  CVector3 cVecBegin = CVector3(
                     std::stod(vecWordList[nCurrentIdx + 1]),
                     std::stod(vecWordList[nCurrentIdx + 2]),
                     std::stod(vecWordList[nCurrentIdx + 3])
                  );
                  CVector3 cVecEnd = CVector3(
                     std::stod(vecWordList[nCurrentIdx + 4]),
                     std::stod(vecWordList[nCurrentIdx + 5]),
                     std::stod(vecWordList[nCurrentIdx + 6])
                  );
                  nCurrentIdx += 7;
                  CColor cColor;
                  if (std::isdigit(vecWordList[nCurrentIdx][0])) {
                     cColor.Set(std::stod(vecWordList[nCurrentIdx]),
                                std::stod(vecWordList[nCurrentIdx + 1]),
                                std::stod(vecWordList[nCurrentIdx + 2])
                     );
                     nCurrentIdx += 3;
                  }
                  else {
                     cColor.Set(vecWordList[nCurrentIdx]);
                     nCurrentIdx ++;
                  }
                  s_tracked_entity.DebugEntity->GetArrows().emplace_back(cVecBegin, cVecEnd, cColor);
               }
               else {
                  nCurrentIdx ++;
               }
            }
         }
      }

      if (bArrowsInLog == false) {
         for(STrackedEntity& s_tracked_entity : m_vecTrackedEntities) {
            if (s_tracked_entity.DebugEntity != NULL) {
               std::string ID = s_tracked_entity.Entity->GetId();
               std::string ParentID = mapParent[ID];
               if (ParentID == "nil")
                  s_tracked_entity.DebugEntity->GetRings().emplace_back(CVector3(0,0,0), 0.2, CColor::BLUE);
               else {
                  CVector3 CRelativePosition = mapPosition[ParentID] - mapPosition[ID];
                  CRelativePosition.Rotate(mapOrientation[ID].Inverse());
                  s_tracked_entity.DebugEntity->GetArrows().emplace_back(CRelativePosition, CVector3(0,0,0), CColor::BLUE);
               }
            }
         }
      }
   }
   
   /****************************************/
   /****************************************/

   REGISTER_LOOP_FUNCTIONS(CReplayLoopFunctions, "replay_loop_functions");
}
