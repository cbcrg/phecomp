# PheCom Intake/Activity Data Binary Convertion 
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' PheCom Intake Data Binary Convertion
    Usage:
          matrix2binary [OPTION] input_file
    where:
       'input_file' is a matrix .mtx file

    OPTIONS:
	a	Convert to binary all related files (SC and CD)
	s	Convert to binary only the specified file
'''   

import sys
from sys import *
import string

def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<3):
    # Not enough arguments
    sys.stderr.write("\nPheCom .mtx Intake Data Binary Converter.\nDetects differences between contigous acquisitions.\n")
    sys.stderr.write("Usage:\t python %s input_file\n" % arg[0])
    sys.stderr.write("where:\n'input_file' is a matrix .mtx file\n") 
    sys.stderr.write("OPTIONS:\n")
    sys.stderr.write("\ta\tConvert to binary all related files (SC and CD)\n") 
    sys.stderr.write("\ts\tConvert to binary only the specified file\n") 
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
    


class Converter:
  ''' Converts data stored in .mtx file to binary '''

  def __init__(self,mtx_file,opt):
    # Class Constructor
    
    self.opt=opt # Store data option

    # Check data option
    try: 
      self.CheckOption(mtx_file)
    except:
      raise ValueError()
    
  def OpenFile(self,mtx_file):
    ''' Opens file '''
    # Open .mtx file
    if (mtx_file.endswith('.mtx')):
      try: 
        self.handle = open(mtx_file,'r')
      except: 
        sys.stderr.write("Unable to open %s" % mtx_file)
        raise ValueError()
    else :
       sys.stderr.write("Error: .mtx file expected!\n")
       raise ValueError()
    
    # Open output file (_XX_bin.mtx)
    try:
      self.handle_out = open(mtx_file[:-4]+'_bin.mtx', 'w') # Create/Open the file
    except:
      sys.stderr.write("Unable create binary data .mtx file\n")
      raise ValueError()


  def GetRootName(self,mtx_file):
    ''' Gets Root Name from a given .mtx file to allow binary convertion of both .mtx files comming from the same raw .mtb data file'''
    self.RootName=mtx_file[:-8]+mtx_file[-6:-4]
    self.FileType=mtx_file[-8:-6]

  
  def Files2convert(self):
    ''' Gets the name of the files to be converted to binary depending on the option given'''
    self.Files=[]
    if (self.opt=='s'):  # The given file only
      self.Files.append(self.RootName[:-2]+self.FileType+self.RootName[-2:]+'.mtx')
    else:  # 'a' option. Both files (SC and CD) to be converted
      self.Files.append(self.RootName[:-2]+'SC'+self.RootName[-2:]+'.mtx')
      self.Files.append(self.RootName[:-2]+'CD'+self.RootName[-2:]+'.mtx')


  def CheckOption(self,filename):
    '''Check for correct data option '''
    if (self.opt!='a' and self.opt!='s'):
      sys.stderr.write("Error:Undefined Option\n")
      raise ValueError()
    else :
      self.GetRootName(filename)
  

  def CopyDispenserDistrb(self):
    ''' Copy Dispenser Distribution Information to the binary file'''

    line=self.handle.readline()
    self.handle_out.write(line)  # Copy to binary file
    while (line.find("Ch")==-1):  # Cage Distribution Header ([Ch]1-Chow/Choc/Drink)
      line = self.handle.readline() 
      self.handle_out.write(line)   # Copy last header line to binary file


  def DataToBinary(self): 
    '''Converts data into binary:
       1. Discard 1st minut due to system initizalization errors
       2. Only count for negative changes (decrements)
       3. Discard decrements > 0.1 g (not consequence of mice eating)
       Then:
       --> Negative change (decrement) --> Eat/Drink:    1
       --> No Negative change          --> No Eat/Drink: 0'''

    # Discard 1st minute (60 samples) due to system initialization errors
    for i in range(60):
      line=self.handle.readline()
      
    # Initialize values
    binary=[]
    oldsample=[]
    
    self.Ascii2Float(line)  # Convert Ascii data into English decimal numbers syntax
    
    for d in self.data:
      oldsample.append(d) # Store intake value to compare with next sample
      binary.append('0')
         
    # Process the rest of the acquisitions
    line=self.handle.readline()
    while (line.find('Stop Date')==-1):  # End of file not reached
      self.Ascii2Float(line)  # Convert Ascii data into English decimal numbers syntax
      for i in range(len(self.data)):
        if(self.data[i] < oldsample[i]):   # Eliminate positive changes
          change=abs(oldsample[i]-self.data[i])   # Calculate the distance
          if (change>=0.01 and change<0.1):  # Mouse has eaten/drunk. 
            binary[i]='1'
          else:                       # Mouse has not eaten/drunk
            binary[i]='0'
        else:
          binary[i]='0'               # Mouse has not eaten/drunk
        oldsample[i]=self.data[i]
      
      # Store Binary data 
      data=string.join(binary,'\t')+'\n'
      self.handle_out.write(data)   
      line=self.handle.readline()
    
    # Store Stop Time 
    self.handle_out.write(line)  

  def Ascii2Float(self,line):
    ''' Convert Ascii data into English decimal numbers syntax '''
    self.data=[]
    line=string.replace(line,',','.') # English decimal syntax
    line=string.replace(line,'*','')  # Eliminate '*'
    samples=line.split()
    for i in range(len(samples)):
      samples[i]=float(samples[i])
    self.data=samples
    
  
  def CloseFiles(self):
    ''' Closes all opened files'''
    self.handle.close()
    self.handle_out.close()
  

  def Convert(self):
    '''Reads .mtx file and converts data into binary'''
  
    # Stablish files to be converted
    self.Files2convert()
    for filename in self.Files:
      # Open File
      self.OpenFile(filename)

      # Copy Dispenser Distribution Information to the binary file
      self.CopyDispenserDistrb()
    
      # Convert data into binary
      self.DataToBinary() 
     
      # Close Files
      self.CloseFiles()
 
 

def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Binary Convertion Object
  try:
    ToBinary=Converter(argv[2],argv[1])
  except ValueError:
    sys.stderr.write( "Binary Convertion Aborted\n" )
    return

  # Convert to binary
  ToBinary.Convert()

  # Close files
  ToBinary.CloseFiles()

if __name__=="__main__":
  main()






     
