#include "pipuck_ext_entity.h"

#include <argos3/core/simulator/simulator.h>
#include <argos3/core/simulator/entity/controllable_entity.h>
#include <argos3/core/simulator/entity/embodied_entity.h>
#include <argos3/core/utility/datatypes/color.h>

#include <argos3/plugins/simulator/entities/directional_led_equipped_entity.h>
#include <argos3/plugins/simulator/entities/radio_equipped_entity.h>
#include <argos3/plugins/simulator/entities/tag_equipped_entity.h>
#include <argos3/plugins/simulator/media/directional_led_medium.h>
#include <argos3/plugins/simulator/media/radio_medium.h>
#include <argos3/plugins/simulator/media/tag_medium.h>

#include <argos3/plugins/robots/pi-puck/simulator/pipuck_differential_drive_entity.h>

namespace argos {

   /****************************************/
   /****************************************/

   const CVector3 CPiPuckExtEntity::WIFI_OFFSET_POSITION = {0.0, 0.0, 0.05};
   const Real CPiPuckExtEntity::WIFI_TRANSMISSION_RANGE = 10.0;
   const CVector3 CPiPuckExtEntity::TAG_OFFSET_POSITION = {0.0, 0.0, 0.0685};
   const Real CPiPuckExtEntity::TAG_SIDE_LENGTH = 0.107;

   /****************************************/
   /****************************************/

   void CPiPuckExtEntity::Init(TConfigurationNode& t_tree) {
      try {
         /* initialize the base class */
         CComposableEntity::Init(t_tree);
         /* create and initialize the embodied entity */
         m_pcEmbodiedEntity = new CEmbodiedEntity(this);
         AddComponent(*m_pcEmbodiedEntity);
         m_pcEmbodiedEntity->Init(GetNode(t_tree, "body"));
         SAnchor& sOriginAnchor = m_pcEmbodiedEntity->GetOriginAnchor();
         /* create and enable additional anchors */
         m_pcEmbodiedEntity->AddAnchor("body",
                                       CVector3(0.0, 0.0, 0.00125),
                                       CQuaternion()).Enable();
         m_pcEmbodiedEntity->AddAnchor("left_wheel",
                                       CVector3(0.0, -0.0255, 0.02125),
                                       CQuaternion(CRadians::PI_OVER_TWO,
                                                   CVector3::X)).Enable();
         m_pcEmbodiedEntity->AddAnchor("right_wheel",
                                       CVector3(0.0, 0.0255, 0.02125),
                                       CQuaternion(-CRadians::PI_OVER_TWO,
                                                   CVector3::X)).Enable();
         /* create and initialize the differential drive entity */
         m_pcDifferentialDriveEntity
            = new CPiPuckDifferentialDriveEntity(this, "differential_drive_0");
         AddComponent(*m_pcDifferentialDriveEntity);
         m_pcDifferentialDriveEntity->Enable();
         /* create and initialize a radio equipped entity for the wifi */
         m_pcRadioEquippedEntity = new CRadioEquippedEntity(this, "radios_0");
         std::string strWifiMedium;
         GetNodeAttributeOrDefault(t_tree, "wifi_medium", strWifiMedium, strWifiMedium);
         if(!strWifiMedium.empty()) {
            CRadioMedium& cWifiRadioMedium =
               CSimulator::GetInstance().GetMedium<CRadioMedium>(strWifiMedium);
            m_pcRadioEquippedEntity->AddRadio("wifi",
                                              WIFI_OFFSET_POSITION,
                                              m_pcEmbodiedEntity->GetOriginAnchor(),
                                              cWifiRadioMedium,
                                              WIFI_TRANSMISSION_RANGE);
            m_pcRadioEquippedEntity->Enable();
         }
         AddComponent(*m_pcRadioEquippedEntity);
         /* create and initialize the directional LED equipped entity */
         m_pcDirectionalLEDEquippedEntity = new CDirectionalLEDEquippedEntity(this, "leds_0");
         m_pcDirectionalLEDEquippedEntity->AddLED("ring_led_0",
                                                  CVector3(0, 0, 0.025),
                                                  CQuaternion(),
                                                  sOriginAnchor,
                                                  CRadians::PI_OVER_THREE,
                                                  CColor::BLACK);
         m_pcDirectionalLEDEquippedEntity->AddLED("ring_led_1",
                                                  CVector3(0, 0, 0.025),
                                                  CQuaternion(), 
                                                  sOriginAnchor,
                                                  CRadians::PI_OVER_THREE,
                                                  CColor::BLACK);
         m_pcDirectionalLEDEquippedEntity->AddLED("ring_led_2",
                                                  CVector3(0, 0, 0.025),
                                                  CQuaternion(),
                                                  sOriginAnchor,
                                                  CRadians::PI_OVER_THREE,
                                                  CColor::BLACK);
         m_pcDirectionalLEDEquippedEntity->AddLED("ring_led_3",
                                                  CVector3(0, 0, 0.025),
                                                  CQuaternion(),
                                                  sOriginAnchor,
                                                  CRadians::PI_OVER_THREE,
                                                  CColor::BLACK);
         m_pcDirectionalLEDEquippedEntity->AddLED("ring_led_4",
                                                  CVector3(0, 0, 0.025),
                                                  CQuaternion(),
                                                  sOriginAnchor,
                                                  CRadians::PI_OVER_THREE,
                                                  CColor::BLACK);
         m_pcDirectionalLEDEquippedEntity->AddLED("ring_led_5",
                                                  CVector3(0, 0, 0.025),
                                                  CQuaternion(), 
                                                  sOriginAnchor,
                                                  CRadians::PI_OVER_THREE,
                                                  CColor::BLACK);
         m_pcDirectionalLEDEquippedEntity->AddLED("ring_led_6",
                                                  CVector3(0, 0, 0.025),
                                                  CQuaternion(),
                                                  sOriginAnchor,
                                                  CRadians::PI_OVER_THREE,
                                                  CColor::BLACK);
         m_pcDirectionalLEDEquippedEntity->AddLED("ring_led_7",
                                                  CVector3(0, 0, 0.025),
                                                  CQuaternion(),
                                                  sOriginAnchor,
                                                  CRadians::PI_OVER_THREE,
                                                  CColor::BLACK);
         m_pcDirectionalLEDEquippedEntity->AddLED("front_led",
                                                  CVector3(0, 0, 0.025),
                                                  CQuaternion(),
                                                  sOriginAnchor,
                                                  CRadians::PI_OVER_THREE,
                                                  CColor::BLACK);
         m_pcDirectionalLEDEquippedEntity->AddLED("body_led",
                                                  CVector3(0, 0, 0.025),
                                                  CQuaternion(),
                                                  sOriginAnchor,
                                                  CRadians::PI_OVER_THREE,
                                                  CColor::BLACK);
         std::string strLedMedium;
         GetNodeAttributeOrDefault(t_tree, "led_medium", strLedMedium, strLedMedium);
         if(!strLedMedium.empty()) {
            CDirectionalLEDMedium& cDirectionalLedMedium =
               CSimulator::GetInstance().GetMedium<CDirectionalLEDMedium>(strLedMedium);
            m_pcDirectionalLEDEquippedEntity->SetMedium(cDirectionalLedMedium);
            m_pcDirectionalLEDEquippedEntity->Enable();
         }
         AddComponent(*m_pcDirectionalLEDEquippedEntity);
         /* create and initialize the tags */
         m_pcTagEquippedEntity = new CTagEquippedEntity(this, "tags_0");
         m_pcTagEquippedEntity->AddTag("tag_0",
                                       TAG_OFFSET_POSITION,
                                       CQuaternion(),
                                       GetEmbodiedEntity().GetOriginAnchor(),
                                       CRadians::PI_OVER_THREE,
                                       TAG_SIDE_LENGTH,
                                       GetId());
         std::string strTagMedium;
         GetNodeAttributeOrDefault(t_tree, "tag_medium", strTagMedium, strTagMedium);
         if(!strTagMedium.empty()) {
            CTagMedium& cTagMedium =
               CSimulator::GetInstance().GetMedium<CTagMedium>(strTagMedium);
            m_pcTagEquippedEntity->SetMedium(cTagMedium);
            m_pcTagEquippedEntity->Enable();
         }
         AddComponent(*m_pcTagEquippedEntity);
         /* Create and initialize the controllable entity */
         m_pcControllableEntity = new CControllableEntity(this);
         AddComponent(*m_pcControllableEntity);
         m_pcControllableEntity->Init(GetNode(t_tree, "controller"));
         /* Update components */
         UpdateComponents();
      }
      catch(CARGoSException& ex) {
         THROW_ARGOSEXCEPTION_NESTED("Failed to initialize PiPuck", ex);
      }
   }

   /****************************************/
   /****************************************/

   void CPiPuckExtEntity::UpdateComponents() {
      /* update all components using base class method */
      CComposableEntity::UpdateComponents();
   }

   /****************************************/
   /****************************************/

   REGISTER_ENTITY(CPiPuckExtEntity,
                   "pipuck_ext",
                   "1.0",
                   "Pi-Puck Developer [pipuck.developer@example.com]",
                   "The Pi-Puck robot with custom extensions",
                   "<long_description>",
                   "<status>"
   );
   REGISTER_STANDARD_SPACE_OPERATIONS_ON_COMPOSABLE(CPiPuckExtEntity);

   /****************************************/
   /****************************************/

}
