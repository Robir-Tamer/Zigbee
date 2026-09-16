#--------------------------------------------------------------------------------------------------------------------#
# Aouther     : David Sameeh                                                                                         #
# Script Name : save_Tx_out.tcl                                                                                      #
# Simulator   : Questa Sim / ModelSim (Tcl transcript)                                                               #
#                                                                                                                    #
# Purpose:                                                                                                           #
#       Dumps the Tx real/imaginary memory contents inistantiated in TestBeanch to plain-text output files,          #
#       one 8-bit word per line, then cleans each file by stripping the leading header comment lines and any         #
#       trailing uninitialized "xxxx..." words left at the tail of the memory (unwritten addresses).                 #
#                                                                                                                    #
# How it works:                                                                                                      #
#       1. Locates the "rtl_tx_real" and "rtl_tx_imag" memories automatically anywhere in the simulation             #
#          hierarchy using "mem list -r /", so no hard-coded instance path is required.                              #
#       2. Exports each memory with the built-in "mem save" command (binary word format, no address column).         #
#       3. Post-processes each output file: removes up to 3 leading comment lines and trims trailing all-X lines.    #                                                                                                                      --#
# Usage:                                                                                                             #
#       From the Questa Sim / ModelSim transcript (or a "do" script), run:                                           #
#           do save_Tx_out.tcl <description>                                                                         #
#                                                                                                                    #
#       Argument (optional):                                                                                         #
#         <description>  - A short tag appended to the output filenames (e.g. "run1", "test_case3").                 #
#                           If omitted, the tag is left blank.                                                       #
#                                                                                                                    #
#       Example:                                                                                                     #
#           do save_Tx_out.tcl "Slow_mode_test"                                                                      #             --#
#                                                                                                                    #
# Prerequisites:                                                                                                     #
#       - Must be run after the simulation has completed (or been run long enough) so that the                       #
#         "rtl_tx_real" / "rtl_tx_imag" memories exist and are populated in the current simulation.                  #
#       - The simulation must contain memories named "rtl_tx_real" and "rtl_tx_imag" somewhere in the hierarchy.     #
#                                                                                                                    #
# Output:                                                                                                            #
#       Directory : ../Tx_output  (created automatically if it does not exist)                                       #
#       Files     : Questa_Sim_result_<description>_tx_real.txt                                                      #
#                   Questa_Sim_result_<description>_tx_imag.txt                                                      #
#       Note      : Any pre-existing output files with the same name are overwritten.                                #
#                                                                                                                    #
#--------------------------------------------------------------------------------------------------------------------#

puts "=============================================="

#-------------------------------------------------------------------------------------#
#-- Get discription from command-line argument ---------------------------------------#
#-------------------------------------------------------------------------------------#

quietly set discription ""

#  reading the discription if it was passed as an argument in the transctipt 
if {![catch {set _arg1 $1}] && $_arg1 ne ""} {
    quietly set discription $_arg1
}


#--------------------------------------------------------------------------------------#
#-- Variables -------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

# Memory name (used to auto-locate the memory in the simulation hierarchy)
quietly set real_mem_name "rtl_tx_real"
quietly set imag_mem_name "rtl_tx_imag"

# Memory size (defined in the testbeanch)
quietly set start_addr 0
quietly set max_addr   100000

# Output file location / naming
quietly set output_dir     "../Tx_output"
quietly set output_prefix  "Questa_Sim_result"

quietly set real_output_file "$output_dir/${output_prefix}_${discription}_tx_real.txt"
quietly set imag_output_file "$output_dir/${output_prefix}_${discription}_tx_imag.txt"


#-------------------------------------------------------------------------------------#
#-- Find memory automatically among design objects -----------------------------------#
#-------------------------------------------------------------------------------------#

quietly set mem_info [mem list -r /];
quietly set mem_info [split $mem_info "\n"];
quietly set real_mem_path "";
quietly set imag_mem_path "";

foreach line ${mem_info} {
    if {[string match "*${real_mem_name}*" $line]} {

        # Extract the memory path
        # Example:
        # Verilog: /zigbee_S_tb/rtl_tx_real[0:99999](100000d x 8w)

        if {[regexp {Verilog:\s+([^[]+)} $line -> path]} {
            set real_mem_path [string trim $path]
            break
        }
    }
}

foreach line ${mem_info} {
    if {[string match "*${imag_mem_name}*" $line]} {

        # Extract the memory path
        # Example:
        # Verilog: /zigbee_S_tb/rtl_tx_imag[0:99999](100000d x 8w)

        if {[regexp {Verilog:\s+([^[]+)} $line -> path]} {
            set imag_mem_path [string trim $path]
            break
        }
    }
}


#-------------------------------------------------------------------------------------#
#-- Check that memory was found ------------------------------------------------------#
#-------------------------------------------------------------------------------------#

if {($real_mem_path eq "") && ($imag_mem_path eq "")} {
    puts "ERROR: Could not find memories: '${real_mem_name}' and '${imag_mem_name}'."
    puts "Available memories:"
    puts $mem_info
    return
} elseif {$real_mem_path eq ""} {
    puts "ERROR: Could not find memory: '${real_mem_name}' ."
    return
} elseif {$imag_mem_path eq ""} {
    puts "ERROR: Could not find memory: '${imag_mem_name}' ."
    return
}

puts "-- Memory found: $real_mem_path  and  $imag_mem_path "


#-------------------------------------------------------------------------------------#
#-- Prepare output directory ---------------------------------------------------------#
#-------------------------------------------------------------------------------------#


# Create directory if it does not exist
if {![file exists $output_dir]} {
    file mkdir $output_dir
    puts "-- Folder created: ${output_dir}"
}

# Remove existing output file
if {[file exists $real_output_file]} {
    file delete -force $real_output_file
    puts "-- Overwriting : Tx_real_output"
}

if {[file exists $imag_output_file]} {
    file delete -force $imag_output_file
    puts "-- Overwriting : Tx_imaginary_output"
}


#-------------------------------------------------------------------------------------#
#-- Save memory content using "mem save" (built-in questa-sim command) ---------------#
#-------------------------------------------------------------------------------------#

mem save -o            $real_output_file   \
         -f            binary              \
         -wordsperline 1                   \
         -noaddress                        \
         $real_mem_path              


mem save -o            $imag_output_file   \
         -f            binary              \
         -wordsperline 1                   \
         -noaddress                        \
         $imag_mem_path              

puts "-- All memory content saved."
#-------------------------------------------------------------------------------------#
#-- Post-process output file: strip header comments and trailing X placeholders ------#
#-------------------------------------------------------------------------------------#

proc trim_mem_file {filepath} {
    if {![file exists $filepath]} {
        puts "WARNING: File not found for trimming: $filepath"
        return
    }

    set fh [open $filepath r]
    set lines [split [read $fh] "\n"]
    close $fh

    # Drop trailing empty element left by the final newline in the file
    if {[llength $lines] > 0 && [lindex $lines end] eq ""} {
        set lines [lrange $lines 0 end-1]
    }

    # Remove up to the first 3 lines if they are comments (start with '#')
    set skip 0
    for {set i 0} {$i < 3 && $i < [llength $lines]} {incr i} {
        if {[string match "//*" [lindex $lines $i]]} {
            incr skip
        } else {
            break
        }
    }
    set lines [lrange $lines $skip end]

    # Walk back from the end, dropping lines that are all x/X (uninitialized words)
    set last_valid [expr {[llength $lines] - 1}]
    while {$last_valid >= 0} {
        set line [string trim [lindex $lines $last_valid]]
        if {[regexp {^[xX]+$} $line]} {
            incr last_valid -1
        } else {
            break
        }
    }
    set lines [lrange $lines 0 $last_valid]

    set fh [open $filepath w]
    puts -nonewline $fh [join $lines "\n"]
    puts $fh ""
    close $fh

    # puts "Trimmed $filepath -> [llength $lines] lines remaining"
}

trim_mem_file $real_output_file
trim_mem_file $imag_output_file


#-------------------------------------------------------------------------------------#
#-- Report result --------------------------------------------------------------------#
#-------------------------------------------------------------------------------------#

quietly set word_count [expr {$last_addr - $start_addr + 1}]

puts "----------------------------------------------"
puts "Memory export completed"
puts "Output files   : $real_output_file, \n\t\t  \
                       $imag_output_file"
puts "Bytes written  : $word_count"
puts "=============================================="
