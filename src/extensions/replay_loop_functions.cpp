#include "replay_loop_functions.h"
#include "debug/debug_entity.h"

namespace argos {

   /****************************************/
   /****************************************/

   void CReplayLoopFunctions::Init(TConfigurationNode& t_tree) {
      m_unStepCount = 0;
      /* read log file folder from replay_input_folder.txt */
      std::string strLogFolder = "./logs";
      std::ifstream infile("replay_input_folder.txt"); 
      std::string strDrawGoalFlag = "False";
      std::string strDrawDebugArrowsFlag = "False";
      std::string strDrawTrackFlag = "False";
      std::string strDrawTrackKeyFrame = "";
      if (!infile.fail()) {
         infile >> strLogFolder;
         infile >> strDrawGoalFlag;
         infile >> strDrawDebugArrowsFlag;
         infile >> strDrawTrackFlag;
         // read a "\n" and then the content
         std::getline(infile, strDrawTrackKeyFrame);
         if (infile.good()) std::getline(infile, strDrawTrackKeyFrame);
         if (infile.good()) infile >> m_unDrawTrackEveryXStep;

         if (strDrawGoalFlag == "True")
            m_bDrawGoalFlag = true;
         if (strDrawDebugArrowsFlag == "True")
            m_bDrawDebugArrowsFlag = true;
         if (strDrawTrackFlag == "True")
            m_bDrawTrackFlag = true;
         // get key frame
         if (strDrawTrackKeyFrame != "None") {
            // split by ,
            std::vector<std::string> vecWordList;
            std::stringstream strstreamLineStream(strDrawTrackKeyFrame);
            while (strstreamLineStream.good()) {
               std::string substr;
               std::getline(strstreamLineStream, substr, ' ' );
               vecWordList.push_back(substr);
            }
            for (std::string word : vecWordList)
               m_vecDrawTrackKeyFrame.push_back(std::stoi(word));
         }
      }

      /* create a colormap */
      UInt16 r = 255;
      UInt16 g = 1;
      UInt16 b = 0;
      while (!((r == 255) && (g == 0) && (b == 0))) {
         if (r == 255 && g < 255 && b == 0) g++;
         if (g == 255 && r > 0 && b == 0) r--;
         if (g == 255 && b < 255 && r == 0) b++;
         if (b == 255 && g > 0 && r == 0) g--;
         if (b == 255 && r < 255 && g == 0) r++;
         if (r == 255 && b > 0 && g == 0) b--;
         m_vecColorMap.push_back(CColor(r,g,b,255));
         m_vecLightColorMap.push_back(CColor(r,g,b,30));
      }

      /* create a vector of tracked entities */
      CEntity::TVector& tRootEntityVector = GetSpace().GetRootEntityVector();
      UInt16 unColorMapStepLength = std::floor(m_vecColorMap.size() / tRootEntityVector.size());
      UInt16 unHardColorEveryXRobots = std::floor(tRootEntityVector.size() / 5);
      UInt16 unColorMapIndex = 0;
      UInt16 unEntityCount = 0;
      for(CEntity* pc_entity : tRootEntityVector) {
         unEntityCount++;
         unColorMapIndex += unColorMapStepLength;
         CComposableEntity* pcComposable = dynamic_cast<CComposableEntity*>(pc_entity);
         if(pcComposable == nullptr) {
            continue;
         }
         try {
            CEmbodiedEntity& cBody = pcComposable->GetComponent<CEmbodiedEntity>("body");
            CColor cColor = m_vecLightColorMap[unColorMapIndex];
            if (unEntityCount % unHardColorEveryXRobots == 0)
               cColor = m_vecColorMap[unColorMapIndex];
            try {
               CDebugEntity& cDebug = pcComposable->GetComponent<CDebugEntity>("debug");
               m_vecTrackedEntities.emplace_back(pc_entity, &cBody, &cDebug, strLogFolder, cColor);
            }
            catch(CARGoSException& ex) {
               m_vecTrackedEntities.emplace_back(pc_entity, &cBody, nullptr, strLogFolder, cColor);
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
         //std::string strLine;
         //if (!std::getline(s_tracked_entity.LogFile, strLine))
         //   exit(0);
         int bufferLength = 4096;
         char buff[bufferLength];
         if (!fgets(buff, bufferLength, s_tracked_entity.LogFile))
            exit(0);
         std::string strLine = buff;
         // strip \n from end
         strLine.erase(std::remove(strLine.begin(), strLine.end(), '\n'), strLine.end());

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
         if (m_bDrawTrackFlag == true) {
            s_tracked_entity.vecTrack.push_back(CPositionV3);
            if ((m_vecDrawTrackKeyFrame.size() > 0) && (m_unStepCount == m_vecDrawTrackKeyFrame[0]))
               s_tracked_entity.vecKeyFrame.emplace_back(CPositionV3);
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

         // draw Track
         if ((m_bDrawTrackFlag == true) &&
             (m_unStepCount % m_unDrawTrackEveryXStep == 0) &&
             (s_tracked_entity.vecTrack.size() > 1) &&
             (s_tracked_entity.DebugEntity != NULL)) {
            for (UInt32 i = 1; i < s_tracked_entity.vecTrack.size(); i++) {
               CVector3 CRelativePosition1 = CVector3(s_tracked_entity.vecTrack[i-1] - CPositionV3).Rotate(COrientationQ.Inverse());
               CVector3 CRelativePosition2 = CVector3(s_tracked_entity.vecTrack[i] - CPositionV3).Rotate(COrientationQ.Inverse());
               s_tracked_entity.DebugEntity->GetCustomizeArrows().emplace_back(
                  CRelativePosition1,
                  CRelativePosition2,
                  s_tracked_entity.CTrackColor,
                  0.10,
                  0.0,
                  1
               );
            }
         }

         // draw KeyFrame
         if ((s_tracked_entity.vecKeyFrame.size() > 0) &&
             (s_tracked_entity.DebugEntity != NULL)) {
            for (STrackedEntity::SKeyFrame keyFrame : s_tracked_entity.vecKeyFrame) {
               CVector3 CRelativePosition = CVector3(keyFrame.PositionV3 - CPositionV3).Rotate(COrientationQ.Inverse());
               Real fRadius = 0.3;
               s_tracked_entity.DebugEntity->GetRings().emplace_back(CRelativePosition, fRadius, CColor::BLACK);
               s_tracked_entity.DebugEntity->GetRings().emplace_back(CRelativePosition, fRadius-0.10, CColor::BLACK);
               s_tracked_entity.DebugEntity->GetRings().emplace_back(CRelativePosition+CVector3(0,0,0.10), fRadius, CColor::BLACK);
               s_tracked_entity.DebugEntity->GetRings().emplace_back(CRelativePosition+CVector3(0,0,0.10), fRadius-0.10, CColor::BLACK);
               s_tracked_entity.DebugEntity->GetRings().emplace_back(CRelativePosition+CVector3(0,0,0.20), fRadius, CColor::BLACK);
               s_tracked_entity.DebugEntity->GetRings().emplace_back(CRelativePosition+CVector3(0,0,0.20), fRadius-0.10, CColor::BLACK);
            }
         }

         // draw lines
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

            // draw Virtual Orientation and goal
            if (m_bDrawGoalFlag) {
               // Virtual Orientation
               Real fAxisLength = 0.15;
               CVector3 X = CVector3(fAxisLength*3, 0, 0);
               CVector3 Y = CVector3(0, fAxisLength*2, 0);
               CVector3 Z = CVector3(0, 0, fAxisLength*1.5);
               CColor cColor = CColor::GREEN;
               s_tracked_entity.DebugEntity->GetArrows().emplace_back(CVector3(0,0,0), X.Rotate(CVirtualOrientationQ), cColor);
               s_tracked_entity.DebugEntity->GetArrows().emplace_back(CVector3(0,0,0), Y.Rotate(CVirtualOrientationQ), cColor);
               s_tracked_entity.DebugEntity->GetArrows().emplace_back(CVector3(0,0,0), Z.Rotate(CVirtualOrientationQ), cColor);
               cColor = CColor::RED;
               // Goal Position
               CVector3 CGoalPositionV3InReal = CVector3(CGoalPositionV3).Rotate(CVirtualOrientationQ);
               s_tracked_entity.DebugEntity->GetArrows().emplace_back(CVector3(0,0,0), CGoalPositionV3InReal, cColor);
               // Goal Orientation
               CQuaternion CGoalOrientationQInReal = CVirtualOrientationQ * CGoalOrientationQ;
               X = CVector3(fAxisLength*3, 0, 0).Rotate(CGoalOrientationQInReal);
               Y = CVector3(0, fAxisLength*2, 0).Rotate(CGoalOrientationQInReal);
               Z = CVector3(0, 0, fAxisLength*1.5).Rotate(CGoalOrientationQInReal);
               s_tracked_entity.DebugEntity->GetArrows().emplace_back(CGoalPositionV3InReal, CGoalPositionV3InReal + X, cColor);
               s_tracked_entity.DebugEntity->GetArrows().emplace_back(CGoalPositionV3InReal, CGoalPositionV3InReal + Y, cColor);
               s_tracked_entity.DebugEntity->GetArrows().emplace_back(CGoalPositionV3InReal, CGoalPositionV3InReal + Z, cColor);
            }
         }

         if (vecWordList.size() >= 18) {
            std::string strParent = vecWordList[17];
            mapParent[ID] = strParent;
         }

         if ((vecWordList.size() > 18) && (m_bDrawDebugArrowsFlag == true)) {
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
                  if (m_bDrawTrackFlag == true) {
                     if (cColor == CColor::WHITE)
                        s_tracked_entity.DebugEntity->GetCustomizeArrows().emplace_back(cVecBegin, cVecEnd, CColor::BLACK, 0.05, 0.03, 1);
                     if (cColor == CColor::BLUE) {
                        s_tracked_entity.DebugEntity->GetCustomizeArrows().emplace_back(cVecBegin, cVecEnd, CColor::BLACK, 0.05, 0.03, 1);
                     }
                  }
                  else {
                     s_tracked_entity.DebugEntity->GetArrows().emplace_back(cVecBegin, cVecEnd, cColor);
                  }
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
               if (ParentID == "") continue;
               if (ParentID == "nil")
                  if (m_bDrawTrackFlag == true) {
                     s_tracked_entity.DebugEntity->GetRings().emplace_back(CVector3(0,0,0), 0.2, CColor::BLACK);
                     s_tracked_entity.DebugEntity->GetRings().emplace_back(CVector3(0,0,0), 0.21, CColor::BLACK);
                     s_tracked_entity.DebugEntity->GetRings().emplace_back(CVector3(0,0,0.01), 0.2, CColor::BLACK);
                     s_tracked_entity.DebugEntity->GetRings().emplace_back(CVector3(0,0,0.01), 0.21, CColor::BLACK);
                  }
                  else {
                     s_tracked_entity.DebugEntity->GetRings().emplace_back(CVector3(0,0,0), 0.2, CColor::BLUE);
                  }
               else {
                  CVector3 CRelativePosition = mapPosition[ParentID] - mapPosition[ID];
                  CRelativePosition.Rotate(mapOrientation[ID].Inverse());
                  if (m_bDrawTrackFlag == true) {
                     s_tracked_entity.DebugEntity->GetCustomizeArrows().emplace_back(CRelativePosition, CVector3(0,0,0), CColor::BLACK, 0.05, 0.05, 1);
                  }
                  else {
                     s_tracked_entity.DebugEntity->GetArrows().emplace_back(CRelativePosition, CVector3(0,0,0), CColor::BLUE);
                  }
               }
            }
         }
      }

      if ((m_vecDrawTrackKeyFrame.size() > 0) && (m_unStepCount == m_vecDrawTrackKeyFrame[0]))
         m_vecDrawTrackKeyFrame.erase(m_vecDrawTrackKeyFrame.begin());
      m_unStepCount++;
   }
   
   /****************************************/
   /****************************************/

   REGISTER_LOOP_FUNCTIONS(CReplayLoopFunctions, "replay_loop_functions");
}
