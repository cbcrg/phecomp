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
    sys.stderr.write("\nPheCom .mtb Intake Data Extraction.\nSplits data into SC and CD type and creates data matrices.\n")
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
         
    # Open output file (_SC_.mtx), store chow mice data
    try:
      self.handle_SC = open(mtb_file[:-4]+'_SC_'+self.opt+'.mtx', 'w') # Create/Open the file
    except:
      sys.stderr.write("Unable create SC .mtx file\n")
      raise ValueError()
   
    # Open output file (_CD.mtx), store choc mice data
    try:
      self.handle_CD = open(mtb_file[:-4]+'_CD_'+self.opt+'.mtx', 'w') # Create/Open the file
    except:
      sys.stderr.write("Unable create CD .mtx file\n")
      raise ValueError()
    
    self.TimeCounter=0   # Counts data acquisition time interval
    

  def GetDispenserDistrib(self):
    ''' Get dispenser distribution and store it'''
    
    self.distrib=[] # Cage distribution in .mtb file
    self.disp_SC=[] # Cage distribution in _SC.mtx file
    self.disp_CD=[] # Cage distribution in _CD.mtx file

    line=self.handle.readline()
    
    while (line.find("[ANIMALS DATA]")==-1):  # Find ANIMALS DATA Section
      line = self.handle.readline() 
   
    line = self.handle.readline()
    
    while (line.find("[EXPERIMENT HEADER]")==-1):  # Look in ANIMALS DATA Section
      if(line.find("Name")!=-1):
        if (line[line.find("=")+1]=='S' or line[line.find("=")+1]=='s'):
          self.distrib.append('SC')
          self.disp_SC.append(line[4:line.find("=")]+'_SC') # Store dispenser distribution
        else:
          self.distrib.append('CD'+'-'+line[-3])
          self.disp_CD.append(line[4:line.find("=")]+'_CD'+'-'+line[-3]) # Store dispenser distribution
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
    '''Write _SC/_CD files header'''
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
     
    disp_order_SC=''   # Stores Dispenser order in SC files
    disp_order_CD=''   # Stores Dispenser order in DC files
    cages_SC=''        # Stores Cages order in SC files
    cages_CD=''        # Stores Cages order in CD files
  
    for r in range(rounds):
      if (r==0) :   # Food and Intake: Channel 3, Food 1; Drink: Channel 1, Drink 1
        cage_number=1
        for dist in self.distrib:
          if(dist.find("SC")!=-1):  # SC data
            cages_SC=cages_SC+'C%d\t' % cage_number
            if(self.opt=='f' or self.opt=='i'):
              # Food Data asked and Intake (Food + Drink)
              disp_order_SC=disp_order_SC+'Ch3-Chow\t' 
            else: 
              # Drink Data asked
              disp_order_SC=disp_order_SC+'Ch1-Drink\t' 
          else:  # CD data
            cages_CD=cages_CD+'C%d\t' % cage_number
            if(self.opt=='f' or self.opt=='i'):
              # Food Data asked and Intake (Food + Drink)
              if(dist.find("-C")!=-1):  # Channel 1 contains Choc
                disp_order_CD=disp_order_CD+'Ch3-Choc\t' 
              elif(dist.find("-D")!=-1):  # Channel 2 contains Choc
                disp_order_CD=disp_order_CD+'Ch3-Chow\t' 
            else: 
              # Drink Data asked
              disp_order_CD=disp_order_CD+'Ch1-Drink\t' 
          cage_number+=1
      if (r==1) :   # Food and Intake: Channel 2, Food 2; Drink: Channel 4, Drink 2
        for dist in self.distrib:
          if(dist.find("SC")!=-1):  # SC data
            if(self.opt=='f' or self.opt=='i'):
              # Food Data asked and Intake (Food + Drink)
              disp_order_SC=disp_order_SC+'Ch4-Chow\t' 
            else: 
              # Drink Data asked
              disp_order_SC=disp_order_SC+'Ch2-Drink\t' 
          else:  # CD data
            if(self.opt=='f' or self.opt=='i'):
              # Food Data asked and Intake (Food + Drink)
              if(dist.find("-C")!=-1):  # Channel 1 contains Choc
                disp_order_CD=disp_order_CD+'Ch4-Chow\t' 
              elif(dist.find("-D")!=-1):  # Channel 2 contains Choc
                disp_order_CD=disp_order_CD+'Ch4-Choc\t' 
            else: 
              # Drink Data asked
              disp_order_CD=disp_order_CD+'Ch%2-Drink\t' 
      if (r==2 or r==3):   # Intake: Channel 1, Drink 1, Channel 2, Drink 2
        for dist in self.distrib:
          if(dist.find("SC")!=-1):  # SC data
            disp_order_SC=disp_order_SC+'Ch%d-Drink\t' %(r-1)
          else: # CD data
            disp_order_CD=disp_order_CD+'Ch%d-Drink\t' %(r-1)
    
    
    # Write _SC file header
    self.handle_SC.write(self.header)
    self.handle_SC.write('\n'+cages_SC+cages_SC+'\n')
    self.handle_SC.write(disp_order_SC+'\n')
    
    # Write _CD file header
    self.handle_CD.write(self.header)
    self.handle_CD.write('\n'+cages_CD+cages_CD+'\n')
    self.handle_CD.write(disp_order_CD+'\n')
    

  def SplitData(self):
    '''Splits required data into SC and CD mice type'''
    self.SC_data='' # Chow mice data
    self.CD_data='' # Choc mice data

    # Classify data  into SC or CD
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
        if(dist.find("SC")!=-1):  # SC data
          self.SC_data=self.SC_data+datum+'\t'
        elif(dist.find("CD")!=-1):  # CD data 
          self.CD_data=self.CD_data+datum+'\t'
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
      # Split Data into SC or CD
      self.SplitData()
      # Store data 
      self.handle_SC.write(self.SC_data+'\n')
      self.handle_CD.write(self.CD_data+'\n')
      self.TimeCounter+=1
      line = self.handle.readline()
    

  def CreateMatrix(self):
    '''Reads .mtb file, creates a matrix with the useful data and stores it into a file'''
  
    # Get Cage dispensers distribution
    self.GetDispenserDistrib()

    # Get Acquisition Date and Time
    self.GateDateTime()
    
    # Write _SC/_CD files header
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
    self.handle_SC.close()
    self.handle_CD.close()

  
  def AddEndDate(self):
    ''' Add End Acquisition Date to Data Files '''

    # Add Stop Date and Time
    self.handle_SC.write('Stop Date and Time:\t'+self.EndDate+'\n')
    
    # Add Stop Date and Time
    self.handle_CD.write('Stop Date and Time:\t'+self.EndDate+'\n')


def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Data Searcher
  try:
    GetData=DataSearcher(argv[2],argv[1])
  except ValueError:
    sys.stderr.write( "\nData Extraction Aborted.\n" )
    return

  # Create data matrices (_SC and _CD) from .mtb file containing required data
  GetData.CreateMatrix()

  # Add End Acquisition Date and time
  GetData.AddEndDate()

  # Close files
  GetData.CloseInFiles()
  GetData.CloseOutFiles()


if __name__=="__main__":
  main()






     
