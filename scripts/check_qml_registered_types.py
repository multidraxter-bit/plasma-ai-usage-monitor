#!/usr/bin/env python3
import os
import re
import sys

def main():
    plugin_cpp_path = 'plugin/aiusageplugin.cpp'
    cmake_path = 'plugin/CMakeLists.txt'

    if not os.path.exists(plugin_cpp_path):
        print(f"Error: {plugin_cpp_path} not found")
        sys.exit(1)

    if not os.path.exists(cmake_path):
        print(f"Error: {cmake_path} not found")
        sys.exit(1)

    with open(plugin_cpp_path, 'r') as f:
        plugin_cpp_content = f.read()

    with open(cmake_path, 'r') as f:
        cmake_content = f.read()

    # Find registered types: qmlRegisterType<Type> or qmlRegisterSingletonType<Type>
    registered_types = re.findall(r'qmlRegister(?:Singleton)?Type<([A-Za-z0-9_]+)>', plugin_cpp_content)
    
    # Base classes registered as uncreatable
    uncreatable_types = re.findall(r'qmlRegisterUncreatableType<([A-Za-z0-9_]+)>', plugin_cpp_content)
    
    all_types = set(registered_types + uncreatable_types)
    
    # Extract SRCS from CMakeLists.txt
    # We look for set(aiusagemonitor_SRCS ...)
    srcs_match = re.search(r'set\s*\(\s*aiusagemonitor_SRCS(.*?)\)', cmake_content, re.DOTALL | re.IGNORECASE)
    if not srcs_match:
        print("Error: Could not find aiusagemonitor_SRCS in plugin/CMakeLists.txt")
        sys.exit(1)

    srcs = srcs_match.group(1).split()
    
    # Extract HDRS
    hdrs_match = re.search(r'set\s*\(\s*aiusagemonitor_HDRS(.*?)\)', cmake_content, re.DOTALL | re.IGNORECASE)
    hdrs = hdrs_match.group(1).split() if hdrs_match else []

    missing = False

    for t in all_types:
        expected_cpp = f"{t.lower()}.cpp"
        expected_h = f"{t.lower()}.h"
        
        # Some types might not have a .cpp file (header-only)
        cpp_exists_on_disk = os.path.exists(os.path.join('plugin', expected_cpp))
        h_exists_on_disk = os.path.exists(os.path.join('plugin', expected_h))
        
        if not cpp_exists_on_disk and not h_exists_on_disk:
            print(f"Error: Type {t} is registered but neither {expected_cpp} nor {expected_h} exist in plugin/")
            missing = True
            continue

        if cpp_exists_on_disk:
            if expected_cpp not in srcs:
                print(f"Error: Type {t} has {expected_cpp} but it is NOT in plugin/CMakeLists.txt aiusagemonitor_SRCS")
                missing = True
        elif h_exists_on_disk:
            if expected_h not in hdrs:
                print(f"Error: Type {t} is header-only but {expected_h} is NOT in plugin/CMakeLists.txt aiusagemonitor_HDRS")
                missing = True

    if missing:
        sys.exit(1)
    else:
        print("QML registered types consistency OK.")
        sys.exit(0)

if __name__ == '__main__':
    main()
