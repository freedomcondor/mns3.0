#ifndef MY_LOOP_FUNCTIONS_H
#define MY_LOOP_FUNCTIONS_H

namespace argos {
   class CDebugEntity;
}

#include <fstream>

#include <argos3/core/simulator/loop_functions.h>
#include <argos3/plugins/robots/drone/simulator/drone_entity.h>
#include "pipuck_ext/pipuck_ext_entity.h"

namespace argos {

   class CMyLoopFunctions : public CLoopFunctions {
   public:

      CMyLoopFunctions() {}

      virtual ~CMyLoopFunctions() {}

      virtual void Init(TConfigurationNode& t_tree) override;

      virtual void PostStep() override;

   private:

      struct STrackedEntity {
         STrackedEntity(CEntity* pc_entity,
                        CEmbodiedEntity* pc_embodied_entity,
                        CDebugEntity* pc_debug_entity) :
            Entity(pc_entity),
            EmbodiedEntity(pc_embodied_entity),
            DebugEntity(pc_debug_entity),
            LogFile("logs/" + pc_entity->GetId() + ".log") {}
         CEntity* Entity;
         CEmbodiedEntity* EmbodiedEntity;
         CDebugEntity* DebugEntity;
         std::ofstream LogFile;
      };

      std::vector<STrackedEntity> m_vecTrackedEntities;
   };
}

#endif

