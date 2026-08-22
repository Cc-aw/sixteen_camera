foreach param_name [lsort [get_param -list]] {
    if {[regexp -nocase {scan|source|hierarchy|parser|vhdl|verilog} $param_name]} {
        puts "$param_name=[get_param $param_name]"
    }
}
exit
