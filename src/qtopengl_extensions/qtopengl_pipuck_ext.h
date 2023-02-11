/**
 * @file <argos3/plugins/robots/pi-puck/simulator/qtopengl_pipuck_ext.h>
 *
 * @author Michael Allwright - <allsey87@gmail.com>
 */

#ifndef QTOPENGL_PIPUCK_EXT_H
#define QTOPENGL_PIPUCK_EXT_H

namespace argos {
   class CQTOpenGLPiPuckExt;
   class CPiPuckExtEntity;
}

#ifdef __APPLE__
#include <gl.h>
#else
#include <GL/gl.h>
#endif

#include <argos3/plugins/simulator/visualizations/qt-opengl/qtopengl_obj_model.h>

#include <array>

namespace argos {

   class CQTOpenGLPiPuckExt {

   public:

      CQTOpenGLPiPuckExt();

      virtual ~CQTOpenGLPiPuckExt();

      virtual void Draw(const CPiPuckExtEntity& c_entity);

   private:
      /* OBJ models */
      CQTOpenGLObjModel m_cPiPuckModel;
      CQTOpenGLObjModel m_cPiPuckWheelModel;
      
      /* The tag texture */
      static const std::array<std::array<GLfloat, 3>, 81> m_arrTagTexture;
      
      /* LED material overrides */
      static const std::array<GLfloat, 4> m_arrRingLedOffAmbientDiffuse;
      static const std::array<GLfloat, 4> m_arrRingLedOnAmbientDiffuse;
      static const std::array<GLfloat, 4> m_arrBodyLedOffAmbientDiffuse;
      static const std::array<GLfloat, 4> m_arrBodyLedOnAmbientDiffuse;
      static const std::array<GLfloat, 4> m_arrFrontLedOffAmbientDiffuse;
      static const std::array<GLfloat, 4> m_arrFrontLedOnAmbientDiffuse;
      
      /* Precompiled list for drawing tags */
      GLuint m_unTagList;

      /* Pointer to the LED material within the OBJ model */
      std::array<CQTOpenGLObjModel::SMaterial*, 8> m_arrRingLEDs;
      CQTOpenGLObjModel::SMaterial& m_sBodyLED;
      CQTOpenGLObjModel::SMaterial& m_sFrontLED;
   };
}

#endif
