
#TODO: Should be non-GNU compatible

#TODO: Should we maybe use both fpu units when possible?

class CPUFeatures:
    x87                = "x87"
    MMX                = "MMX"
    SSE                = "SSE"
    SSE2               = "SSE2"
    SSE3               = "SSE3"
    SSSE3              = "SSSE3"
    AMD_VIRTUALIZATION = "AMD_VIRTUALIZATION"

class CPUOptions:
    def __init__(cxxflags, features):
        self.cxxflags = cxxflags
        self.features = features
