# Galaxy toolbox filter
#
# Only show metagenomics tools
def only_metagenomics(context,section):
    """Only display tool section for metagenomics analyses

    This tool filter will hide all tools except those under sections
    that are directly relevant to metagenomics analyses.

    """
    metagenomics_section_names = ['Metagenomic analyses',
                                  'Metagenomics: Mothur',]
    return section.name in metagenomics_section_names
