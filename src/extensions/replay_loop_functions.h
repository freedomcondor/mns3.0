#ifndef MY_LOOP_FUNCTIONS_H
#define MY_LOOP_FUNCTIONS_H

namespace argos {
   class CDebugEntity;
}

//#include <fstream>
#include <stdlib.h>

#include <argos3/core/simulator/loop_functions.h>
#include <argos3/plugins/robots/drone/simulator/drone_entity.h>
#include "pipuck_ext/pipuck_ext_entity.h"
#include "../qtopengl_extensions/my_qtopengl_user_functions.h"

namespace argos {

   class CReplayLoopFunctions : public CLoopFunctions {
   public:

      CReplayLoopFunctions() {}

      virtual ~CReplayLoopFunctions() {}

      virtual void Init(TConfigurationNode& t_tree) override;

      virtual void PreStep() override;

   private:

      struct STrackedEntity {
         STrackedEntity(CEntity* pc_entity,
                        CEmbodiedEntity* pc_embodied_entity,
                        CDebugEntity* pc_debug_entity,
                        std::string str_log_folder) :
            Entity(pc_entity),
            EmbodiedEntity(pc_embodied_entity),
            //LogFile(str_log_folder + "/" + pc_entity->GetId() + ".log") {}
            DebugEntity(pc_debug_entity) {
               LogFile = fopen((str_log_folder + "/" + pc_entity->GetId() + ".log").c_str(), "r");
            }
         CEntity* Entity;
         CEmbodiedEntity* EmbodiedEntity;
         CDebugEntity* DebugEntity;
         //std::ifstream LogFile; // too slow
         FILE *LogFile;
      };

      std::vector<STrackedEntity> m_vecTrackedEntities;
   };
}

#endif

