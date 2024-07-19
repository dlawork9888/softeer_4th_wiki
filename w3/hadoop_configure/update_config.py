import os
import shutil
import xml.etree.ElementTree as ET
from xml.dom import minidom

def backup_config_file(original_file):
    backup_file = original_file + ".backup"
    shutil.copy(original_file, backup_file)
    print(f"Backup created for {original_file}.")

def prettify_element(elem, level=0):
    i = "\n" + level*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            prettify_element(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def update_or_add_property(tree, property_name, new_value):
    root = tree.getroot()
    properties = root.findall(".//property")
    found = False
    for prop in properties:
        name = prop.find('name')
        if name is not None and name.text == property_name:
            value = prop.find('value')
            if value is not None:
                value.text = new_value
                found = True
                break
    if not found:  # If property does not exist, add it
        new_property = ET.SubElement(root, 'property')
        name_elem = ET.SubElement(new_property, 'name')
        name_elem.text = property_name
        value_elem = ET.SubElement(new_property, 'value')
        value_elem.text = new_value
    prettify_element(root)  # Re-indent the tree
    print(f"Updated '{property_name}' to '{new_value}'.")

def save_config_file(tree, file_path):
    xml_str = ET.tostring(tree.getroot(), 'utf-8')
    pretty_xml = minidom.parseString(xml_str).toprettyxml(indent="  ")
    with open(file_path, "w") as f:
        f.write(pretty_xml)
    print(f"Updated configuration saved to {file_path}.")

def update_configuration(file_path, updates):
    backup_config_file(file_path)
    tree = ET.parse(file_path)
    for property_name, new_value in updates.items():
        update_or_add_property(tree, property_name, new_value)
    save_config_file(tree, file_path)

def main():
    hadoop_conf_dir = ""
    config_updates = {
        "core-site.xml": {
            "fs.defaultFS": "hdfs://namenode:9000",
            "hadoop.tmp.dir": "/hadoop/tmp",
            "io.file.buffer.size": "131072"
        },
        "hdfs-site.xml": {
            "dfs.replication": "2",
            "dfs.blocksize": "134217728",  # 128 MB
            "dfs.namenode.name.dir": "/hadoop/dfs/name"
        },
        "mapred-site.xml": {
            "mapreduce.framework.name": "yarn",
            "mapreduce.jobhistory.address": "namenode:10020",
            "mapreduce.task.io.sort.mb": "256"
        },
        "yarn-site.xml": {
            "yarn.resourcemanager.address": "namenode:8032",
            "yarn.nodemanager.resource.memory-mb": "8192",
            "yarn.scheduler.minimum-allocation-mb": "1024"
        }
    }

    for file_name, updates in config_updates.items():
        full_path = os.path.join(hadoop_conf_dir, file_name)
        update_configuration(full_path, updates)

if __name__ == "__main__":
    main()
