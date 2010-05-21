# PheCom Data Joining Tool 
#
# Author: Isabel Fernandez <isabel.fernandez @ crg.cat>

''' PheCom Joining Data Files Tool. Creates a single file appending the content of all filenames provided. Transposes data in order to have a single row of data per each cage dispenser.
    Usage:
          joindata [OPTION] input_file1 input_file2 ... input_fileN
    where:
       'input_fileX' is a matrix .mtx file
   OPTIONS:
	m	Merge data from dispensers in the same cage
	k	Keeps data splited into dispensers

'''   

import sys
from sys import *
import string
import time
import os


def CheckArguments(arg):
  ''' Checks that the user introduces the correct number of arguments '''
  if(len(arg)<3):
    # Not enough arguments
    sys.stderr.write("\nPheCom Joining Data Files Tool.\nCreates a single file appending the content of all filenames provided. Data stored is eating amount (increments)\n")
    sys.stderr.write("Usage:\t python %s [OPTION] input_file1 input_file2 ... input_fileN\n" % arg[0])
    sys.stderr.write("where:\n'input_fileX' is a matrix .mtx file\n")  
    sys.stderr.write("OPTIONS:\n")
    sys.stderr.write("\tm\tMerge data from dispensers in the same cage\n") 
    sys.stderr.write("\tk\tKeeps data splited into dispensers\n") 
    sys.stderr.write("Error: Not enought arguments\n")
    sys.exit()
  

class Joiner:
  ''' Joins provided data files in a single file '''

  def __init__(self,opt,file_list):
    # Class Constructor
    
    # Store Files Name for further use 
    self.file_list=file_list

    self.opt=opt # Store data option
  
    # Check data option
    try: 
      self.CheckOption()
    except:
      raise ValueError()

    # Check files types (avoid mix SC with CD, binary with analog, food with drink or intake ...)
    try:
      self.CheckFilesTypes(file_list)
    except:
      sys.stderr.write("Data Files join aborted.\n")
      raise ValueError()
    
    # Open all files in file_list
    try:
      self.OpenFile(file_list)
    except:
      sys.stderr.write("Data Files join aborted.\n")
      raise ValueError()
    
    
  def CheckOption(self):
    '''Check for correct data option '''
    if (self.opt!='m' and self.opt!='k'):
      sys.stderr.write("Error:Undefined Option\n")
      raise ValueError()     

  def CheckFilesTypes(self, file_list):  
    ''' Check files types (avoid mix SC with CD, binary with analog, food with drink or intake ...) '''
    FileNamePrint=[]     # Stores file characteristics (SC/CD, food/drink/intake, binary/analog)
    OldFileNamePrint=[]  # Stores file characteristics (SC/CD, food/drink/intake, binary/analog)
    # Get characteristcs of 1st file in list to compare
    OldFileNamePrint=file_list[0][:-4].split('_') # Get file characteristics + data acquisition date

    # Compare file Characteristics
    for filename in file_list[1:]:
      FileNamePrint=filename[:-4].split('_') # Get file characteristics + data acquisition date
      # Check that the number of characteristics is the same. If not, binary and analog data may be compared
      if (len(OldFileNamePrint)==len(FileNamePrint)):
        # Check that the fields are the same
        for i in range(1,len(FileNamePrint)):
          if(OldFileNamePrint[i]!=FileNamePrint[i]):  # Different characteristics must not be joined
            sys.stderr.write("Error: Different file types to be joined.\n")
            raise ValueError()
          
      else:
        sys.stderr.write("Error: Different file types to be joined.\n")
        raise ValueError()
   

  def OpenFile(self,file_list):
    ''' Open files '''
    self.handles=[]  # Stores file handles of filenames provided
    for filename in file_list:
      # Open .mtx file
      if (filename.endswith('.mtx')):
        try: 
          self.handles.append(open(filename,'r'))
        except: 
          sys.stderr.write("Unable to open %s" % filename)
          raise ValueError()
      else :
         sys.stderr.write("Error: .mtx file expected!\n")
         raise ValueError()
    
       
  def GetFileInfo(self):
    ''' Get information from each file in order to be able to sort files chronologically (by starting date) and keep some info for writting the joined file header '''
    self.FileInfo={}
     
    for f in range(len(self.handles)):
      info={}
      line=self.handles[f].readline()
      info['Header']=line     # Get File Header
      line=self.handles[f].readline()
      info['StartDate']=line[line.find(":\t")+2:-1]  # Get Start Date
      line=self.handles[f].readline()
      line=self.handles[f].readline()
      info['CageList']=line   # Get Cage List
      line=self.handles[f].readline()
      info['DispDist']=line   # Get Dispenser Distribution
      info['Handle']=self.handles[f]
      info['FileName']=self.file_list[f]
      # Save all this info from current file
      self.FileInfo[f]=info 
    
      
    
  def SortFiles(self):
    ''' Order file handles so they are joined cronologically (by starting date) '''
         
    # Convert date and time to a time expressed in seconds
    for key in self.FileInfo.keys():
      date=time.strptime(self.FileInfo[key]['StartDate'], "%d/%m/%Y %H:%M:%S") # Get start date and time
      self.FileInfo[key]['StartDateSec']=time.mktime(date)  # Convert date and time to a time expressed in seconds
    
    # Order the files
    self.SortedFiles=[(self.FileInfo[key]['StartDateSec'],self.FileInfo[key]) for key in self.FileInfo.keys()] # Schwartzian transform  
    self.SortedFiles.sort()
    # Safe files sorted
    for i in range(len(self.SortedFiles)):
      self.FileInfo[i]=self.SortedFiles[i][1]
    

  def Seconds2String(self,sec):
    '''Convert time interval in seconds into readable string '''
    readable = []
    days, seconds= divmod(sec,86400)
    if days > 1:
      readable.append("%d days" % days)
    elif days == 1:
      readable.append("1 day")
    hours, seconds = divmod(seconds, 3600)
    if hours > 1: 
      readable.append("%d hours" % hours)
    elif hours == 1:
      readable.append("1 hour")
    minutes, seconds = divmod(seconds, 60)
    if minutes > 1:
      readable.append("%d minutes" % minutes)
    elif minutes == 1:
      readable.append("1 minute")
    if seconds == 1: 
      readable.append("1 second")
    elif not readable or seconds > 1:
      if isinstance(seconds, int) or isinstance(seconds, long):
	readable.append("%s seconds" % seconds)
      else: readable.append("%.0f seconds" % seconds)
    
    return " ".join(readable)

  
  def GetAcquisitionGap(self):
    ''' Calculates Acquisition Gaps '''
    self.TimeGaps=[]
    
    # Get the Acquisition Gaps in seconds
    self.TimeGaps=[self.FileInfo[i+1]['StartDateSec']-self.FileInfo[i]['StopDateSec'] for i in range(0,len(self.FileInfo)-1)]
    # Convert Acquisition Gaps to days, hours, minutes and seconds
    for i in range(len(self.TimeGaps)):
      self.TimeGaps[i]=self.Seconds2String(self.TimeGaps[i])
      
             
  def CheckDataDistribution(self):
    ''' Check that dispensers are distributed in the same order'''
    CageDist=[]  
   
    # Get Cage Distribution of 1st file in list to compare
    OldCageDist=self.FileInfo[0]['CageList'].split('\t') 
    for i in range(1,len(self.FileInfo)):
      NewCageDist=self.FileInfo[i]['CageList'].split('\t') 
      if (OldCageDist!=NewCageDist): # Different cage distributions must not be joined
        sys.stderr.write("Error: Different dispenser distributions to be joined.\n")
        raise ValueError()
   

  def WriteHeader(self):
    ''' Write header of joined file'''
    # Since Data is same type (already checked), copy header and cages distribution from first file
    self.handle_out.write(self.FileInfo[0]['Header'])   # Main header
    # Write Start, Stop and Gap Adquisition times
    for i in range(len(self.FileInfo)):
      self.handle_out.write('Start Date and Time:\t'+self.FileInfo[i]['StartDate']+'\n') # Start date 
      '''self.handle_out.write('\tStop Date and Time:\t'+self.FileInfo[i]['StopDate']+'\n') # Stop date 
      if (i<len(self.FileInfo)-1):
        self.handle_out.write('Gap:\t'+self.TimeGaps[i]+'\n') # Time Gap'''
  
   
  def OpenTempFiles(self,mode):
    ''' Opens Temporary Files to store joinded data (.tmp)'''
    self.TempHandle=[]
    self.TempPath=[]
    cages=self.FileInfo[0]['CageList'].split() # Cages List
    disp=self.FileInfo[0]['DispDist'].split() # Dispensers List
    path=os.getcwd()+'/'
   
    if (self.opt=='m'):
      # Merge dispensers in the same cage
      filenumber= len(cages)/2
    else:
      # Keep data splited into dispensers
      filenumber=len(cages)

    for i in range(filenumber):
      self.TempPath.append(path+cages[i]+'_'+disp[i]+'.tmp')
      # Create a file for each dispenser
      try:
        self.TempHandle.append(open(self.TempPath[i], mode)) # Create/Open the file
      except:
        sys.stderr.write("Unable create temporal data file\n")
        raise ValueError()


  def JoinData(self): 
    ''' Joins data of all input files.  Stores it in independent temporal files '''
    
    # Open Temporary Output Files
    self.OpenTempFiles('w')    
    
    if (self.opt=='k') :
      # Keep data splited into dispensers
      # Data Distribution
      for key in self.FileInfo.keys():
        # Read all data in each file and classify per cage dispenser
        line = self.FileInfo[key]['Handle'].readline()  #
        while (line.find("Stop Date")==-1):   # End of the data
          info=line[:-1].split('\t')  # Separate data by dispensers
          for i in range(len(info)):
            self.TempHandle[i].write(info[i]+' ')  # Store data into its corresponding file
          line = self.FileInfo[key]['Handle'].readline()  #
        # Store Stop Acquisiton Date for each file
        self.FileInfo[key]['StopDate']=line[line.find(":\t")+2:-1]  # Get Stop Date
        # Convert date and time to a time expressed in seconds
        date=time.strptime(self.FileInfo[key]['StopDate'], "%d/%m/%Y %H:%M:%S") # Get stop date and time
        self.FileInfo[key]['StopDateSec']=time.mktime(date)  
        # Close file after whole content read
        self.FileInfo[key]['Handle'].close()  
    else:
      # Merge data from dispensers in the same cage
      # Data distribution
      for key in self.FileInfo.keys():
        # Read all data in each file and classify per cage dispenser. Merge data of dispensers in the same cage (OR)
        line = self.FileInfo[key]['Handle'].readline()  #
        while (line.find("Stop Date")==-1):   # End of the data
          #j=0
          #while j<8000:   # End of the data
          info=line[:-1].split('\t')  # Separate data by dispensers
          #print info
          for i in range(len(info)/2):
            # Merge Data
            if (info[i]!='0.00' or info[i+6]!='0.00'):  # Mouse ate at one or both dispensers
              disp1=float(info[i])  # Convert Ascii data into float
              disp2=float(info[i+6])  # Convert Ascii data into float
              if (disp1>disp2):
                self.TempHandle[i].write(info[i]+' ')  # Store data into its corresponding file
              else:
                self.TempHandle[i].write(info[i+6]+' ')  # Store data into its corresponding file
            else:  # Mouse did not eat at any dispenser
              self.TempHandle[i].write('0.00 ')  # Store data into its corresponding file
          line = self.FileInfo[key]['Handle'].readline()  #
          #j+=1
        # Store Stop Acquisiton Date for each file
        self.FileInfo[key]['StopDate']=line[line.find(":\t")+2:-1]  # Get Stop Date
        # Convert date and time to a time expressed in seconds
        date=time.strptime(self.FileInfo[key]['StopDate'], "%d/%m/%Y %H:%M:%S") # Get stop date and time
        self.FileInfo[key]['StopDateSec']=time.mktime(date)
        # Close file after whole content read
        self.FileInfo[key]['Handle'].close()  

    # Close Temporal Files
    for i in range(len(self.TempHandle)):
      self.TempHandle[i].close()

     
  def JoinTempFiles(self):
    ''' Join Temporal files'''
    # Open Final Joined Data File
    try:
        self.handle_out=open(self.FileInfo[0]['FileName'][:-4]+'_'+self.opt+'.jnd', 'w') # Create/Open the file
    except:
        sys.stderr.write("Unable create joined data file\n")
        raise ValueError()
    
    # Open Temporary Output Files
    self.OpenTempFiles('r')    
    
    '''# Calculate Acquisition Gaps
    self.GetAcquisitionGap()'''
   
    # Write Header
    self.WriteHeader()

    # Data Distribution
    if (self.opt=='k'):
      # Keep data splited into dispenser
      cages=self.FileInfo[0]['CageList'].split() # Cages List
      disp=self.FileInfo[0]['DispDist'].split() # Dispensers List
    else:
      # Merge data from the dispensers in the same cage
       cages=self.FileInfo[0]['CageList'].split() # Cages List
       cages=cages[:len(cages)/2]
       disp=['' for i in cages]

    # Write Data
    for i in range(len(self.TempHandle)):
      self.handle_out.write(cages[i]+'-'+disp[i]+'\n')
      line=self.TempHandle[i].readline()
      self.handle_out.write(line+'\n')
    
    # Close Temporal Files
    for i in range(len(self.TempHandle)):
      self.TempHandle[i].close()

    # Remove Temporal Files
    for path in self.TempPath:
      os.remove(path)

    # Close Joined Data File
    self.handle_out.close()


  def JoinFiles(self):
    '''Reads .mtx files and joins data in a single file'''
    
    # GetFileInfo
    self.GetFileInfo ()
    
    # Order file handles so they are joined cronologically (by starting date)
    self.SortFiles()
    
    # Check that dispensers are distributed in the same order
    self.CheckDataDistribution()
   
    # Join data
    self.JoinData()

    # Join Temporal files
    self.JoinTempFiles()
        
    
def main():
  
  # Checks that the user introduces the correct number of arguments
  CheckArguments(argv)

  # Start Joiner Object
  try:
    ToJoin=Joiner(argv[1],argv[2:])
  except ValueError:
    sys.stderr.write( "Files Joining aborted.\n" )
    return

  # Join Files
  ToJoin.JoinFiles()

 
if __name__=="__main__":
  main()






     
