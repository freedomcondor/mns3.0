#ifndef MY_QTOPENGL_USER_FUNCTIONS_H
#define MY_QTOPENGL_USER_FUNCTIONS_H

namespace argos {
   class CMyQtOpenGLUserFunctions;
   class CDebugEntity;
   class CPiPuckExtEntity;
   class CDroneEntity;
   class CBuilderBotEntity;
   class CBlockEntity;
   struct SAnchor;
   class QMouseWheelEventHandler;
}

#include <argos3/plugins/simulator/visualizations/qt-opengl/qtopengl_user_functions.h>
#include <argos3/core/utility/datatypes/datatypes.h>

namespace argos {

   class CMyQtOpenGLUserFunctions : public QObject,
                                    public CQTOpenGLUserFunctions {
      Q_OBJECT

   public:
      CMyQtOpenGLUserFunctions();

      virtual ~CMyQtOpenGLUserFunctions() {}

      virtual void Init(TConfigurationNode& t_tree);

      virtual void EntityMoved(CEntity& c_entity,
                               const CVector3& c_old_pos,
                               const CVector3& c_new_pos);

      void Annotate(CBlockEntity& c_entity);
      void Annotate(CBuilderBotEntity& c_entity);
      void Annotate(CDroneEntity& c_entity);
      void Annotate(CPiPuckExtEntity& c_entity);
      void Annotate(CDebugEntity& c_debug_entity, const SAnchor& s_anchor);

   private:
      QMouseWheelEventHandler* m_pcMouseWheelEventHandler;

   private:
      void DrawArrow3(const CVector3& c_from, const CVector3& c_to);
      void DrawRing3(const CVector3& c_center, Real f_radius);

   };

   class QMouseWheelEventHandler : public QObject {
      Q_OBJECT
   public:
      QMouseWheelEventHandler(QObject* pc_parent,
                              CMyQtOpenGLUserFunctions* pc_user_functions) :
         QObject(pc_parent),
         m_pcUserFunctions(pc_user_functions) {}
   protected:
      bool eventFilter(QObject* pc_object, QEvent* pc_event);
   private:
      CMyQtOpenGLUserFunctions* m_pcUserFunctions;
   };

   struct CCachedShapes {
      public:
         static CCachedShapes& GetCachedShapes() {
            static CCachedShapes cInstance;
            return cInstance;
         }

         GLuint GetCylinder() const {
            return m_unCylinder;
         }

         GLuint GetCone() const {
            return m_unCone;
         }

         GLuint GetRing() const {
            return m_unRing;
         }

      private:
         CCachedShapes() {
            /* Reserve the needed display lists */
            m_unBaseList = glGenLists(3);
            /* References to the display lists */
            m_unCylinder = m_unBaseList;
            m_unCone     = m_unBaseList + 1;
            m_unRing     = m_unBaseList + 2;
            /* Make cylinder list */
            glNewList(m_unCylinder, GL_COMPILE);
            MakeCylinder();
            glEndList();
            /* Make cone list */
            glNewList(m_unCone, GL_COMPILE);
            MakeCone();
            glEndList();
            /* Make ring list */
            glNewList(m_unRing, GL_COMPILE);
            MakeRing();
            glEndList();
         }

         ~CCachedShapes() {
            glDeleteLists(m_unBaseList, 3);
         }

         void MakeCone();
         void MakeCylinder();
         void MakeRing();
   
         GLuint m_unBaseList;
         GLuint m_unCylinder;
         GLuint m_unCone;
         GLuint m_unRing;
      };
}
#endif
