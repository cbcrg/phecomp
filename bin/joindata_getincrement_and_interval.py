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
    sys.stderr.write("\nPheCom Joining Data Files Tool.\nCreates a single file appending the content of all filenames provided.Data format: eating amount (increment)\n")
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
    temp=file_list[0][:-4].split('/') # Get file characteristics + data acquisition date
    OldFileNamePrint=temp[-1].split('_')
    # Compare file Characteristics
    for filename in file_list[1:]:
      temp=filename[:-4].split('/') # Get file characteristics + data acquisition date
      FileNamePrint=temp[-1].split('_')
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
    self.handle_out1.write(self.FileInfo[0]['Header'])   # Main header
    self.handle_out2.write(self.FileInfo[0]['Header'])   # Main header
    # Write Start, Stop and Gap Adquisition times
    for i in range(len(self.FileInfo)):
      self.handle_out1.write('Start Date and Time:\t'+self.FileInfo[i]['StartDate']+'\n') # Start date 
      self.handle_out2.write('Start Date and Time:\t'+self.FileInfo[i]['StartDate']+'\n') # Start date 
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
    disp=self.FileInfo[0]['DispDist'].split() # Dispensers List
    disp_type_list=[]
    for d in disp:
      f=d[-4:]
      disp_type_list.append(f)  
    if (self.opt=='k') :
      # Keep data splited into dispensers
      # Data Distribution
      for key in self.FileInfo.keys():
        # Read all data in each file and classify per cage dispenser
        line = self.FileInfo[key]['Handle'].readline()  #
        index=len(self.FileInfo[key]['CageList'].split())
        counter=[]
        #print index
        for i in range(index):
          counter.append(0)  # for calculating interval durations
        #print counter
        while (line.find("Stop Date")==-1):   # End of the data
          info=line[:-1].split('\t')  # Separate data by dispensers
          for i in range(len(info)):
            if (info[i]!='0.00'):
              "if counter[i]< 60000:"
              duration='%d '% counter[i]
              self.TempHandle[i].write(duration)  # Store data into its corresponding file
              #print duration
              counter[i]=0  # Restart counter for next interval
            else:
              counter[i] +=1 
          line = self.FileInfo[key]['Handle'].readline()  #
        for i in range(index):
          if counter[i]!=0: # Last value was a non eating event. Last interval duration must be registered
            '''if counter[i]<60000:   '''
            duration='%d '% counter[i]
            #print duration
            self.TempHandle[i].write(duration)  # Store interval duration
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
        index=len(self.FileInfo[key]['CageList'].split())/2
        counter=[]
        dispenser=[]
        for i in range(index):
          counter.append(0)  # for calculating interval durations
          dispenser.append('')
        while (line.find("Stop Date")==-1):   # End of the data
          #j=0
          #while j<8000:   # End of the data
          info=line[:-1].split('\t')  # Separate data by dispensers
          #print info
          for i in range(len(info)/2):
            # Merge Data
            if (info[i]!='0.00' or info[i+6]!='0.00'):  # Mouse eat
              "if counter[i]<60000:  " 
              duration='%d '% counter[i]
              self.TempHandle[i].write(duration)  # Store interval duration
              counter[i]=0  # Restart counter for next interval
              # find the dispenser and get the type
              if (info[i]!='0.00'):
                disp_type=disp_type_list[i]
                dispenser[i]+=info[i]+disp_type[-1]+' '
                #self.TempHandle[i].write(info[i]+disp_type[-1]+' ')  # Store data into its corresponding file

              else:
                disp_type=disp_type_list[i+6]
                dispenser[i]+=info[i+6]+disp_type[-1]+' '
                #self.TempHandle[i].write(info[i+6]+disp_type[-1]+' ')  # Store data into its corresponding file
              '''disp1=float(info[i])  # Convert Ascii data into float
              disp2=float(info[i+6])  # Convert Ascii data into float
              if (disp1>disp2):
                self.TempHandle[i].write(info[i]+' ')  # Store data into its corresponding file
              else:
                self.TempHandle[i].write(info[i+6]+' ')  # Store data into its corresponding file'''
            else:  # Mouse did not eat at any dispenser
              counter[i] +=1 
              # self.TempHandle[i].write('0.00 ')  # Store data into its corresponding file
          line = self.FileInfo[key]['Handle'].readline()  #
          #j+=1
        # Store Stop Acquisiton Date for each file
        for i in range(index):
          if counter[i]!=0: # Last value was a non eating event. Last interval duration must be registered
	    "if counter[i]<60000:"
            duration='%d\n'% counter[i]
            self.TempHandle[i].write(duration)  # Store interval duration
            dispenser[i]+='0x '
            '''else:
              self.TempHandle[i].write('\n')  #  '''
          self.TempHandle[i].write(dispenser[i]+'\n')

        self.FileInfo[key]['StopDate']=line[line.find(":\t")+2:-1]  # Get Stop Date
        # Convert date and time to a time expressed in seconds
        date=time.strptime(self.FileInfo[key]['StopDate'], "%d/%m/%Y %H:%M:%S") # Get stop date and time
        self.FileInfo[key]['StopDateSec']=time.mktime(date)
        # Close file after whole content read
        self.FileInfo[key]['Handle'].close()  

    # Close Temporal Files
    for i in range(len(self.TempHandle)):
      self.TempHandle[i].close()
    

  def Interval2Bin(self,duration):
    ''' Converts an interval duration into the correspondent bin '''
    # Store the interval duration in bins. The distribution of intervals in bins 
    # 10 bin SC data
    duration=int(duration)
    if duration < 57:
      return '1 '
    elif duration < 104:
      return '2 '
    elif duration < 162:
      return '3 '
    elif duration < 238:
      return '4 '
    elif duration < 350:
      return '5 '
    elif duration < 537:
      return '6 '
    elif duration < 952:
      return '7 '
    elif duration < 2106:
      return '8 '
    elif duration < 4771:
      return '9 '
    else:
      return '10 '
    # 10 bin CD data
    '''if duration < 64:
      return '1 '
    elif duration < 116:
      return '2 '
    elif duration < 175:
      return '3 '
    elif duration < 246:
      return '4 '
    elif duration < 351:
      return '5 '
    elif duration < 529:
      return '6 '
    elif duration < 863:
      return '7 '
    elif duration < 1513:
      return '8 '
    elif duration < 3251:
      return '9 '
    else:
      return '10 '''
    # 20 bin SC data
    '''if duration < 37:
      return '1 '
    elif duration < 57:
      return '2 '
    elif duration < 79:
      return '3 '
    elif duration < 105:
      return '4 '
    elif duration < 133:
      return '5 '
    elif duration < 166:
      return '6 '
    elif duration < 204:
      return '7 '
    elif duration < 255:
      return '8 '
    elif duration < 320:
      return '9 '
    elif duration < 404:
      return '10 '
    elif duration < 522:
      return '11 '
    elif duration < 682:
      return '12 '
    elif duration < 974:
      return '13 '
    elif duration < 1425:
      return '14 '
    elif duration < 2061:
      return '15 '
    elif duration < 3182:
      return '16 '
    elif duration < 4605:
      return '17 '
    elif duration < 6696:
      return '18 '
    elif duration < 11299:
      return '19 '
    else:
      return '20 '''
   # 20 bin CD data
    '''if duration < 40:
      return '1 '
    elif duration < 69:
      return '2 '
    elif duration < 91:
      return '3 '
    elif duration < 118:
      return '4 '
    elif duration < 148:
      return '5 '
    elif duration < 181:
      return '6 '
    elif duration < 216:
      return '7 '
    elif duration < 257:
      return '8 '
    elif duration < 305:
      return '9 '
    elif duration < 371:
      return '10 '
    elif duration < 454:
      return '11 '
    elif duration < 567:
      return '12 '
    elif duration < 719:
      return '13 '
    elif duration < 923:
      return '14 '
    elif duration < 1221:
      return '15 '
    elif duration < 1713:
      return '16 '
    elif duration < 2523:
      return '17 '
    elif duration < 3914:
      return '18 '
    elif duration < 6369:
      return '19 '
    else:
      return '20 '''
 

  def JoinTempFiles(self):
    ''' Join Temporal files'''
    # Open Final Joined Data File
    try:
        self.handle_out1=open(self.FileInfo[0]['FileName'][:-4]+'_'+self.opt+'_int_incr.jnd', 'w') # Create/Open the file
    except:
        sys.stderr.write("Unable create joined data file\n")
        raise ValueError()
    
    # Open Final Joined Data File
    try:
        self.handle_out2=open(self.FileInfo[0]['FileName'][:-4]+'_'+self.opt+'_bin_incr.jnd', 'w') # Create/Open the file
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
      #self.handle_out1.write(cages[i]+'-'+disp[i]+'\n')
      #self.handle_out2.write(cages[i]+'-'+disp[i]+'\n')
      line=self.TempHandle[i].readline()
      while line!='':
        self.handle_out1.write(cages[i]+'-'+disp[i]+'\n')
        self.handle_out2.write(cages[i]+'-'+disp[i]+'\n')
        self.handle_out1.write(line[:-1]+'\n')
        '''intervals=line.split()
        line=''
        for interval in intervals:
          line+=self.Interval2Bin(interval)
        self.handle_out2.write(line+'\n')'''
        line=self.TempHandle[i].readline()
      
    # Add List of symbols at the end of the file
    '''line='SYMBOLS\n'
    self.handle_out2.write(line)
    line=''
    for i in range (1,11):
     line+='%d ' %i
    self.handle_out2.write(line+'\n')'''

    # Close Temporal Files
    for i in range(len(self.TempHandle)):
      self.TempHandle[i].close()
    
    # Remove Temporal Files
    for path in self.TempPath:
      os.remove(path)

    # Close Joined Data File
    self.handle_out1.close()
    self.handle_out2.close()


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



