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
      using TRingVec = std::vector<std::tuple<CVector3, Real, CColor> >;
      using TMessageVec = std::vector<std::string>;

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

      TRingVec& GetRings() {
         return m_vecRings;
      }

      TMessageVec& GetMessages() {
         return m_vecMessages;
      }

   private:
      TArrowVec m_vecArrows;
      TRingVec m_vecRings;
      TMessageVec m_vecMessages;
   };
}

#endif
