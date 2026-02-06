#==============================================================================
# Script Name:       setup.ps1
# Description:       Setup Intel SEP (System Event Profiler) environment variables
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 7, 2024
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Sets up Intel SEP environment for telemetry collection

.DESCRIPTION
  Initializes Intel System Event Profiler (SEP) environment variables required
  for EMON and other Intel performance monitoring tools used in the RBR
  telemetry collection framework.

.EXAMPLE
  .\setup.ps1
  Initializes Intel SEP environment variables

.NOTES
  Requires Intel SEP tools to be installed at the standard location
#>

. 'C:\Program Files (x86)\IntelSWTools\sep\sep_vars.ps1'
exit 0