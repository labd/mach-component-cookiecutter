import re


def tf_attribute(file_path: str, name: str):
    """Get attribute value from terraform file.

    Very quick-and-dirty implementation
    """
    content = ""
    with open(file_path) as f:
        content = f.read()

    result = re.search(rf"{name}\s+=\s+(.*)", content)
    if result:
        return result.group(1).strip('"').strip("'")

    return None
