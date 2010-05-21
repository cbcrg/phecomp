# PheCom Intake/Activity Data Extraction 
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' PheCom .mtb Intake Data Extraction
    Usage:
          raw2matrix [OPTION] input_file
    where:
       'input_file' is a PheCom .mtb file
 
    OPTIONS:
	f	Create data matrices from food data in .mtb file
	d	Create data matrices from drink data in .mtb file
	i	Create data matrices from intake (food+drink) data in .mtb file
        a	Create data matrices from activity and rearing data in .mtb file
'''   

import sys
from sys import *
import string
import time


def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<3):
    # Not enough arguments
    sys.stderr.write("\nPheCom .mtb Intake Data Extraction.\nSplits data into FAT and CTRL type and creates data matrices.\n")
    sys.stderr.write("Usage:\t python %s [OPTION] input_file\n" % arg[0])
    sys.stderr.write("where:\n'input_file' is a PheCom .mtb file\n")
    sys.stderr.write("OPTIONS:\n")
    sys.stderr.write("\tf\tCreate data matrices from food data in .mtb file\n") 
    sys.stderr.write("\td\tCreate data matrices from drink data in .mtb file\n") 
    sys.stderr.write("\ti\tCreate data matrices from intake (food+drink) data in .mtb file\n") 
    sys.stderr.write("\ta\tCreate data matrices from activity and rearing data in .mtb file\n")
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
    


class DataSearcher:
  ''' Searches and stores required data from PheCom .mtb file '''

  def __init__(self,mtb_file,opt):
    # Class Constructor
    # Open .mtb file
    if (mtb_file.endswith('.mtb')):
      try: 
        self.handle = open(mtb_file,'r')
      except:
        sys.stderr.write("Unable to open %s" % mtb_file)
        raise ValueError()
    else :
        sys.stderr.write("Error: .mtb file expected!\n")
        raise ValueError()
    
    self.opt=opt # Store data option
    self.RootName=mtb_file[:-4] # Keep input file name to posterior modification

    # Check data option
    try: 
      self.CheckOption()
    except:
      raise ValueError()
         
    # Open output file (_fat_.mtx), store fatty mice data
    try:
      self.handle_FAT = open(mtb_file[:-4]+'_FAT_'+self.opt+'.mtx', 'w') # Create/Open the file
    except:
      sys.stderr.write("Unable create FAT .mtx file\n")
      raise ValueError()
   
    # Open output file (_ctrl.mtx), store control mice data
    try:
      self.handle_CTRL = open(mtb_file[:-4]+'_CTRL_'+self.opt+'.mtx', 'w') # Create/Open the file
    except:
      sys.stderr.write("Unable create CTRL .mtx file\n")
      raise ValueError()
    
    self.TimeCounter=0   # Counts data acquisition time interval
    

  def GetDispenserDistrib(self):
    ''' Get dispenser distribution and store it'''
    
    self.distrib=[] # Cage distribution in .mtb file
    self.disp_FAT=[] # Cage distribution in _FAT.mtx file
    self.disp_CTRL=[] # Cage distribution in _CTRL.mtx file

    line=self.handle.readline()
    
    while (line.find("[ANIMALS DATA]")==-1):  # Find ANIMALS DATA Section
      line = self.handle.readline() 
   
    line = self.handle.readline()
    
    while (line.find("[EXPERIMENT HEADER]")==-1):  # Look in ANIMALS DATA Section
      if(line.find("Group")!=-1):
        if (line[line.find("=")+1]=='F' or line[line.find("=")+1]=='f'):
          self.distrib.append('FAT')
          self.disp_FAT.append(line[5:line.find("=")]+'_FAT') # Store dispenser distribution
        else:
          self.distrib.append('CTRL')
          self.disp_CTRL.append(line[5:line.find("=")]+'_CTRL') # Store dispenser distribution
      line = self.handle.readline()


  def GateDateTime(self):
    ''' Get Acquisition Date and Time'''
    line = self.handle.readline()
    
    while (line.find("Date")==-1):  # Find Date Tag
      line = self.handle.readline()
    
    self.date=line[line.find("=")+1:-2]
   
  
  def GetEndTime(self):
    ''' Calculates End Date and Time '''
    # Get start date and time
    StartDate=time.strptime(self.date, "%d/%m/%Y %H:%M:%S") # Get start date and time
    StartDate=time.mktime(StartDate)  # Convert date and time to a time expressed in seconds
    EndDate=StartDate+self.TimeCounter
    EndDate=time.gmtime(EndDate) # Convert new date to Human Friendly Format
    self.EndDate=time.strftime("%d/%m/%Y %H:%M:%S",EndDate)
        

  def CheckOption(self):
    '''Check for correct data option '''
    if (self.opt!='f' and self.opt!='d' and self.opt!='i'):
      sys.stderr.write("Error:Undefined Option\n")
      raise ValueError()  
    

  def WriteHeader(self):
    '''Write _FAT/_CTRL files header'''
    # Choose header
    if (self.opt=='f'):
      # Food Data asked
      self.header='PHECOM FOOD DATA\nStart Date and Time:\t'+self.date+'\n' 
    elif (self.opt=='d'):
      # Drink Data asked
      self.header='PHECOM DRINK DATA\nStart Date and Time:\t'+self.date+'\n'
    elif (self.opt=='i'):
      # Intake (Food+Drink) Data asked  
      self.header='PHECOM INTAKE (FOOD+DRINK) DATA\nStart Date and time:\t'+self.date+'\n'  
    
    # Create dispenser labels
    if(self.opt=='f' or self.opt=='d'):
      # Food Data asked or Drink Data asked, 2 dispensers per cage
      rounds=2
    else:
      # Intake (Food + Drink) Data asked, 4 dispensers per cage
      rounds=4
     
    disp_order_FAT=''   # Stores Dispenser order in FAT files
    disp_order_CTRL=''   # Stores Dispenser order in CTRL files
    cages_FAT=''        # Stores Cages order in FAT files
    cages_CTRL=''        # Stores Cages order in CTRL files
  
    for r in range(rounds):
      if (r==0) :   # Food and Intake: Channel 3, Food 1; Drink: Channel 1, Drink 1
        cage_number=1
        for dist in self.distrib:
          if(dist.find("FAT")!=-1):  # FAT data
            cages_FAT=cages_FAT+'C%d\t' % cage_number
            if(self.opt=='f' or self.opt=='i'):
              # Food Data asked and Intake (Food + Drink)
              disp_order_FAT=disp_order_FAT+'Ch3-Fat\t' 
            else: 
              # Drink Data asked
              disp_order_FAT=disp_order_FAT+'Ch1-Drink\t' 
          else:  # CTRL data
            cages_CTRL=cages_CTRL+'C%d\t' % cage_number
            if(self.opt=='f' or self.opt=='i'):
              # Food Data asked and Intake (Food + Drink)
               disp_order_CTRL=disp_order_CTRL+'Ch3-Ctrl\t' 
            else: 
              # Drink Data asked
              disp_order_CTRL=disp_order_CTRL+'Ch1-Drink\t' 
          cage_number+=1
      if (r==1) :   # Food and Intake: Channel 2, Food 2; Drink: Channel 4, Drink 2
        for dist in self.distrib:
          if(dist.find("FAT")!=-1):  # FAT data
            if(self.opt=='f' or self.opt=='i'):
              # Food Data asked and Intake (Food + Drink)
              disp_order_FAT=disp_order_FAT+'Ch4-Fat\t' 
            else: 
              # Drink Data asked
              disp_order_FAT=disp_order_FAT+'Ch2-Drink\t' 
          else:  # CTRL data
            if(self.opt=='f' or self.opt=='i'):
              # Food Data asked and Intake (Food + Drink)
              disp_order_CTRL=disp_order_CTRL+'Ch4-Ctrl\t' 
            else: 
              # Drink Data asked
              disp_order_CTRL=disp_order_CTRL+'Ch2-Drink\t' 
      if (r==2 or r==3):   # Intake: Channel 1, Drink 1, Channel 2, Drink 2
        for dist in self.distrib:
          if(dist.find("FAT")!=-1):  # FAT data
            disp_order_FAT=disp_order_FAT+'Ch%d-Drink\t' %(r-1)
          else: # CTRL data
            disp_order_CTRL=disp_order_CTRL+'Ch%d-Drink\t' %(r-1)
    
    
    # Write _FAT file header
    self.handle_FAT.write(self.header)
    self.handle_FAT.write('\n'+cages_FAT+cages_FAT+'\n')
    self.handle_FAT.write(disp_order_FAT+'\n')
    
    # Write _CTRL file header
    self.handle_CTRL.write(self.header)
    self.handle_CTRL.write('\n'+cages_CTRL+cages_CTRL+'\n')
    self.handle_CTRL.write(disp_order_CTRL+'\n')
    

  def SplitData(self):
    '''Splits required data into FAT and CTRL mice type'''
    self.FAT_data='' # Chow mice data
    self.CTRL_data='' # Choc mice data

    # Classify data  into FAT or CTRL
    if(self.opt=='f' or self.opt=='d'):
      # Food Data asked or Drink Data asked, 2 dispensers per cage
      rounds=2
    else:
      # Intake (Food + Drink) Data asked, 4 dispensers per cage
      rounds=4
    index=0
    for r in range(rounds):
      for dist in self.distrib:
        datum=self.data[index]
        if(dist.find("FAT")!=-1):  # FAT data
          self.FAT_data=self.FAT_data+datum+'\t'
        elif(dist.find("CTRL")!=-1):  # CTRL data 
          self.CTRL_data=self.CTRL_data+datum+'\t'
        index+=1

  def GetData(self):
    ''' Gets required data '''
    # Read .mtb file until DATASECTION Tag
    line = self.handle.readline()
    while (line.find("[DATASECTION]")==-1):  
      line = self.handle.readline() 

    # Get required data till end of file
    line = self.handle.readline()
    while (line!="" and line!='\n'):  # End of file not reached
      sample=line.split()
      if (self.opt=='f'):
        # Food Data asked
        #self.data=sample[29:53]
        self.data=sample[53:]  # Channels 3 & 4
      elif (self.opt=='d'):
        # Drink Data asked
        #self.data=sample[53:]
        self.data=sample[29:53]  # Channels 1 & 2
      elif (self.opt=='i'):
        # Intake (Food+Drink) Data asked 
        self.data=sample[29:]
      # Split Data into FAT or CTRL
      self.SplitData()
      # Store data 
      self.handle_FAT.write(self.FAT_data+'\n')
      self.handle_CTRL.write(self.CTRL_data+'\n')
      self.TimeCounter+=1
      line = self.handle.readline()
    

  def CreateMatrix(self):
    '''Reads .mtb file, creates a matrix with the useful data and stores it into a file'''
  
    # Get Cage dispensers distribution
    self.GetDispenserDistrib()

    # Get Acquisition Date and Time
    self.GateDateTime()
    
    # Write _FAT/_CTRL files header
    self.WriteHeader()
  
    # Get Data
    self.GetData()
    
    # Get End Acquisition Date and Time
    self.GetEndTime()
 
   
  def CloseInFiles(self):
    ''' Closes all input opened files'''
    self.handle.close()
      
 
  def CloseOutFiles(self):
    ''' Closes all output opened files'''
    self.handle_FAT.close()
    self.handle_CTRL.close()

  
  def AddEndDate(self):
    ''' Add End Acquisition Date to Data Files '''

    # Add Stop Date and Time
    self.handle_FAT.write('Stop Date and Time:\t'+self.EndDate+'\n')
    
    # Add Stop Date and Time
    self.handle_CTRL.write('Stop Date and Time:\t'+self.EndDate+'\n')


def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Data Searcher
  try:
    GetData=DataSearcher(argv[2],argv[1])
  except ValueError:
    sys.stderr.write( "\nData Extraction Aborted.\n" )
    return

  # Create data matrices (_FAT and _CTRL) from .mtb file containing required data
  GetData.CreateMatrix()

  # Add End Acquisition Date and time
  GetData.AddEndDate()

  # Close files
  GetData.CloseInFiles()
  GetData.CloseOutFiles()


if __name__=="__main__":
  main()






     
