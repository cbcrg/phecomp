# PheCom Intake/Activity Data Increment Convertion 
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' PheCom Intake Data Increment Convertion
    Usage:
          matrix2increment [OPTION] input_file
    where:
       'input_file' is a matrix .mtx file

    OPTIONS:
	a	Convert to increments all related files (SC and CD)
	s	Convert to increments only the specified file
'''   

import sys
from sys import *
import string

def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<3):
    # Not enough arguments
    sys.stderr.write("\nPheCom .mtx Intake Data Increment Converter.\nDetects differences between contigous acquisitions. Do not filter any length.\n")
    sys.stderr.write("Usage:\t python %s input_file\n" % arg[0])
    sys.stderr.write("where:\n'input_file' is a matrix .mtx file\n") 
    sys.stderr.write("OPTIONS:\n")
    sys.stderr.write("\ta\tConvert to increments all related files (SC and CD) / (FAT and CTRL)\n") 
    sys.stderr.write("\ts\tConvert to increments only the specified file\n") 
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
    


class Converter:
  ''' Converts data stored in .mtx file to increments '''

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
    
    # Open output file (_XX_inc.mtx)
    try:
      self.handle_out = open(mtx_file[:-4]+'_inc_all.mtx', 'w') # Create/Open the file
    except:
      sys.stderr.write("Unable create increment data .mtx file\n")
      raise ValueError()


  def GetRootName(self,mtx_file):
    ''' Gets Root Name from a given .mtx file to allow increment convertion of both .mtx files comming from the same raw .mtb data file'''
    '''if self.RootName.find('FAT'):
      self.RootName=mtx_file[:-9]+mtx_file[-6:-4]
    elif self.RootName.find('CTRL'):
      self.RootName=mtx_file[:-10]+mtx_file[-6:-4]
    else:
      self.RootName=mtx_file[:-8]+mtx_file[-6:-4]
      self.FileType=mtx_file[-8:-6]
    '''
    self.RootName=mtx_file

  
  def Files2convert(self):
    ''' Gets the name of the files to be converted to increment depending on the option given'''
    self.Files=[]
    '''if (self.opt=='s'):  # The given file only
      self.Files.append(self.RootName[:-2]+self.FileType+self.RootName[-2:]+'.mtx')
    else:  # 'a' option. Both files (SC and CD) to be converted
      if(self.RootName.find('SC')!=-1 or self.RootName.find('CD')!=-1):
        self.Files.append(self.RootName[:-2]+'SC'+self.RootName[-2:]+'.mtx')
        self.Files.append(self.RootName[:-2]+'CD'+self.RootName[-2:]+'.mtx')
      else:
        self.Files.append(self.RootName[:-2]+'FAT'+self.RootName[-2:]+'.mtx')
        self.Files.append(self.RootName[:-2]+'CTRL'+self.RootName[-2:]+'.mtx') '''
    self.Files.append(self.RootName)
    if (self.opt=='a'):
      if(self.RootName.find('SC')!=-1):
         self.Files.append(self.RootName[:-8]+'CD'+self.RootName[-6:])
      elif(self.RootName.find('CD')!=-1):
         self.Files.append(self.RootName[:-8]+'SC'+self.RootName[-6:])
      elif(self.RootName.find('FAT')!=-1):
         self.Files.append(self.RootName[:-9]+'CTRL'+self.RootName[-6:])
      elif(self.RootName.find('CTRL')!=-1):
         self.Files.append(self.RootName[:-10]+'FAT'+self.RootName[-6:])


  def CheckOption(self,filename):
    '''Check for correct data option '''
    if (self.opt!='a' and self.opt!='s'):
      sys.stderr.write("Error:Undefined Option\n")
      raise ValueError()
    else :
      self.GetRootName(filename)
  

  def CopyDispenserDistrb(self):
    ''' Copy Dispenser Distribution Information to the increments file'''

    for i in range(4):
      line=self.handle.readline()
      self.handle_out.write(line)  # Copy to increment file
    line = self.handle.readline() 
    '''while (line.find("Ch")==-1):  # Cage Distribution Header ([Ch]1-Chow/Choc/Drink)
      line = self.handle.readline() 
      self.handle_out.write(line)   # Copy last header line to increment file'''
      


  def DataToIncrement(self): 
    '''Converts data into increment:
       1. Discard 1st minut due to system initizalization errors
       2. Only count for negative changes (decrements)
       3. Discard decrements > 0.1 g (not consequence of mice eating)
       Then:
       --> Negative change (decrement) --> Eat/drink: Convert to positive increment
       --> No Negative change          --> No Eat/Drink: 0.00'''

    # Discard 1st minute (60 samples) due to system initialization errors
    for i in range(60): # TO BE UNCOMMENTED
      line=self.handle.readline()
    #line=self.handle.readline()# TO BE ERASED!	
    # Initialize values
    increment=[]
    oldsample=[]
    interval=0
    
    self.Ascii2Float(line)  # Convert Ascii data into English decimal numbers syntax
    
    for d in self.data:
      oldsample.append(d) # Store intake value to compare with next sample
      increment.append('0') # Initialize increment vector
         
    # Process the rest of the acquisitions
    line=self.handle.readline()
    while (line.find('Stop Date')==-1):  # End of file not reached
      self.Ascii2Float(line)  # Convert Ascii data into English decimal numbers syntax
      #print oldsample
      #print self.data
      for i in range(len(self.data)):
        #print self.data[i]
        #print oldsample[i]
         
        if(self.data[i] <= oldsample[i]):   # negative changes, real eating events
          change=abs(oldsample[i]-self.data[i])   # Calculate the distance
        '''  #print change
          increment[i]='%.2f' % change
          #  interval=0
          else:
          interval+=1
          #if interval >	86400 : # More than 24h whithout eating!
          #if interval >	36000 : # More than 10h whithout eating!
          if interval >	21600 : # More than 6h whithout eating!
            pass # Not register this time event
          else:
            increment[i]='0.00'               # Mouse has not eaten/drunk
        else:
          change=oldsample[i]-self.data[i]   # Calculate the distance
          #print change
          increment[i]='%.2f' % change
        change=oldsample[i]-self.data[i]'''
        increment[i]='%.2f' % change
        oldsample[i]=self.data[i]
      
      # Store Increment data 
      data=string.join(increment,'\t')+'\n'
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
    '''Reads .mtx file and converts data into increment'''
  
    # Stablish files to be converted
    self.Files2convert()
    for filename in self.Files:
      # Open File
      self.OpenFile(filename)

      # Copy Dispenser Distribution Information to the increment file
      self.CopyDispenserDistrb()
    
      # Convert data into increment
      self.DataToIncrement() 
     
      # Close Files
      self.CloseFiles()
 
 

def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Increment Convertion Object
  try:
    ToIncrement=Converter(argv[2],argv[1])
  except ValueError:
    sys.stderr.write( "Increment Convertion Aborted\n" )
    return

  # Convert to increment
  ToIncrement.Convert()

  # Close files
  ToIncrement.CloseFiles()

if __name__=="__main__":
  main()






     
