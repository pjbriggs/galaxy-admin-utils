# Galaxy toolbox filter
#
# This 'global' filter removes the specified section 
# from the tool panel for all users except those with
# the associated roles of 'Developer' and 'Tester'.
#
# See https://wiki.galaxyproject.org/UserDefinedToolboxFilters
#
# To deploy:
# 1. Put into lib/galaxy/tools/filters/ as e.g.
#    sections.py
# 2. Update the galaxy.ini file to add to the
#    'tool_section_filters' parameter, e.g.
#
#    tool_section_filters = sections:restrict_developmental
#
# Filter developmental tool section depending on user role
def restrict_developmental(context,section):
    """
    Display additional tool section for 'developmental' tools

    This tool filter will add a 'Developmental Tools' section
    to the tool panel (which includes versions of tools that
    are currently under development).

    Note that these tools are provided for test purposes only
    and should not be used for production work.

    """
    user = context.trans.user
    hidden_sections = ["Developmental Tools",]
    allowed_roles = ["Developer","Tester",]
    if section.name in hidden_sections:
        # Check user has allowed role
        for user_role in user.roles:
           if user_role.role.name in allowed_roles:
               return True
        # not found to have the role, return false
        return False
    # return true for any other tool
    return True
