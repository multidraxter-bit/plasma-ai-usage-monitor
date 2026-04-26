#!/usr/bin/env python3
import sys
import os
import argparse

def main():
    parser = argparse.ArgumentParser(description="Smoke test QML import.")
    parser.add_argument("--strict", action="store_true", help="Fail hard if PyQt6 is missing or module cannot be imported.")
    parser.add_argument("--expected-version", default="6.0.1", help="Expected version string (default: 6.0.1).")
    args = parser.parse_args()

    try:
        from PyQt6.QtCore import QUrl, QCoreApplication
        from PyQt6.QtQml import QQmlEngine, QQmlComponent
        from PyQt6.QtGui import QGuiApplication
    except ImportError:
        print("PyQt6 not installed.")
        if args.strict:
            sys.exit(1)
        else:
            print("Skipping QML smoke test.")
            sys.exit(0)

    # To use QQmlEngine, we need a QCoreApplication or QGuiApplication
    # We slice sys.argv so Qt doesn't consume our custom arguments
    # Create a temporary QML module directory structure so QQmlEngine can find it
    import tempfile
    import shutil
    
    with tempfile.TemporaryDirectory() as temp_qml_dir:
        module_path = os.path.join(temp_qml_dir, "com", "github", "loofi", "aiusagemonitor")
        os.makedirs(module_path, exist_ok=True)
        
        # We need qmldir and the compiled .so
        qmldir_src = os.path.abspath("plugin/qmldir")
        so_src = os.path.abspath("build/plugin/libaiusagemonitorplugin.so")
        
        if os.path.exists(qmldir_src):
            shutil.copy(qmldir_src, os.path.join(module_path, "qmldir"))
        if os.path.exists(so_src):
            shutil.copy(so_src, os.path.join(module_path, "libaiusagemonitorplugin.so"))
            
        app = QGuiApplication(sys.argv[:1])
        engine = QQmlEngine()
        
        # Add local build path for testing without install
        engine.addImportPath(temp_qml_dir)
        
        # We want to check if the plugin is installed and importable.
        
        qml_content = b"""
    import QtQuick
    import com.github.loofi.aiusagemonitor 1.0 as AiMonitor

    Item {
        property string version: AiMonitor.AppInfo.version
        Component.onCompleted: {
            console.log("Loaded AppInfo version: " + version)
        }
    }
    """
    
    component = QQmlComponent(engine)
    component.setData(qml_content, QUrl("smoke_test.qml"))
    
    if component.isError():
        errors = component.errors()
        error_msgs = "\n".join([e.toString() for e in errors])
        
        # Check if the error is specifically about not finding the module
        if "is not installed" in error_msgs and "com.github.loofi.aiusagemonitor" in error_msgs:
            if args.strict:
                print("Error: The QML module 'com.github.loofi.aiusagemonitor' could not be found (strict mode).")
                print(f"Full QML error trace:\n{error_msgs}")
                sys.exit(1)
            else:
                print("Warning: The QML module 'com.github.loofi.aiusagemonitor' could not be found.")
                print("Skipping runtime version check. Are you sure the plugin is built and installed? Run 'just install'.")
                sys.exit(0)
        else:
            print(f"QML Component Error:\n{error_msgs}")
            sys.exit(1)
            
    obj = component.create()
    if obj is None:
        print("Error: Could not instantiate the QML component.")
        sys.exit(1)
        
    version = obj.property("version")
    print(f"Smoke test successful. Plugin loaded, version: {version}")
    
    if version != args.expected_version:
        print(f"Error: Expected version {args.expected_version}, but loaded plugin reports {version}.")
        print("You might have a stale plugin shadowing the new build.")
        sys.exit(1)

if __name__ == '__main__':
    main()
