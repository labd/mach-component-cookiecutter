# https://github.com/Azure/azure-functions-python-worker/issues/219#issuecomment-558052465
import sys
from os import path

sys.path.append(path.dirname(path.dirname(__file__)))
sys.path.append("/home/site/wwwroot")
