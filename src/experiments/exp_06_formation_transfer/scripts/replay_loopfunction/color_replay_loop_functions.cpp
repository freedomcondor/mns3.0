#include "color_replay_loop_functions.h"
#include "debug/debug_entity.h"

namespace argos {

   /****************************************/
   /****************************************/

   // Initialize static variables
   std::vector<CReplayLoopFunctions::STrackedEntity> CReplayLoopFunctions::m_vecTrackedEntities;
   std::map<std::string, UInt32> CReplayLoopFunctions::m_mapEntityIDTrackedEntityIndex;

   bool CReplayLoopFunctions::m_bDrawGoalFlag = false;
   bool CReplayLoopFunctions::m_bDrawDebugArrowsFlag = false;
   bool CReplayLoopFunctions::m_bDrawTrackFlag = false;
   UInt32 CReplayLoopFunctions::m_unDrawTrackEveryXStep = 1;
   std::vector<UInt32> CReplayLoopFunctions::m_vecDrawTrackKeyFrame;
   UInt32 CReplayLoopFunctions::m_unStepCount;

   bool CReplayLoopFunctions::m_bFinishSignal = false;

   /****************************************/
   /****************************************/

   void CReplayLoopFunctions::EntityMultiThreadIteration(CControllableEntity* cControllableEntity) {
      // Get tracked entity from cControllableEntity id
      STrackedEntity& s_tracked_entity = m_vecTrackedEntities[
         m_mapEntityIDTrackedEntityIndex[cControllableEntity->GetRootEntity().GetId()]
      ];

      // Get a line from log
      int bufferLength = 4096;
      char buff[bufferLength];
      if (!fgets(buff, bufferLength, s_tracked_entity.LogFile))
      {
         m_bFinishSignal = true;
         return;
      }
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
      // get Orientation
      if (vecWordList.size() >= 6) {
         CRadians CX, CY, CZ;
         CZ.FromValueInDegrees(std::stod(vecWordList[3]));
         CY.FromValueInDegrees(std::stod(vecWordList[4]));
         CX.FromValueInDegrees(std::stod(vecWordList[5]));
         COrientationQ.FromEulerAngles(CZ, CY, CX);
      }
      // move robot to the location
      s_tracked_entity.EmbodiedEntity->MoveTo(CPositionV3, COrientationQ, false, true);

      // record position into vecTrack, and if keyFrame, record into vecKeyFrame
      if (m_bDrawTrackFlag == true) {
         s_tracked_entity.vecTrack.push_back(CPositionV3);
      }
      if ((m_vecDrawTrackKeyFrame.size() > 0) && (m_unStepCount == m_vecDrawTrackKeyFrame[0]))
         s_tracked_entity.vecKeyFrame.emplace_back(CPositionV3);
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
          (m_unStepCount % m_unDrawTrackEveryXStep == 0) &&
          (s_tracked_entity.DebugEntity != NULL)) {
         for (STrackedEntity::SKeyFrame keyFrame : s_tracked_entity.vecKeyFrame) {
            CVector3 CRelativePosition = CVector3(keyFrame.PositionV3 - CPositionV3).Rotate(COrientationQ.Inverse());
            Real fRadius = 0.2;
            Real fThickness = 0.1;
            Real fHeight = 0.2;
            s_tracked_entity.DebugEntity->GetCustomizeRings().emplace_back(
               CRelativePosition,
               fRadius,
               CColor::BLACK,
               fThickness,
               fHeight,
               1
            );
         }
      }

      // draw Goal and virtal frame
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

      // TODO figure a way to record parent in parallel
      /*
      if (vecWordList.size() >= 18) {
         std::string strParent = vecWordList[17];
         mapParent[ID] = strParent;
      }
      */

      if ((vecWordList.size() > 18) && (m_bDrawDebugArrowsFlag == true)) {
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
            if (strDrawType == "customize_ring") {
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
               Real fThickness = std::stod(vecWordList[nCurrentIdx]);
               Real fHeight = std::stod(vecWordList[nCurrentIdx + 1]);
               Real fColorTransparent = std::stod(vecWordList[nCurrentIdx + 2]);
               s_tracked_entity.DebugEntity->GetCustomizeRings().emplace_back(cVecMiddle,
                                                                              fRadius,
                                                                              cColor,
                                                                              fThickness,
                                                                              fHeight,
                                                                              fColorTransparent);
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
            else if (strDrawType == "customize_arrow") {
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
               Real fBodyThickness = std::stod(vecWordList[nCurrentIdx]);
               Real fHeadThickness = std::stod(vecWordList[nCurrentIdx + 1]);
               Real fColorTransparent = std::stod(vecWordList[nCurrentIdx + 2]);
               s_tracked_entity.DebugEntity->GetCustomizeArrows().emplace_back(cVecBegin,
                                                                                 cVecEnd,
                                                                                 cColor,
                                                                                 fBodyThickness,
                                                                                 fHeadThickness,
                                                                                 fColorTransparent);
            }
            else if (strDrawType == "halo") {
               CVector3 cVecMiddle = CVector3(
                  std::stod(vecWordList[nCurrentIdx + 1]),
                  std::stod(vecWordList[nCurrentIdx + 2]),
                  std::stod(vecWordList[nCurrentIdx + 3])
               );
               Real fRadius = std::stod(vecWordList[nCurrentIdx + 4]);
               Real fHaloRadius = std::stod(vecWordList[nCurrentIdx + 5]);
               Real fMaxTransparency = std::stod(vecWordList[nCurrentIdx + 6]);
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
               s_tracked_entity.DebugEntity->GetHalos().emplace_back(cVecMiddle,
                                                                     fRadius,
                                                                     fHaloRadius,
                                                                     fMaxTransparency,
                                                                     cColor);
            }
            else {
               nCurrentIdx ++;
            }
         }
      }
   }

   /****************************************/
   /****************************************/

   void CReplayLoopFunctions::Init(TConfigurationNode& t_tree) {
      m_unStepCount = 0;
      /* from replay_input_folder.txt read log file folder and other flags */
      std::string strLogFolder = "./logs";
      std::ifstream infile("replay_input_folder.txt");
      std::string strDrawGoalFlag = "False";
      std::string strDrawDebugArrowsFlag = "False";
      std::string strDrawTrackFlag = "False";
      std::string strDrawTrackKeyFrame = "";
      /* read key frame */
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
      std::vector<CColor> vecDarkColorMap;
      std::vector<CColor> vecLightColorMap;
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
         vecDarkColorMap.push_back(CColor(r,g,b,255));
         vecLightColorMap.push_back(CColor(r,g,b,30));
      }

      /* create a vector of tracked entities */
      CEntity::TVector& tRootEntityVector = GetSpace().GetRootEntityVector();
      UInt16 unColorMapStepLength = std::floor(vecDarkColorMap.size() / tRootEntityVector.size());
      UInt16 unDarkColorEveryXRobots = std::floor(tRootEntityVector.size() / 5);
      UInt16 unColorMapIndex = 0;
      UInt16 unEntityCount = 0;
      for(CEntity* pc_entity : tRootEntityVector) {
         CComposableEntity* pcComposable = dynamic_cast<CComposableEntity*>(pc_entity);
         if(pcComposable == nullptr) {
            continue;
         }
         try {
            CEmbodiedEntity& cBody = pcComposable->GetComponent<CEmbodiedEntity>("body");
            CColor cColor = vecLightColorMap[unColorMapIndex];
            if (unEntityCount % unDarkColorEveryXRobots == 0)
               cColor = vecDarkColorMap[unColorMapIndex];
            try {
               CDebugEntity& cDebug = pcComposable->GetComponent<CDebugEntity>("debug");
               m_vecTrackedEntities.emplace_back(pc_entity, &cBody, &cDebug, strLogFolder, cColor);
            }
            catch(CARGoSException& ex) {
               m_vecTrackedEntities.emplace_back(pc_entity, &cBody, nullptr, strLogFolder, cColor);
            }

            m_mapEntityIDTrackedEntityIndex[pc_entity->GetId()] = unEntityCount;
            unEntityCount++;
            unColorMapIndex += unColorMapStepLength;
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
      GetSpace().IterateOverControllableEntities(EntityMultiThreadIteration);

      if (m_bFinishSignal == true)
         exit(0);

      if ((m_vecDrawTrackKeyFrame.size() > 0) && (m_unStepCount == m_vecDrawTrackKeyFrame[0]))
         m_vecDrawTrackKeyFrame.erase(m_vecDrawTrackKeyFrame.begin());
      m_unStepCount++;
   }

   /****************************************/
   /****************************************/

   REGISTER_LOOP_FUNCTIONS(CReplayLoopFunctions, "color_replay_loop_function");
}
