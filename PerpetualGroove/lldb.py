import lldb

def __lldb_init_module(debugger, internal_dict):
  debugger.HandleCommand('type summary add -w "Groove" -F %s.SwiftObjectDescription Groove.BarBeatTime' % __name__)
  debugger.HandleCommand('type summary add -w "Groove" -F %s.SwiftObjectDescription Groove.VariableLengthQuantity' % __name__)
