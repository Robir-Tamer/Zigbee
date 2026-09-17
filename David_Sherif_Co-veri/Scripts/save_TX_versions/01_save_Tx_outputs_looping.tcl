#-------------------------------------------------------------------------------------------------------------------------#
#-- Save initialized memory contents to a binary file --------------------------------------------------------------------#
#-- Each line contains one 8-bit word -------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------------------------------------#


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


#-------------------------------------------------------------------------------------#
#-- Get discription from command-line argument ---------------------------------------#
#-------------------------------------------------------------------------------------#

set discription ""

#  reading the discription if it was passed as an argument in the transctipt 
if {![catch {set _arg1 $1}] && $_arg1 ne ""} {
    set discription $_arg1
}


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

puts "Memory found: $real_mem_path  and  $imag_mem_path "


#-------------------------------------------------------------------------------------#
#-- Prepare output directory ---------------------------------------------------------#
#-------------------------------------------------------------------------------------#

quietly set real_output_file "$output_dir/${output_prefix}_${discription}_tx_real.bin"
quietly set imag_output_file "$output_dir/${output_prefix}_${discription}_tx_imag.bin"

# Create directory if it does not exist
if {![file exists $output_dir]} {
    file mkdir $output_dir
}

# Remove existing output file
if {[file exists $real_output_file]} {
    file delete -force $real_output_file
    puts "Overwriting Tx_real_output"
}

if {[file exists $imag_output_file]} {
    file delete -force $imag_output_file
    puts "Overwriting Tx_imaginary_output"
}


#-------------------------------------------------------------------------------------#
#-- Open output file -----------------------------------------------------------------#
#-------------------------------------------------------------------------------------#
quietly set fp_r [open $real_output_file "w"]
quietly set fp_i [open $imag_output_file "w"]


#-------------------------------------------------------------------------------------#
#-- Read memory and write initialized locations --------------------------------------#
#-------------------------------------------------------------------------------------#

for {set addr $start_addr} {$addr <= $max_addr} {incr addr} {

    # Read real memory location
    set value_r [examine -radix binary "${real_mem_path}($addr)"]

    # Read imag memory location
    set value_i [examine -radix binary "${imag_mem_path}($addr)"]

    # Stop when an uninitialized X value is encountered
    if {[string match "*x*" [string tolower $value_r]]} {
        break
    }

    # Write exactly one 8-bit word per line
    puts $fp_r $value_r
    puts $fp_i $value_i
}


#-------------------------------------------------------------------------------------#
#-- Close file -----------------------------------------------------------------------#
#-------------------------------------------------------------------------------------#
close $fp_r
close $fp_i


#-------------------------------------------------------------------------------------#
#-- Report result --------------------------------------------------------------------#
#-------------------------------------------------------------------------------------#

quietly set last_addr  [expr {$addr - 1}]
quietly set word_count [expr {$last_addr - $start_addr + 1}]

puts "=============================================="
puts "Memory export completed"
puts "Output files   : $real_output_file, \n\
                       $imag_output_file"
puts "Start address  : $start_addr"
puts "Last address   : $last_addr"
puts "Words written  : $word_count"
puts "=============================================="