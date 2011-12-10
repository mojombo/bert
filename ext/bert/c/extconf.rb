# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# warnings save lives
$CFLAGS << " -Wall "

# Give it a name
extension_name = 'decode'

# The destination
dir_config(extension_name)

# Do the work
create_makefile(extension_name)