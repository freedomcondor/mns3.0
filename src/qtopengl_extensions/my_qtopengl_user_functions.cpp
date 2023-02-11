
#include "my_qtopengl_user_functions.h"

#include <argos3/core/simulator/simulator.h>
#include <argos3/core/simulator/space/space.h>
#include <argos3/core/simulator/entity/composable_entity.h>

#include <argos3/plugins/robots/block/simulator/block_entity.h>
#include <argos3/plugins/robots/builderbot/simulator/builderbot_entity.h>
#include <argos3/plugins/robots/drone/simulator/drone_entity.h>
#include "../extensions/pipuck_ext/pipuck_ext_entity.h"
#include "../extensions/debug/debug_entity.h"

#include <argos3/plugins/simulator/visualizations/qt-opengl/qtopengl_render.h>
#include <argos3/plugins/simulator/visualizations/qt-opengl/qtopengl_main_window.h>

#include <QWheelEvent>

#define GL_NUMBER_VERTICES 36u
#define BLOCK_SIDE_LENGTH 0.055
#define DELTA_Z 0.0005

namespace argos {

   /****************************************/
   /****************************************/

   bool QMouseWheelEventHandler::eventFilter(QObject* pc_object, QEvent* pc_event) {
      if (pc_event->type() != QEvent::Wheel) {
         return QObject::eventFilter(pc_object, pc_event);
      }
      QWheelEvent *pcWheelEvent = static_cast<QWheelEvent*>(pc_event);
      if(!(pcWheelEvent->modifiers() & Qt::ControlModifier)) {
         return QObject::eventFilter(pc_object, pc_event);
      }
      CEntity* pcEntity = m_pcUserFunctions->GetSelectedEntity();
      if(pcEntity == nullptr) {
         return QObject::eventFilter(pc_object, pc_event);
      }
      CBuilderBotEntity* pcBuilderBotEntity = dynamic_cast<CBuilderBotEntity*>(pcEntity);
      if(pcBuilderBotEntity == nullptr) {
         return QObject::eventFilter(pc_object, pc_event);
      }
      CEmbodiedEntity& cBuilderBotEmbodiedEntity = pcBuilderBotEntity->GetEmbodiedEntity();
      const SAnchor& sBuilderBotOriginAnchor = cBuilderBotEmbodiedEntity.GetOriginAnchor();
      const SAnchor& sBuilderBotEndEffectorAnchor = cBuilderBotEmbodiedEntity.GetAnchor("end_effector");
      /* get the target position of a block */
      CVector3 cTargetBlockPos(sBuilderBotEndEffectorAnchor.Position);
      cTargetBlockPos -= (CVector3::Z * BLOCK_SIDE_LENGTH);
      try {
         std::map<std::string, CAny>& mapBlockEntities =
            CSimulator::GetInstance().GetSpace().GetEntitiesByType("block");
         for(const std::pair<const std::string, CAny>& c_block : mapBlockEntities) {
            CEmbodiedEntity& cBlockEmbodiedEntity =
               any_cast<CBlockEntity*>(c_block.second)->GetEmbodiedEntity();
            const SAnchor& sBlockOriginAnchor = cBlockEmbodiedEntity.GetOriginAnchor();
            if(Distance(cTargetBlockPos, sBlockOriginAnchor.Position) < 0.005) {
               /* we have found our block, save its position and move it to just below the floor */
               const CVector3 cBlockInitPosition(sBlockOriginAnchor.Position);
               const CQuaternion cBlockInitOrientation(sBlockOriginAnchor.Orientation);
               const CVector3 cBuilderBotInitPosition(sBuilderBotOriginAnchor.Position);
               const CQuaternion cBuilderBotInitOrientation(sBuilderBotOriginAnchor.Orientation);
               // step one: move the block to a temporary position */
               CVector3 cBlockTempPosition(cBlockInitPosition);
               cBlockTempPosition.SetZ(-2.0 * BLOCK_SIDE_LENGTH);
               if(cBlockEmbodiedEntity.MoveTo(cBlockTempPosition,
                                              sBlockOriginAnchor.Orientation)) {
                  CDegrees cDegrees(pcWheelEvent->angleDelta().y() / 8);
                  CQuaternion cRotation(ToRadians(cDegrees), CVector3::Z);
                  // step two: rotate the builderbot
                  if(cBuilderBotEmbodiedEntity.MoveTo(cBuilderBotInitPosition,
                                                      cBuilderBotInitOrientation * cRotation)) {
                     // step three: rotate and translate the block
                     CVector3 cBlockNewPosition(cBlockInitPosition - cBuilderBotInitPosition);
                     cBlockNewPosition.Rotate(cRotation);
                     cBlockNewPosition += cBuilderBotInitPosition;
                     Real fBlockEndEffectorDistance =
                        Distance(cBlockNewPosition, sBuilderBotEndEffectorAnchor.Position);
                     if(fBlockEndEffectorDistance < BLOCK_SIDE_LENGTH + DELTA_Z) {
                        cBlockNewPosition -= (CVector3::Z * DELTA_Z);
                     }
                     CQuaternion cBlockNewOrientation(cBlockInitOrientation * cRotation);
                     if(cBlockEmbodiedEntity.MoveTo(cBlockNewPosition,
                                                    cBlockNewOrientation)) {
                        m_pcUserFunctions->GetQTOpenGLWidget().update();
                        return true;
                     }
                  }
               }
               cBuilderBotEmbodiedEntity.MoveTo(cBuilderBotInitPosition, cBuilderBotInitOrientation);
               cBlockEmbodiedEntity.MoveTo(cBlockInitPosition, cBlockInitOrientation);
               return true;
            }
         }
      }
      catch(CARGoSException& ex) {}
      return QObject::eventFilter(pc_object, pc_event);
   }

   /****************************************/
   /****************************************/

   CMyQtOpenGLUserFunctions::CMyQtOpenGLUserFunctions() {
      RegisterUserFunction<CMyQtOpenGLUserFunctions, CBlockEntity>(&CMyQtOpenGLUserFunctions::Annotate);
      RegisterUserFunction<CMyQtOpenGLUserFunctions, CBuilderBotEntity>(&CMyQtOpenGLUserFunctions::Annotate);
      RegisterUserFunction<CMyQtOpenGLUserFunctions, CPiPuckExtEntity>(&CMyQtOpenGLUserFunctions::Annotate);
      RegisterUserFunction<CMyQtOpenGLUserFunctions, CDroneEntity>(&CMyQtOpenGLUserFunctions::Annotate);
   }

   /****************************************/
   /****************************************/

   void CMyQtOpenGLUserFunctions::Init(TConfigurationNode& t_tree) {
      /* install the mouse wheel event handler */
      m_pcMouseWheelEventHandler =
         new QMouseWheelEventHandler(&GetQTOpenGLWidget(), this);
      GetQTOpenGLWidget().installEventFilter(m_pcMouseWheelEventHandler);
   }

   /****************************************/
   /****************************************/

   void CMyQtOpenGLUserFunctions::EntityMoved(CEntity& c_entity,
                                              const CVector3& c_old_pos,
                                              const CVector3& c_new_pos) {
      /* was a builderbot moved? */
      CBuilderBotEntity* pcBuilderBot = dynamic_cast<CBuilderBotEntity*>(&c_entity);
      if(pcBuilderBot == nullptr) {
         return;
      }
      /* at this point the end effector of the robot has already been moved,
         so we need to figure out where it was */
      const SAnchor& sEndEffectorAnchor =
         pcBuilderBot->GetEmbodiedEntity().GetAnchor("end_effector");
      CVector3 cDeltaPos(c_new_pos - c_old_pos);
      CVector3 cOldEndEffectorPos(sEndEffectorAnchor.Position - cDeltaPos);
      /* get the potential position of a block */
      CVector3 cBlockTestPos(cOldEndEffectorPos - CVector3::Z * BLOCK_SIDE_LENGTH);
      try {
         std::map<std::string, CAny>& mapBlockEntities =
            CSimulator::GetInstance().GetSpace().GetEntitiesByType("block");
         for(const std::pair<const std::string, CAny>& c_block : mapBlockEntities) {
            CEmbodiedEntity& cEmbodiedEntity =
               any_cast<CBlockEntity*>(c_block.second)->GetEmbodiedEntity();
            const SAnchor& sBlockAnchor = cEmbodiedEntity.GetOriginAnchor();
            /* if the origin of a block is within 0.005 meters of where
               we expected to find a block, move it */
            if(Distance(cBlockTestPos, sBlockAnchor.Position) < 0.005) {
               /* here, we drop the blocks position by 0.0005 meters to compensate for
                  inaccuracies in the physics engine */
               cEmbodiedEntity.MoveTo(sBlockAnchor.Position + cDeltaPos - (CVector3::Z * 0.0005),
                                      sBlockAnchor.Orientation);
               return;
            }
         }
      }
      catch(CARGoSException& ex) {}
   }

   /****************************************/
   /****************************************/

   void CMyQtOpenGLUserFunctions::Annotate(CDroneEntity& c_entity) {
      try {
         CDebugEntity& cDebugEntity =
            c_entity.GetComponent<CDebugEntity>("debug");
         Annotate(cDebugEntity, c_entity.GetEmbodiedEntity().GetOriginAnchor());
      }
      catch(CARGoSException& ex) {}
   }

   /****************************************/
   /****************************************/

   void CMyQtOpenGLUserFunctions::Annotate(CPiPuckExtEntity& c_entity) {
      try {
         CDebugEntity& cDebugEntity =
            c_entity.GetComponent<CDebugEntity>("debug");
         Annotate(cDebugEntity, c_entity.GetEmbodiedEntity().GetOriginAnchor());
      }
      catch(CARGoSException& ex) {}
   }

   /****************************************/
   /****************************************/

   void CMyQtOpenGLUserFunctions::Annotate(CBuilderBotEntity& c_entity) {
      try {
         CDebugEntity& cDebugEntity =
            c_entity.GetComponent<CDebugEntity>("debug");
         Annotate(cDebugEntity, c_entity.GetEmbodiedEntity().GetOriginAnchor());
      }
      catch(CARGoSException& ex) {}
   }

   /****************************************/
   /****************************************/

   void CMyQtOpenGLUserFunctions::Annotate(CBlockEntity& c_entity) {
      try {
         CDebugEntity& cDebugEntity =
            c_entity.GetComponent<CDebugEntity>("debug");
         Annotate(cDebugEntity, c_entity.GetEmbodiedEntity().GetOriginAnchor());
      }
      catch(CARGoSException& ex) {}
   }

   /****************************************/
   /****************************************/
   
   void CMyQtOpenGLUserFunctions::Annotate(CDebugEntity& c_debug_entity,
                                           const SAnchor& s_anchor) {
      glDisable(GL_LIGHTING);
      glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      const CVector3& cPosition = s_anchor.Position;
      const CQuaternion& cOrientation = s_anchor.Orientation;
      CRadians cZAngle, cYAngle, cXAngle;
      cOrientation.ToEulerAngles(cZAngle, cYAngle, cXAngle);
      glPushMatrix();
      glTranslatef(cPosition.GetX(), cPosition.GetY(), cPosition.GetZ());
      glRotatef(ToDegrees(cXAngle).GetValue(), 1.0f, 0.0f, 0.0f);
      glRotatef(ToDegrees(cYAngle).GetValue(), 0.0f, 1.0f, 0.0f);
      glRotatef(ToDegrees(cZAngle).GetValue(), 0.0f, 0.0f, 1.0f);
      for(const auto& t_arrow : c_debug_entity.GetArrows()) {
         const CVector3& cFrom = std::get<0>(t_arrow);
         const CVector3& cTo = std::get<1>(t_arrow);
         const CColor& cColor = std::get<2>(t_arrow);
         glColor4ub(cColor.GetRed(), cColor.GetGreen(), cColor.GetBlue(), 128u);
         DrawArrow3(cFrom, cTo);
      }
      for(const auto& t_ring : c_debug_entity.GetRings()) {
         const CVector3& cCenter = std::get<0>(t_ring);
         const Real& fRadius = std::get<1>(t_ring);
         const CColor& cColor = std::get<2>(t_ring);
         glColor4ub(cColor.GetRed(), cColor.GetGreen(), cColor.GetBlue(), 128u);
         DrawRing3(cCenter, fRadius);
      }
      glPopMatrix();
      glDisable(GL_BLEND);
      glEnable(GL_LIGHTING);
   }

   /****************************************/
   /****************************************/

   void CMyQtOpenGLUserFunctions::DrawRing3(const CVector3& c_center, Real f_radius) {
      const CCachedShapes& cCachedShapes = CCachedShapes::GetCachedShapes();
      const Real fRingHeight = 0.015625 * 2;
      const Real fRingThickness = 0.015625 * 2;
      const Real fHalfRingThickness = fRingThickness * 0.5;
      const Real fDiameter = 2.0 * f_radius;
      /* draw inner ring surface */
      glPushMatrix();
      glTranslatef(c_center.GetX(), c_center.GetY(), c_center.GetZ());
      glScalef(fDiameter, fDiameter, fRingHeight);
      glCallList(cCachedShapes.GetRing());
      glPopMatrix();
      /* draw outer ring surface */
      glPushMatrix();
      glTranslatef(c_center.GetX(), c_center.GetY(), c_center.GetZ());
      glScalef(fDiameter + fRingThickness, fDiameter + fRingThickness, fRingHeight);
      glCallList(cCachedShapes.GetRing());
      glPopMatrix();
      /* draw top */
      glPushMatrix();
      glTranslatef(c_center.GetX(), c_center.GetY(), c_center.GetZ());
      CVector2 cInnerVertex(f_radius, 0.0f);
      CVector2 cOuterVertex(f_radius + fHalfRingThickness, 0.0f);
      const CRadians cAngle(CRadians::TWO_PI / GL_NUMBER_VERTICES);
      glBegin(GL_QUAD_STRIP);
      glNormal3f(0.0f, 0.0f, 1.0f);
      for(GLuint i = 0; i <= GL_NUMBER_VERTICES; i++) {
         glVertex3f(cInnerVertex.GetX(), cInnerVertex.GetY(), fRingHeight);
         glVertex3f(cOuterVertex.GetX(), cOuterVertex.GetY(), fRingHeight);
         cInnerVertex.Rotate(cAngle);
         cOuterVertex.Rotate(cAngle);
      }
      glEnd();
      glPopMatrix();
   }

   /****************************************/
   /****************************************/

   void CMyQtOpenGLUserFunctions::DrawArrow3(const CVector3& c_from, const CVector3& c_to) {
      const CCachedShapes& cCachedShapes = CCachedShapes::GetCachedShapes();
      const Real fArrowThickness = 0.015625f * 2;
      const Real fArrowHead =      0.031250f * 2.5;
      CVector3 cArrow(c_to - c_from);
      CQuaternion cRotation(CVector3::Z, cArrow / cArrow.Length());
      CRadians cZAngle, cYAngle, cXAngle;
      cRotation.ToEulerAngles(cZAngle, cYAngle, cXAngle);
      /* draw arrow body */
      glPushMatrix();
      glTranslatef(c_to.GetX(), c_to.GetY(), c_to.GetZ());
      glRotatef(ToDegrees(cXAngle).GetValue(), 1.0f, 0.0f, 0.0f);
      glRotatef(ToDegrees(cYAngle).GetValue(), 0.0f, 1.0f, 0.0f);
      glRotatef(ToDegrees(cZAngle).GetValue(), 0.0f, 0.0f, 1.0f);
      glScalef(fArrowHead, fArrowHead, fArrowHead);
      glCallList(cCachedShapes.GetCone());
      glPopMatrix();
      /* draw arrow head */
      glPushMatrix();
      glTranslatef(c_from.GetX(), c_from.GetY(), c_from.GetZ());
      glRotatef(ToDegrees(cXAngle).GetValue(), 1.0f, 0.0f, 0.0f);
      glRotatef(ToDegrees(cYAngle).GetValue(), 0.0f, 1.0f, 0.0f);
      glRotatef(ToDegrees(cZAngle).GetValue(), 0.0f, 0.0f, 1.0f);
      glScalef(fArrowThickness, fArrowThickness, cArrow.Length() - fArrowHead);
      glCallList(cCachedShapes.GetCylinder());
      glPopMatrix();
   }

   /****************************************/
   /****************************************/

   void CCachedShapes::MakeCylinder() {
      /* Side surface */
      CVector2 cVertex(0.5f, 0.0f);
      CRadians cAngle(CRadians::TWO_PI / GL_NUMBER_VERTICES);
      glBegin(GL_QUAD_STRIP);
      for(GLuint i = 0; i <= GL_NUMBER_VERTICES; i++) {
         glNormal3f(cVertex.GetX(), cVertex.GetY(), 0.0f);
         glVertex3f(cVertex.GetX(), cVertex.GetY(), 1.0f);
         glVertex3f(cVertex.GetX(), cVertex.GetY(), 0.0f);
         cVertex.Rotate(cAngle);
      }
      glEnd();
      /* Top disk */
      cVertex.Set(0.5f, 0.0f);
      glBegin(GL_POLYGON);
      glNormal3f(0.0f, 0.0f, 1.0f);
      for(GLuint i = 0; i <= GL_NUMBER_VERTICES; i++) {
         glVertex3f(cVertex.GetX(), cVertex.GetY(), 1.0f);
         cVertex.Rotate(cAngle);
      }
      glEnd();
      /* Bottom disk */
      cVertex.Set(0.5f, 0.0f);
      cAngle = -cAngle;
      glBegin(GL_POLYGON);
      glNormal3f(0.0f, 0.0f, -1.0f);
      for(GLuint i = 0; i <= GL_NUMBER_VERTICES; i++) {
         glVertex3f(cVertex.GetX(), cVertex.GetY(), 0.0f);
         cVertex.Rotate(cAngle);
      }
      glEnd();
   }

   /****************************************/
   /****************************************/

   void CCachedShapes::MakeCone() {
      /* Cone surface */
      CVector2 cVertex(0.5f, 0.0f);
      CRadians cAngle(CRadians::TWO_PI / GL_NUMBER_VERTICES);
      glBegin(GL_QUAD_STRIP);
      for(GLuint i = 0; i <= GL_NUMBER_VERTICES; i++) {
         glNormal3f(cVertex.GetX(), cVertex.GetY(), 0.0f);
         glVertex3f(0.0f, 0.0f, 0.0f);
         glVertex3f(cVertex.GetX(), cVertex.GetY(), -1.0f);
         cVertex.Rotate(cAngle);
      }
      glEnd();
      /* Bottom disk */
      cVertex.Set(0.5f, 0.0f);
      cAngle = -cAngle;
      glBegin(GL_POLYGON);
      glNormal3f(0.0f, 0.0f, -1.0f);
      for(GLuint i = 0; i <= GL_NUMBER_VERTICES; i++) {
         glVertex3f(cVertex.GetX(), cVertex.GetY(), -1.0f);
         cVertex.Rotate(cAngle);
      }
      glEnd();
   }

   /****************************************/
   /****************************************/

   void CCachedShapes::MakeRing() {
      CVector2 cVertex;
      const CRadians cAngle(CRadians::TWO_PI / GL_NUMBER_VERTICES);
      /* draw front surface */
      cVertex.Set(0.5f, 0.0f);     
      glBegin(GL_QUAD_STRIP);
      for(GLuint i = 0; i <= GL_NUMBER_VERTICES; i++) {
         glNormal3f(cVertex.GetX(), cVertex.GetY(), 0.0f);
         glVertex3f(cVertex.GetX(), cVertex.GetY(), 1.0f);
         glVertex3f(cVertex.GetX(), cVertex.GetY(), 0.0f);
         cVertex.Rotate(cAngle);
      }
      glEnd();
      /* draw back surface */
      cVertex.Set(0.5f, 0.0f);     
      glBegin(GL_QUAD_STRIP);
      for(GLuint i = 0; i <= GL_NUMBER_VERTICES; i++) {
         glNormal3f(cVertex.GetX(), cVertex.GetY(), 0.0f);
         glVertex3f(cVertex.GetX(), cVertex.GetY(), 0.0f);
         glVertex3f(cVertex.GetX(), cVertex.GetY(), 1.0f);
         cVertex.Rotate(cAngle);
      }
      glEnd();
   }

   /****************************************/
   /****************************************/

   REGISTER_QTOPENGL_USER_FUNCTIONS(CMyQtOpenGLUserFunctions, "my_qtopengl_user_functions");

   /****************************************/
   /****************************************/

}
