import os
import os.path


def doesFileExist(filepath):

    if os.path.isfile(filepath) and os.access(filepath, os.R_OK):
        print ("File exists and is readable")
    else:
        raise FileNotFoundError

def parsemeaning(filepath):

    f = open(filepath, "r")
    for line in f.readlines():
      list1 = line.split('-')
      print(list1[0].rstrip())
      list2 = list1[1].split(',')
      for meaning in list2:
            print (meaning.lstrip())


    
if __name__=='__main__':

  PATH ='dictionary.txt'
  try:
    doesFileExist(PATH)
    parsemeaning(PATH)
  except FileNotFoundError:
      print("File not found")
  except:
      print("Unexpected error")
  
   



