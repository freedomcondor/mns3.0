mtl_file="pipuck.mtl"
obj_file="pipuck.obj"
output_file="qtopengl_pipuck_ext_models.h"

header_1='''#ifndef QTOPENGL_PIPUCK_EXT_MODELS
#define QTOPENGL_PIPUCK_EXT_MODELS

const char* PIPUCK_EXT_MTL = R"""(
'''

header_2=''')""";

const char* PIPUCK_EXT_OBJ = R"""(
'''

header_3=''')""";

#endif
'''

echo "$header_1" > $output_file
cat $mtl_file >> $output_file
echo "$header_2" >> $output_file
cat $obj_file >> $output_file
echo "$header_3" >> $output_file