#ifndef PIPUCK_ENTITY_H
#define PIPUCK_ENTITY_H

namespace argos {
   class CPiPuckDifferentialDriveEntity;
   class CControllableEntity;
   class CDirectionalLEDEquippedEntity;
   class CEmbodiedEntity;
   class CRadioEquippedEntity;
   class CTagEquippedEntity;
}

#include <argos3/core/simulator/entity/composable_entity.h>

namespace argos {

   class CPiPuckExtEntity : public CComposableEntity {

   public:

      ENABLE_VTABLE();

   public:

      CPiPuckExtEntity() :
         CComposableEntity(nullptr),
         m_pcControllableEntity(nullptr),
         m_pcEmbodiedEntity(nullptr),
         m_pcDifferentialDriveEntity(nullptr),
         m_pcRadioEquippedEntity(nullptr) {}

      virtual ~CPiPuckExtEntity() {}

      virtual void Init(TConfigurationNode& t_tree);

      inline CTagEquippedEntity& GetTagEquippedEntity() {
         return *m_pcTagEquippedEntity;
      }

      inline const CTagEquippedEntity& GetTagEquippedEntity() const {
         return *m_pcTagEquippedEntity;
      }

      virtual std::string GetTypeDescription() const {
         return "pipuck_ext";
      }
      
      inline CControllableEntity& GetControllableEntity() {
         return *m_pcControllableEntity;
      }

      inline CPiPuckDifferentialDriveEntity& GetDifferentialDriveEntity() {
         return *m_pcDifferentialDriveEntity;
      }

      inline const CPiPuckDifferentialDriveEntity& GetDifferentialDriveEntity() const {
         return *m_pcDifferentialDriveEntity;
      }

      inline CDirectionalLEDEquippedEntity& GetDirectionalLEDEquippedEntity() {
         return *m_pcDirectionalLEDEquippedEntity;
      }

      inline const CDirectionalLEDEquippedEntity& GetDirectionalLEDEquippedEntity() const {
         return *m_pcDirectionalLEDEquippedEntity;
      }

      inline CEmbodiedEntity& GetEmbodiedEntity() {
         return *m_pcEmbodiedEntity;
      }

      inline const CEmbodiedEntity& GetEmbodiedEntity() const {
         return *m_pcEmbodiedEntity;
      }

      inline CRadioEquippedEntity& GetRadioEquippedEntity() {
         return *m_pcRadioEquippedEntity;
      }

      inline const CRadioEquippedEntity& GetRadioEquippedEntity() const {
         return *m_pcRadioEquippedEntity;
      }

      virtual void UpdateComponents();

   private:

      CControllableEntity*            m_pcControllableEntity;
      CDirectionalLEDEquippedEntity*  m_pcDirectionalLEDEquippedEntity;
      CEmbodiedEntity*                m_pcEmbodiedEntity;
      CPiPuckDifferentialDriveEntity* m_pcDifferentialDriveEntity;
      CRadioEquippedEntity*           m_pcRadioEquippedEntity;
      CTagEquippedEntity*             m_pcTagEquippedEntity;

      static const CVector3 WIFI_OFFSET_POSITION;
      static const Real     WIFI_TRANSMISSION_RANGE;
      static const CVector3 TAG_OFFSET_POSITION;
      static const Real     TAG_SIDE_LENGTH;
   };

}

#endif
