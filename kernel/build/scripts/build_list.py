def asmObj(asm_file):
    return asm_file[:-4] + ".o"

def cppObj(cpp_file):
    return cpp_file[:-4] + ".o"


def buildList(builder, files, filename_transform):
    output_list = []
    
    for file in file:
        output_list.append(builder(file, filename_transform(file)))

    return output_list
