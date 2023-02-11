
#include "../extensions/pipuck_ext/pipuck_ext_entity.h"
#include "qtopengl_pipuck_ext.h"
#include "qtopengl_pipuck_ext_models.h"

#include <argos3/core/utility/datatypes/color.h>
#include <argos3/core/utility/math/vector2.h>

#include <argos3/plugins/simulator/entities/directional_led_equipped_entity.h>
#include <argos3/plugins/simulator/entities/tag_equipped_entity.h>
#include <argos3/plugins/simulator/visualizations/qt-opengl/qtopengl_widget.h>

#include <array>

#define BODY_LED_INDEX 8
#define FRONT_LED_INDEX 9

namespace argos {

   /****************************************/
   /****************************************/

    CQTOpenGLPiPuckExt::CQTOpenGLPiPuckExt() :
      /* create the model */
      m_cPiPuckModel(PIPUCK_EXT_MTL, PIPUCK_EXT_OBJ),
      m_cPiPuckWheelModel("pipuck-wheel.obj"),
      m_arrRingLEDs {
         &m_cPiPuckModel.GetMaterial("Red-Ring-LED-0"),
         &m_cPiPuckModel.GetMaterial("Red-Ring-LED-1"),
         &m_cPiPuckModel.GetMaterial("Red-Ring-LED-2"),
         &m_cPiPuckModel.GetMaterial("Red-Ring-LED-3"),
         &m_cPiPuckModel.GetMaterial("Red-Ring-LED-4"),
         &m_cPiPuckModel.GetMaterial("Red-Ring-LED-5"),
         &m_cPiPuckModel.GetMaterial("Red-Ring-LED-6"),
         &m_cPiPuckModel.GetMaterial("Red-Ring-LED-7"),
      },
      m_sBodyLED(m_cPiPuckModel.GetMaterial("Green-Body-LEDs")),
      m_sFrontLED(m_cPiPuckModel.GetMaterial("Front-facing-Red-LED")) {
      /* generate the tag texture */
      GLuint unTagTex;
      glGenTextures(1, &unTagTex);
      glBindTexture(GL_TEXTURE_2D, unTagTex);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 9, 9, 0, GL_RGB, GL_FLOAT, m_arrTagTexture.data());
      /* draw normalized tag into list */
      m_unTagList = glGenLists(1);
      glNewList(m_unTagList, GL_COMPILE);
      glEnable(GL_NORMALIZE);
      glDisable(GL_LIGHTING);
      glEnable(GL_TEXTURE_2D);
      glBindTexture(GL_TEXTURE_2D, unTagTex);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
      glBegin(GL_QUADS);
      glNormal3f(0.0f, 0.0f, 1.0f);
      glTexCoord2f(1.0f, 1.0f); glVertex2f( 0.5f,  0.5f);
      glTexCoord2f(0.0f, 1.0f); glVertex2f(-0.5f,  0.5f);
      glTexCoord2f(0.0f, 0.0f); glVertex2f(-0.5f, -0.5f);
      glTexCoord2f(1.0f, 0.0f); glVertex2f( 0.5f, -0.5f);
      glEnd();
      glDisable(GL_TEXTURE_2D);
      glEnable(GL_LIGHTING);
      glDisable(GL_NORMALIZE);
      glEndList();
   }

   /****************************************/
   /****************************************/

   CQTOpenGLPiPuckExt::~CQTOpenGLPiPuckExt() {}

   /****************************************/
   /****************************************/

   void CQTOpenGLPiPuckExt::Draw(const CPiPuckExtEntity& c_entity) {
      /* Update LED materials */
      const CDirectionalLEDEquippedEntity& c_leds = c_entity.GetDirectionalLEDEquippedEntity();
      for(UInt32 un_ring_led_index = 0;
          un_ring_led_index < 8;
          un_ring_led_index++) {
         if(c_leds.GetLED(un_ring_led_index).GetColor() == CColor::BLACK) {
            m_arrRingLEDs[un_ring_led_index]->Diffuse = m_arrRingLedOffAmbientDiffuse;
            m_arrRingLEDs[un_ring_led_index]->Ambient = m_arrRingLedOffAmbientDiffuse;
         }
         else {
            m_arrRingLEDs[un_ring_led_index]->Diffuse = m_arrRingLedOnAmbientDiffuse;
            m_arrRingLEDs[un_ring_led_index]->Ambient = m_arrRingLedOnAmbientDiffuse;
         }
      }
      if(c_leds.GetLED(BODY_LED_INDEX).GetColor() == CColor::BLACK) {
         m_sBodyLED.Diffuse = m_arrBodyLedOffAmbientDiffuse;
         m_sBodyLED.Ambient = m_arrBodyLedOffAmbientDiffuse;
      }
      else {
         m_sBodyLED.Diffuse = m_arrBodyLedOnAmbientDiffuse;
         m_sBodyLED.Ambient = m_arrBodyLedOnAmbientDiffuse;
      }
      if(c_leds.GetLED(FRONT_LED_INDEX).GetColor() == CColor::BLACK) {
         m_sFrontLED.Diffuse = m_arrFrontLedOffAmbientDiffuse;
         m_sFrontLED.Ambient = m_arrFrontLedOffAmbientDiffuse;
      }
      else {
         m_sFrontLED.Diffuse = m_arrFrontLedOnAmbientDiffuse;
         m_sFrontLED.Ambient = m_arrFrontLedOnAmbientDiffuse;
      }
      CRadians cZAngle, cYAngle, cXAngle;
      /* draw the body */
      const SAnchor& sBodyAnchor = c_entity.GetEmbodiedEntity().GetAnchor("body");
      sBodyAnchor.Orientation.ToEulerAngles(cZAngle, cYAngle, cXAngle);
      glPushMatrix();
      glTranslatef(sBodyAnchor.Position.GetX(),
                   sBodyAnchor.Position.GetY(),
                   sBodyAnchor.Position.GetZ());
      glRotatef(ToDegrees(cXAngle).GetValue(), 1.0f, 0.0f, 0.0f);
      glRotatef(ToDegrees(cYAngle).GetValue(), 0.0f, 1.0f, 0.0f);
      glRotatef(ToDegrees(cZAngle).GetValue(), 0.0f, 0.0f, 1.0f);
      m_cPiPuckModel.Draw();
      /* draw tags */
      for(const CTagEquippedEntity::SInstance& s_instance :
          c_entity.GetTagEquippedEntity().GetInstances()) {
         /* the texture of the tag contains the white border which isn't actually part
            of the tag. Stretching the texture by 9/7ths fixes this problem */
         Real fScaling = s_instance.Tag.GetSideLength() * 14.0 / 10.7;
         const CVector3& cTagPosition = s_instance.PositionOffset;
         const CQuaternion& cTagOrientation = s_instance.OrientationOffset;
         cTagOrientation.ToEulerAngles(cZAngle, cYAngle, cXAngle);
         glPushMatrix();
         glTranslatef(cTagPosition.GetX(),
                      cTagPosition.GetY(),
                      cTagPosition.GetZ());
         glRotatef(ToDegrees(cXAngle).GetValue(), 1.0f, 0.0f, 0.0f);
         glRotatef(ToDegrees(cYAngle).GetValue(), 0.0f, 1.0f, 0.0f);
         glRotatef(ToDegrees(cZAngle).GetValue(), 0.0f, 0.0f, 1.0f);
         glScalef(fScaling, fScaling, 1.0f);
         glCallList(m_unTagList);
         glPopMatrix();
      }
      glPopMatrix();
      /* draw the left wheel */
      const SAnchor& sLeftWheelAnchor = c_entity.GetEmbodiedEntity().GetAnchor("left_wheel");
      sLeftWheelAnchor.Orientation.ToEulerAngles(cZAngle, cYAngle, cXAngle);
      glPushMatrix();
      glTranslatef(sLeftWheelAnchor.Position.GetX(),
                   sLeftWheelAnchor.Position.GetY(),
                   sLeftWheelAnchor.Position.GetZ());
      glRotatef(ToDegrees(cXAngle).GetValue(), 1.0f, 0.0f, 0.0f);
      glRotatef(ToDegrees(cYAngle).GetValue(), 0.0f, 1.0f, 0.0f);
      glRotatef(ToDegrees(cZAngle).GetValue(), 0.0f, 0.0f, 1.0f);
      m_cPiPuckWheelModel.Draw();
      glPopMatrix();
      /* draw the right wheel */
      const SAnchor& sRightWheelAnchor = c_entity.GetEmbodiedEntity().GetAnchor("right_wheel");
      sRightWheelAnchor.Orientation.ToEulerAngles(cZAngle, cYAngle, cXAngle);
      glPushMatrix();
      glTranslatef(sRightWheelAnchor.Position.GetX(),
                   sRightWheelAnchor.Position.GetY(),
                   sRightWheelAnchor.Position.GetZ());
      glRotatef(ToDegrees(cXAngle).GetValue(), 1.0f, 0.0f, 0.0f);
      glRotatef(ToDegrees(cYAngle).GetValue(), 0.0f, 1.0f, 0.0f);
      glRotatef(ToDegrees(cZAngle).GetValue(), 0.0f, 0.0f, 1.0f);
      m_cPiPuckWheelModel.Draw();
      glPopMatrix();
   }

   /****************************************/
   /****************************************/

   class CQTOpenGLOperationDrawPiPuckExtNormal : public CQTOpenGLOperationDrawNormal {
   public:
      void ApplyTo(CQTOpenGLWidget& c_visualization,
                   CPiPuckExtEntity& c_entity) {
         static CQTOpenGLPiPuckExt m_cModel;
         m_cModel.Draw(c_entity);
         c_visualization.DrawRays(c_entity.GetControllableEntity());
      }
   };

   /****************************************/
   /****************************************/

   class CQTOpenGLOperationDrawPiPuckExtSelected : public CQTOpenGLOperationDrawSelected {
   public:
      void ApplyTo(CQTOpenGLWidget& c_visualization,
                   CPiPuckExtEntity& c_entity) {
         c_visualization.DrawBoundingBox(c_entity.GetEmbodiedEntity());
      }
   };

   /****************************************/
   /****************************************/

   REGISTER_QTOPENGL_ENTITY_OPERATION(CQTOpenGLOperationDrawNormal, CQTOpenGLOperationDrawPiPuckExtNormal, CPiPuckExtEntity);

   REGISTER_QTOPENGL_ENTITY_OPERATION(CQTOpenGLOperationDrawSelected, CQTOpenGLOperationDrawPiPuckExtSelected, CPiPuckExtEntity);

   /****************************************/
   /****************************************/

#define TAG_WHITE std::array<GLfloat, 3> {1.0f, 1.0f, 1.0f}
#define TAG_BLACK std::array<GLfloat, 3> {0.0f, 0.0f, 0.0f}

   const std::array<std::array<GLfloat, 3>, 81> CQTOpenGLPiPuckExt::m_arrTagTexture {
      TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE,
      TAG_WHITE, TAG_BLACK, TAG_BLACK, TAG_BLACK, TAG_BLACK, TAG_BLACK, TAG_BLACK, TAG_BLACK, TAG_WHITE,
      TAG_WHITE, TAG_BLACK, TAG_BLACK, TAG_WHITE, TAG_BLACK, TAG_WHITE, TAG_BLACK, TAG_BLACK, TAG_WHITE,
      TAG_WHITE, TAG_BLACK, TAG_WHITE, TAG_BLACK, TAG_BLACK, TAG_BLACK, TAG_WHITE, TAG_BLACK, TAG_WHITE,
      TAG_WHITE, TAG_BLACK, TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_BLACK, TAG_WHITE, TAG_BLACK, TAG_WHITE,
      TAG_WHITE, TAG_BLACK, TAG_BLACK, TAG_WHITE, TAG_BLACK, TAG_WHITE, TAG_WHITE, TAG_BLACK, TAG_WHITE,
      TAG_WHITE, TAG_BLACK, TAG_WHITE, TAG_BLACK, TAG_WHITE, TAG_BLACK, TAG_WHITE, TAG_BLACK, TAG_WHITE,
      TAG_WHITE, TAG_BLACK, TAG_BLACK, TAG_BLACK, TAG_BLACK, TAG_BLACK, TAG_BLACK, TAG_BLACK, TAG_WHITE,
      TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE, TAG_WHITE,
   };

   const std::array<GLfloat, 4> CQTOpenGLPiPuckExt::m_arrRingLedOffAmbientDiffuse  {0.75f, 0.75f, 0.75f, 0.8f};
   const std::array<GLfloat, 4> CQTOpenGLPiPuckExt::m_arrRingLedOnAmbientDiffuse   {1.00f, 0.00f, 0.00f, 0.8f};
   const std::array<GLfloat, 4> CQTOpenGLPiPuckExt::m_arrBodyLedOffAmbientDiffuse  {0.75f, 0.75f, 0.75f, 0.7f};
   const std::array<GLfloat, 4> CQTOpenGLPiPuckExt::m_arrBodyLedOnAmbientDiffuse   {0.27f, 0.83f, 0.27f, 0.7f};
   const std::array<GLfloat, 4> CQTOpenGLPiPuckExt::m_arrFrontLedOffAmbientDiffuse {0.75f, 0.75f, 0.75f, 0.8f};
   const std::array<GLfloat, 4> CQTOpenGLPiPuckExt::m_arrFrontLedOnAmbientDiffuse  {1.00f, 0.00f, 0.00f, 0.8f};

   /****************************************/
   /****************************************/

}
