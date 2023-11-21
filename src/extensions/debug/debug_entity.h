#ifndef DEBUG_ENTITY_H
#define DEBUG_ENTITY_H

namespace argos {
   class CDebugDefaultActuator;
}

#include <argos3/core/simulator/entity/composable_entity.h>
#include <argos3/core/utility/datatypes/color.h>

namespace argos {

   class CDebugEntity : public CEntity {
   friend class CDebugDefaultActuator;
   public:
      ENABLE_VTABLE();

   public:
      using TArrowVec = std::vector<std::tuple<CVector3, CVector3, CColor> >;
      using TCustomizeArrowVec = std::vector<std::tuple<CVector3, CVector3, CColor, Real, Real, Real> >; // bodyThickness, HeadThickness, ColorTransparent
      using TRingVec = std::vector<std::tuple<CVector3, Real, CColor> >;
      using TCustomizeRingVec = std::vector<std::tuple<CVector3, Real, CColor, Real, Real, Real> >; // Thickness, Height, ColorTransparent
      using TMessageVec = std::vector<std::string>;
      using THaloVec = std::vector<std::tuple<CVector3, Real, Real, Real, CColor> >; // Position, Radius, HaloRadius, MaxTransparency

      CDebugEntity(CComposableEntity* pc_parent,
                   const std::string& str_id) :
         CEntity(pc_parent, str_id) {}

      virtual ~CDebugEntity() {}

      virtual std::string GetTypeDescription() const {
         return "debug";
      }

      TArrowVec& GetArrows() {
         return m_vecArrows;
      }

      TCustomizeArrowVec& GetCustomizeArrows() {
         return m_vecCustomizeArrows;
      }

      TRingVec& GetRings() {
         return m_vecRings;
      }

      TCustomizeRingVec& GetCustomizeRings() {
         return m_vecCustomizeRings;
      }

      THaloVec& GetHalos() {
         return m_vecHalos;
      }

      TMessageVec& GetMessages() {
         return m_vecMessages;
      }

   private:
      TArrowVec m_vecArrows;
      TCustomizeArrowVec m_vecCustomizeArrows;
      TRingVec m_vecRings;
      TCustomizeRingVec m_vecCustomizeRings;
      THaloVec m_vecHalos;
      TMessageVec m_vecMessages;
   };
}

#endif
