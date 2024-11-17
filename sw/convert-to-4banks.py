import sys
import os

def main(inext = ".vh"):

    if len(sys.argv) not in [2,3]:
        print("must specify source dir with .vh files, [input extension].")
        return
    path = sys.argv[1]
    if len(sys.argv) == 3:
        inext = sys.argv[2]

    # Check if the path exists and is a directory
    if not os.path.isdir(path):
        print("'{}' is not a valid directory.".format(path))
        return
    
    # Iterate over all files in the directory
    for root, _, files in os.walk(path):
        for file in files:
            if file.endswith(inext):
                full_path = os.path.join(root, file)
                print(full_path)
                with open(full_path, "r") as f, open(file+"b0.vh", "w") as b0, open(file+"b1.vh", "w") as b1, open(file+"b2.vh", "w") as b2, open(file+"b3.vh", "w") as b3:
                    for line in f:
                        content = line.strip()
                        if '@' in content:
                            content = content.split()[1]
                        #test 4bytes
                        if len(content) != 8:
                            print("{} is not 32-bit word.".format(content))
                            return
                        b0.write(content[6:]+"\n")
                        b1.write(content[4:6]+"\n")
                        b2.write(content[2:4]+"\n")
                        b3.write(content[0:2]+"\n")
    

if __name__ == "__main__":
    main()