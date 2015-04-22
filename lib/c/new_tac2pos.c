/*
 * readAct.c
 *
 *  Created on: May 26, 2011
 *      Author: jespinosa
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Reading tac files
 *
 * Compilation:
 * gcc tac2pos.c -o tac2pos
 * Execution tac2pos -file foo.tac -action position
 *
 * */

//Header for the declaration decl.h

typedef struct
  {
	char id [4];
	int size;
	char type[4];
  } chunk;

typedef struct
  {
	char id[4];
	int size;

	//This part corresponds to fmtCabecera
	int version;
	char endName[1];
	char name[35];
	double creationDate;
	double modDate;
	int reserved; //not used
	int trajectories;

  } experimentHeader;

typedef struct
  {
	char id[4];
	int size;
	char endName[1]; //this part should be developed if we want to get exactly the important part of the string
	char name[255];
  } remarks;

//CHUNK TRACK-----------------

typedef struct
  {
	char id[4];
	int size;
	char listType[4];
  } trackInfo;

typedef struct
  {
	char id[4];
	int size;
  } trackFormat;

////Corresponds to prjFmtTrayectoria
//typedef struct
//  {
//	int version;
//	  char endExperimenter[1];
//	  char experimenter[35];
//	  char endIdAnimal[1];
//	  char idAnimal[23];
//	  double date;
//	  int NTrackFile;
//	  float samplingTime;
//	  char endcalUnit[1];
//	  char calUnit[10];
//	  float horCal;
//	  float verCal;
//	  int NPoints;
//  } trackHeader;

typedef struct
  {
	char id[4];
	int size;
	char remarks[256];
  } trackRemarksFormat;

typedef struct
  {
    char id[4];
    int size;
  } trackPointList;

//typedef struct
//  {
//	trackInfo trInfo;
//	trackFormat trFormat;
//	trackHeader trHeader;
//	trackRemarksFormat trRmFormat;
//	trackPointList trPointList;
//  } track;

  /*float hCal, float vCal, int nTrack, char * fileName)
  {
    //pasarle el tiempo inicial printar t + ctr y el ctr aprovecharlo para printar el index!! #del*/
typedef struct
  {
	float hCal;
	float vCal;
	int nTrack;
	int iniTrTime;
	char * fileName;
  } info2coord;

typedef struct
  {
	char * fileName;
	int fileId;
  } readOnce;

//Function declaration
//functions should be inside decl.c
int readHeader (char **fl, int start, int nFiles);
int printHeader (FILE *fd, char * name);
//readOnce * printHeader (FILE *fd, char * name);
int readCoord (char **fl, int start, int nFiles);
int printCoord (FILE *fd, char *fileName);
int readDate (char **fl, int start, int nFiles);
int getDate (FILE *fd, char * name);
//void printDate (FILE *fd, int tracks, char * fileName);
int printDate (FILE *fd, int tracks, char * fileName);
void fileProcessing (FILE *fd, char * name);
chunk returnChunkHeader (FILE *fd);
int countBytes (FILE *fd);
void asessTag (char fileTag[], char Tag[]);
//void readCoordinates (int size, FILE *fd, float hCal, float vCal, int nTrack, char * fileName);//#del
void readCoordinates (int size, FILE *fd, info2coord * info);
int excelTime2EPOCH (double dateTrack);
char * returnTimeString (double EPOCHseconds, int n);
void printTrackHeaders (FILE * fd, int tracks, char * fileName);
char * addEnd2string (char * string, int size);
int getNumbFiles (char ** argList, int startPos, int endList);
int fileCheck (char **fl, int start, int nFiles);

/************************************************************************************************************
 *tac2pos.c
 ************************************************************************************************************
 *Reads tac binary files generated by ACTITRACK during data acquisition, this files have the animal position
 *for each animal and time point during the experimental time
 ************************************************************************************************************
 *OPTIONS
 *-file   <file>.........file: input binary file to be processed;
 *-action <mode> ........mode: 'date' get the starting EPOCH time when recording has started;
 *                             'position' get the position coordinate for the specified files.
 ************************************************************************************************************
 */


int main (int argc, char *argv[])

{
  int startListFiles = 0;
  int nFiles = 0;
  int i = 0;
  //int endFileList = 0;//#del

  for (i = 1; i < argc; i++)
  {
	  //fprintf (stderr, "the value of i is %i\n",i);//#del
	  //fprintf (stderr, "------------the command is-------------- %s\n",argv[i]);//#del

	  if (i == 1 && argv[1][0] != '-') //files directly without option
	  {
		  startListFiles = i;
		  nFiles = getNumbFiles (argv, i, argc);
		  //fprintf (stderr, "We find files directly!  %i\n", nFiles);//#del
		  i = (i + nFiles) - 1;
		  //fprintf (stderr, "Number of files is %i\n", nFiles);//#del
	  }

	  else if (strcmp (argv[i], "-file") == 0)
	  {
		  startListFiles = i+1;
		  nFiles = getNumbFiles (argv, i+1, argc);

		  //fprintf (stderr, "%i\n", startListFiles);//#del
		  //fprintf (stderr, "number of files after function --- %i\n", nFiles);//#del

		  i += nFiles;
	  }

	  else if (strcmp (argv[i], "-action" ) == 0)
	  {
		  //fprintf (stderr, "the command is %i\t%i\n",i,argc);

		  //Assess that binary files are not empty
		  fileCheck (argv, startListFiles, nFiles);

		  if (i+1 == argc || (argv[i+1][0] == '-') )
			  //|| (argv[i+1][0] != '-'))
		  //if (strcmp (argv[i+1], "coordinates") == 0 || (i-1 == argc) || (argv[i+1][0] != '-'))
		  {
			  fprintf (stderr, "FATAL ERROR: -action flag option not provided (position, date)!\n");
			  exit (EXIT_FAILURE);
		  }

		  else if (strcmp (argv[i+1], "position") == 0)
		  {
			  //fprintf (stderr, "Chosen option is position\n");//#del

			  readHeader (argv, startListFiles, nFiles);
			  readCoord (argv, startListFiles, nFiles);
			  return (EXIT_SUCCESS);
		  }

		  else if (strcmp (argv[i+1], "date") == 0)
		  {
			  if (nFiles == 1)
			  {
				  //fprintf (stderr, "---------- Read date option -----------!\n");//#del
				  readDate (argv, startListFiles, nFiles);
				  return (EXIT_SUCCESS);
			  }
			  else
			  {
				  fprintf (stderr, "FATAL ERROR: \"-action date\" option could only be used with a single input file!\n");
				  exit (EXIT_FAILURE);
			  }
		  }
	  }

	  else
	  	  {
		  	  fprintf (stderr, "FATAL ERROR: \"%s\" option not recognized!\n", argv[i]);
		  	  exit (EXIT_FAILURE);
	  	  }
//	  else if (startListFiles != 0 && (argv[i][0] == '-'))
//	  {
//		  nFiles = i-1;
//		  puts ("caca"); exit (1);
//	  }

	  //printf("argv[%d]: %s\n", i, argv[i]); //#del

  }

//  exit (1);
//  readHeader (argv, startListFiles, nFiles);
//  exit (1);
//  readCoord (argv, startListFiles, nFiles);

  return 0;
}

/*Functions
*/

int fileCheck (char **fl, int start, int nFiles)
{
	int fc = 0;
	int end = 0;
	int empty = 0;
	end = start + nFiles;

	for (fc = start; fc < end; fc += 1)
	{
		FILE *fd;

		char * fileName;
		fileName = fl[fc];
		fd = fopen (fileName, "rb");

		if ( fd == NULL )
		{
			fprintf (stderr, "FATAL ERROR:Cannot open file %s!\n", fileName);
			exit (EXIT_FAILURE);
		}

		fseek (fd, 0L, SEEK_END);
		empty = ftell (fd) == 0L;

		if (empty == 1 )
		{
			fprintf (stderr, "FATAL ERROR:File %s is empty!\n", fileName);
			exit (EXIT_FAILURE);
		}

	}

	return 0;
}

int readHeader (char **fl, int start, int nFiles)
  {
	int fc = 0;
	int end = 0;

	end = start + nFiles;
	//fprintf (stderr, "---start----%i---nFiles----%i---end---%i\n", start, nFiles, end);//#del

	for (fc = start; fc < end; fc += 1)
	{
		 FILE *fd;

		 char * fileName;
		 fileName = fl[fc];
		 //fprintf (stderr, "--------filenames is --- %s---------\n", fileName);//#del
		 fd = fopen (fileName, "rb");

		 if ( fd == NULL )
		 {
		   fprintf (stderr, "FATAL ERROR:Cannot open file %s!\n", fileName);
		   exit (EXIT_FAILURE);
	     }

		 printHeader (fd, fileName);

		 fclose (fd);
	}

	return 0;
  }


int printHeader (FILE *fd, char * name)
//readOnce * printHeader (FILE *fd, char * name)
{
	//char msg[]="test";//#del
	//fprintf (stderr, "%s\n", msg);

	//readOnce * infoFile;
	chunk fileHeader;
	fileHeader = returnChunkHeader (fd);

	asessTag (fileHeader.id, "RIFF");

	//fprintf (stderr, "Annotated file size: %d \n", fileHeader.size);//chivato


	int count = 0;
	//WE HAVE TO ADD FOUR BYTES BECAUSE I'VE ALREADY READ THE TYPE INSIDE FILEHEADER SO THE FILE POINTER IS DISPLACED +4
	count = countBytes (fd) + 4;

	if (count != fileHeader.size)
	{
		fprintf (stderr, "ERROR: Annotated file (%i) size does not match real file size (%i)!\n", fileHeader.size, count);//chivato
		exit (EXIT_FAILURE);
	}

	//fprintf (stderr, "Size until end of file: %i \n", count);//chivato

	//exit (EXIT_FAILURE);
	chunk experimentInfo;
	experimentInfo = returnChunkHeader (fd);

	/*#DEL
	fprintf (stderr, "id: %s \n", experimentInfo.id);//chivato
	fprintf (stderr, "size: %i \n", experimentInfo.size);//chivato
	fprintf (stderr, "type: %s \n", experimentInfo.type);//chivato
	*/

	experimentHeader expHeader;
	fread (&expHeader, sizeof expHeader, 1, fd);
	asessTag (expHeader.id, "fmt ");

	/*#del
	fprintf (stderr, "id: %s \n", expHeader.id);//chivato
	fprintf (stderr, "size: %i \n", expHeader.size);//chivato
	fprintf (stderr, "trajectories: %i \n", expHeader.trajectories);//chivato
	fprintf (stderr, "Creation date excel format: %f\n", expHeader.creationDate);

	//unsigned char ch = (unsigned char)expHeader.endName[0];
	fprintf (stderr, "endName: %d \n", expHeader.endName[0]);//chivato
	fprintf (stderr, "Name: %s \n", expHeader.name);//chivato
	*/

	remarks expRemarks;
	fread (&expRemarks, sizeof expRemarks, 1, fd);
	asessTag (expRemarks.id, "cmnt");
	/*#del
	fprintf (stderr, "Exp remarks size: %d \n", expRemarks.size);
	fprintf (stderr, "Exp remarks endName: %d \n", expRemarks.endName[0]);//chivato
	fprintf (stderr, "Exp remarks Name: %s \n", expRemarks.name);//chivato
	*/

	//PRINTING FILE HEADERS
	//char name2print[35] = expHeader.name; //if we don't know the size use malloc
	//Preparing string variables to be print. Not changes in the structure if not all get mixed
	char * name2print;
	char * comments2print;

	name2print = addEnd2string (expHeader.name, (unsigned char) expHeader.endName[0]);
	comments2print = addEnd2string (expRemarks.name, (unsigned char) expRemarks.endName[0]);

	//substitute by function addEnd2string
	/*char name2print [expHeader.endName[0]];
	strncpy (name2print, expHeader.name, expHeader.endName[0]);
	name2print [(unsigned char)expHeader.endName[0]] = '\0';

	char comment2print [expRemarks.endName[0]];
	strncpy (comment2print, expRemarks.name, expRemarks.endName[0]);
	comment2print [(unsigned char)expRemarks.endName[0]] = '\0';*/

	char * date2printCreation;
	char * date2printMod;

	date2printCreation = returnTimeString (expHeader.creationDate, 80);
	date2printMod = returnTimeString (expHeader.modDate, 80);

	fprintf (stdout, "#h;%s;TRACKING FILE;TRACKING FILE;Comments;%s\n", name, comments2print);
	fprintf (stdout, "#h;%s;TRACKING FILE;TRACKING FILE;Code;%s\n", name, name2print);
	fprintf (stdout, "#h;%s;TRACKING FILE;TRACKING FILE;File Creation Date & Time;%s", name, date2printCreation);
	fprintf (stdout, "#h;%s;TRACKING FILE;TRACKING FILE;Number of Trackings;%i\n", name, expHeader.trajectories);
	fprintf (stdout, "#h;%s;TRACKING FILE;TRACKING FILE;Last Modification Date & Time;%s", name, date2printMod);
	fprintf (stdout, "#h;%s;TRACKING FILE;TRACKING FILE;File Name;%s\n", name, name);
	fprintf (stdout, "#h;%s;HEADER;EHEADER;Ncages;%i\n", name, expHeader.trajectories);//DO THE ASSIGMENT OF THE END STRING


	//TRACK STUFF BEGINS HERE, IT SHOULD BE IN A LOOP OF THE NUMBER O TRACKS (NUMBER OF TRAJECTORIES WILL BE THE COUNTER)
	//Printing tracks header first

	printTrackHeaders (fd, expHeader.trajectories, name);

	//infoFile->fileId = 1;
	//return 0;
	//return infoFile;
	return EXIT_SUCCESS;
}

int readCoord (char **fl, int start, int nFiles)
  {
	int fc =0;
	int end = 0;

	end = start + nFiles;
	//fprintf (stderr, "---start----%i---nFiles----%i---end---%i\n", start, nFiles, end); //#del

	for (fc = start; fc < end; fc += 1)
	{
		 FILE *fd;

		 char * fileName;
		 fileName = fl[fc];

		 fd = fopen (fileName, "rb");

		 if ( fd == NULL )
		 {
			 fprintf (stderr, "FATAL ERROR:Cannot open file %s!\n", fileName);
			 exit (EXIT_FAILURE);
	     }

		 fprintf (stderr, "Reading coordinates of file ----%s----\n", fileName);

		 printCoord (fd, fileName);

		 fclose (fd);
	}

	return 0;
  }

int printCoord (FILE *fd, char *fileName)
{
	chunk fileHeader;
	fileHeader = returnChunkHeader (fd);
	chunk experimentInfo;
	experimentInfo = returnChunkHeader (fd);
	experimentHeader expHeader;
	fread (&expHeader, sizeof expHeader, 1, fd);
	remarks expRemarks;
	fread (&expRemarks, sizeof expRemarks, 1, fd);

	int Ntrack;
		  //int pdateEPOCH = 0;

		  //for (Ntrack=1; Ntrack <= 12; Ntrack +=1)
	  for (Ntrack=1; Ntrack <= expHeader.trajectories; Ntrack +=1)
	  {
		  /*#del
		  fprintf (stderr, "Track being SKIPPED +++++++++++++++++++++++++ : %d \n\n\n", Ntrack);
		  */

		  trackInfo trInfo;
		  fread (&trInfo, sizeof trInfo, 1, fd);

		  /*#del
		  fprintf (stderr, "TR id: %s \n", trInfo.id);
		  fprintf (stderr, "TR size: %d \n", trInfo.size);
		  fprintf (stderr, "TR listType: %s \n", trInfo.listType);

		  //fseek (fd, trInfo.size, SEEK_CUR);
		  */

		  trackFormat trFormat;
		  fread (&trFormat, sizeof trFormat, 1, fd);

		  int version = 0;
		  char endExperimenter[1] = "";
		  char experimenter[35] = "";
		  char endIdAnimal[1] = "" ;
		  char idAnimal[23] = "";
		  double dateTrack = 0;
		  int NTrackFile = 0;
		  float samplingTime = 0;
		  char endcalUnit[1] = "";
		  char calUnit[10] = "";
		  float horCal = 0;
		  float verCal = 0;
		  int NPoints = 0;
		  char dump[1]; //There is a error between the length in trFormat.size and what the documentation says 103 and 104
						//OJO see what happen in different files

		  fread (&version, sizeof (version), 1, fd);
		  fread (&endExperimenter, sizeof (endExperimenter), 1, fd);
		  fread (&experimenter, sizeof (experimenter), 1, fd);
		  fread (&endIdAnimal, sizeof (endIdAnimal), 1, fd);
		  fread (&idAnimal, sizeof (idAnimal), 1, fd);
		  fread (&dateTrack, sizeof (dateTrack), 1, fd);
		  fread (&NTrackFile, sizeof (NTrackFile), 1, fd);
		  fread (&samplingTime, sizeof (samplingTime), 1, fd);
		  fread (&endcalUnit, sizeof (endcalUnit), 1, fd);
		  fread (&calUnit, sizeof (calUnit), 1, fd);
		  fread (&horCal, sizeof (horCal), 1, fd);
		  fread (&verCal, sizeof (verCal), 1, fd);
		  fread (&NPoints, sizeof (NPoints), 1, fd);
		  fread (&dump, sizeof (dump), 1, fd);

		  /*#del//chivatos
		  fprintf (stderr, "TR header version: %d \n", version);//del
		  fprintf (stderr, "TR header endExperimenter: %d \n", endExperimenter[0]);//del
		  fprintf (stderr, "TR header endExperimenter: %s \n", experimenter);//del
		  fprintf (stderr, "TR header trackFile: %d \n", NTrackFile );//del

		  fprintf (stderr, "TR header horCal: %f \n", horCal);
		  fprintf (stderr, "TR header verCal: %f \n", verCal);
		  fprintf (stderr, "TR header Npoints: %d \n", NPoints);
		  //chivatos */

		  trackRemarksFormat trRmFormat;
		  fread (&trRmFormat, sizeof (trRmFormat), 1, fd);

		  trackPointList trPointList;
		  fread (&trPointList, sizeof (trPointList), 1, fd);

		  info2coord info2readCoord;

		  info2readCoord.hCal = horCal;
		  info2readCoord.vCal = verCal;
		  info2readCoord.nTrack = Ntrack;
		  info2readCoord.fileName = fileName;
		  info2readCoord.iniTrTime = excelTime2EPOCH (dateTrack);

		  //readCoordinates (trPointList.size, fd, horCal, verCal, Ntrack, fileName );
		  readCoordinates (trPointList.size, fd, &info2readCoord);
		  //readCoordinates (trPointList.size, fd, );
		  //fseek (fd, trPointList.size, SEEK_CUR); //only take comment if debugging and not reading coordinates

		  trackPointList events;

		  fread (&events, sizeof(events),1, fd);
		  /*#del
		  fprintf (stdout, "event id %s\n", events.id);
		  fprintf (stdout, "event size %d\n", events.size);
		 */

		  fseek (fd, events.size, SEEK_CUR);


	  };
	  return 0;
}

//readDate (argv, startListFiles, nFiles);
int readDate (char **fl, int start, int nFiles)
{
	int fc =0;
	int end = 0;

	end = start + nFiles;
	//fprintf (stderr, "---start----%i---nFiles----%i---end---%i\n", start, nFiles, end);//#del
	fprintf (stderr, "---------- Reading date! -----------\n");

	for (fc = start; fc < end; fc += 1)
	{
		FILE *fd;

		char * fileName;
		fileName = fl[fc];

		fd = fopen (fileName, "rb");

		if ( fd == NULL )
		{
			fprintf (stderr, "FATAL ERROR: Cannot open file %s!\n", fileName);
			exit (EXIT_FAILURE);
		}

		getDate (fd, fileName);
	}
	return (EXIT_SUCCESS);
}

int getDate (FILE *fd, char * name)
{
	chunk fileHeader;
	fileHeader = returnChunkHeader (fd);

	asessTag (fileHeader.id, "RIFF");

	int count = 0;
	//WE HAVE TO ADD FOUR BYTES BECAUSE I'VE ALREADY READ THE TYPE INSIDE FILEHEADER (RIFF) SO THE FILE POINTER IS DISPLACED +4
	count = countBytes (fd) + 4;

	if (count != fileHeader.size)
	{
		fprintf (stderr, "ERROR: Annotated file (%i) size does not match real file size (%i)!\n", fileHeader.size, count);//chivato
		exit (EXIT_FAILURE);
	}

//	12
	chunk experimentInfo;
	experimentInfo = returnChunkHeader (fd);
	fprintf (stderr, "--------%li\n", sizeof (experimentInfo));

	experimentHeader expHeader;
	fread (&expHeader, sizeof expHeader, 1, fd);
	asessTag (expHeader.id, "fmt ");

	remarks expRemarks;
	fread (&expRemarks, sizeof expRemarks, 1, fd);
	asessTag (expRemarks.id, "cmnt");

	printDate (fd, expHeader.trajectories, name);

	return EXIT_SUCCESS;
}

int printDate (FILE *fd, int tracks, char * fileName)
{
  int iniPos = 0;
  int Ntrack = 0;
  int pdateTrackEPOCH = 0;
  char fileOut[1000];
  FILE *fp;

  iniPos = ftell (fd);

  for (Ntrack=1; Ntrack <= tracks; Ntrack +=1)
  {
	int dateTrackEPOCH=0;
	char * dateString;

    trackInfo trInfo;
    fread (&trInfo, sizeof trInfo, 1, fd);

    trackFormat trFormat;
    fread (&trFormat, sizeof trFormat, 1, fd);

    int version = 0;
	char endExperimenter[1] = "";
	char experimenter[35] = "";
	char endIdAnimal[1] = "" ;
	char idAnimal[23] = "";
	double dateTrack = 0;
	int NTrackFile = 0;
	float samplingTime = 0;
	char endCalUnit[1] = "";
	char calUnit[10] = "";
	float horCal = 0;
	float verCal = 0;
	int NPoints = 0;
	char dump[1];

	fread (&version, sizeof (version), 1, fd);
	fread (&endExperimenter, sizeof (endExperimenter), 1, fd);
	fread (&experimenter, sizeof (experimenter), 1, fd);
	fread (&endIdAnimal, sizeof (endIdAnimal), 1, fd);
	fread (&idAnimal, sizeof (idAnimal), 1, fd);
	fread (&dateTrack, sizeof (dateTrack), 1, fd);
	fread (&NTrackFile, sizeof (NTrackFile), 1, fd);
	fread (&samplingTime, sizeof (samplingTime), 1, fd);
	fread (&endCalUnit, sizeof (endCalUnit), 1, fd);
	fread (&calUnit, sizeof (calUnit), 1, fd);
	fread (&horCal, sizeof (horCal), 1, fd);
	fread (&verCal, sizeof (verCal), 1, fd);
	fread (&NPoints, sizeof (NPoints), 1, fd);
	fread (&dump, sizeof (dump), 1, fd);

	dateTrackEPOCH = excelTime2EPOCH (dateTrack);
	dateString = returnTimeString (dateTrack, 80);

	if (dateTrackEPOCH != pdateTrackEPOCH && Ntrack != 1)
	{
	  fprintf (stderr, "ERROR: %i time stamps in tracks are not all equal %i\n", dateTrackEPOCH, pdateTrackEPOCH);
	  exit (EXIT_FAILURE);
	}

	//Once we have checked that all tracks timestamps are the same
	if (Ntrack == tracks)
	{
	  //fprintf (stdout, "#h;%s;HEADER;EHEADER;StartStamp;%i\n", fileName, dateTrackEPOCH);
	  sprintf (fileOut, "%s.date",fileName);
	  //fprintf (stdout, "######################%s\n", fileOut);
	  fp = fopen (fileOut, "w");
	  fprintf (fp, "%i", dateTrackEPOCH);
	  fprintf (stderr, "You can find starting recording EPOCH time inside file %s\n", fileOut);
	}

	pdateTrackEPOCH = dateTrackEPOCH;
	trackRemarksFormat trRmFormat;
	fread (&trRmFormat, sizeof (trRmFormat), 1, fd);

	trackPointList dummyTrPointList;
	fread (&dummyTrPointList, sizeof (dummyTrPointList), 1, fd);

	fseek (fd, dummyTrPointList.size, SEEK_CUR);

	trackPointList dummyEvents;

	fread (&dummyEvents, sizeof(dummyEvents), 1, fd);

    fseek (fd, dummyEvents.size, SEEK_CUR);

  }

  //returning file to original pos
  //fseek (fd, iniPos, SEEK_SET);


  //int endPos = 0;//#del
  //endPos = ftell (fd);//#del
  return fclose (fp);
}

//int readCoord (char **fl, int start, int nFiles)
//  {
//	int fc =0;
//	int end = 0;
//
//	end = start + nFiles;
//	fprintf (stderr, "---start----%i---nFiles----%i---end---%i\n", start, nFiles, end);
//
//	for (fc = start; fc < end; fc += 1)
//	{
//		 FILE *fd;
//
//		 char * fileName;
//		 fileName = fl[fc];
//
//		 fd = fopen (fileName, "rb");
//
//		 if ( fd == NULL )
//		 {
//		   puts ("Cannot open file");
//		   exit (EXIT_FAILURE);
//	     }


chunk returnChunkHeader (FILE *fd)
{
	chunk result;

	fread (&result, sizeof result, 1, fd);
	//result.id [4] = '\0';
	//printf (" %s -----------\n", result.id);
	//printf ("size: %d \n", result.size);
	return result;
}


void asessTag (char fileTag[], char Tag[])
{

	if (strncmp (fileTag, Tag, 4))
		{
		  fprintf (stderr, "ERROR:Tag file %s does not correspond to expected tag %s\n", fileTag, Tag);
		  exit (EXIT_FAILURE);
		}
}

int countBytes (FILE *fd)
{
	int size = 0;
	int iniPos = 0;
	int endPos = 0;

	iniPos = ftell (fd);
	fseek (fd, SEEK_CUR, SEEK_END);
	endPos = ftell (fd);

	size = endPos - (iniPos + 1);

	//returning file to original pos
	fseek (fd, iniPos, SEEK_SET);

	return size;
}

void printTrackHeaders (FILE *fd, int tracks, char * fileName)
{
  int iniPos = 0;
  int Ntrack = 0;
  int pdateTrackEPOCH = 0;

  iniPos = ftell (fd);

  //printf ("Initial pos is %i tracksN is %i\n\n", iniPos, tracks); //#DEL

  for (Ntrack=1; Ntrack <= tracks; Ntrack +=1)
  {
	int dateTrackEPOCH=0;
	char * dateString;
	/*#del
	fprintf (stderr, "Track being printed +++++++++++++++++++++++++ : %d \n\n\n", Ntrack);
	 */
    trackInfo trInfo;
    fread (&trInfo, sizeof trInfo, 1, fd);

    /*#del
    fprintf (stderr, "TR id: %s \n", trInfo.id);
    fprintf (stderr, "TR size: %d \n", trInfo.size);
    fprintf (stderr, "TR listType: %s \n", trInfo.listType);
	*/

    trackFormat trFormat;
    fread (&trFormat, sizeof trFormat, 1, fd);

    /*#del
    fprintf (stderr, "TR format id: %s \n", trFormat.id);
    fprintf (stderr, "TR format size: %d \n", trFormat.size);
	*/

    int version = 0;
	char endExperimenter[1] = "";
	char experimenter[35] = "";
	char endIdAnimal[1] = "" ;
	char idAnimal[23] = "";
	double dateTrack = 0;
	int NTrackFile = 0;
	float samplingTime = 0;
	char endCalUnit[1] = "";
	char calUnit[10] = "";
	float horCal = 0;
	float verCal = 0;
	int NPoints = 0;
	char dump[1];

	fread (&version, sizeof (version), 1, fd);
	fread (&endExperimenter, sizeof (endExperimenter), 1, fd);
	fread (&experimenter, sizeof (experimenter), 1, fd);
	fread (&endIdAnimal, sizeof (endIdAnimal), 1, fd);
	fread (&idAnimal, sizeof (idAnimal), 1, fd);
	fread (&dateTrack, sizeof (dateTrack), 1, fd);
	fread (&NTrackFile, sizeof (NTrackFile), 1, fd);
	fread (&samplingTime, sizeof (samplingTime), 1, fd);
	fread (&endCalUnit, sizeof (endCalUnit), 1, fd);
	fread (&calUnit, sizeof (calUnit), 1, fd);
	fread (&horCal, sizeof (horCal), 1, fd);
	fread (&verCal, sizeof (verCal), 1, fd);
	fread (&NPoints, sizeof (NPoints), 1, fd);
	fread (&dump, sizeof (dump), 1, fd);

	//(fread (&version, sizeof version, 1, trHeaderBuf);
    //printf ("Enter sentence to append: ");

	/*//chivatos//#del
	fprintf (stderr, "TR header version: %d \n", version);//del
	fprintf (stderr, "TR header endExperimenter: %d \n", endExperimenter[0]);//del
	fprintf (stderr, "TR header endExperimenter: %s \n", experimenter);//del
	fprintf (stderr, "TR header trackFile: %d \n", NTrackFile );
	*/

	dateTrackEPOCH = excelTime2EPOCH (dateTrack);
	dateString = returnTimeString (dateTrack, 80);
	//int dateString = excelTime2EPOCH (dateEPOCH);

	if (dateTrackEPOCH != pdateTrackEPOCH && Ntrack != 1)
	{
	  fprintf (stderr, "ERROR: %i time stamps in tracks are not all equal %i\n", dateTrackEPOCH, pdateTrackEPOCH);
	  exit (EXIT_FAILURE);
	}

	//fprintf (stderr, "Creation date EPOCH format: %i\n", dateTrackEPOCH);//#DEL

	/*Starting time is code in each track so first time is printed in the header and the coincidence with all the
	following tracks time is checked */

	if (Ntrack == 1)
	{
	  fprintf (stdout, "#h;%s;HEADER;EHEADER;StartStamp;%i\n", fileName, dateTrackEPOCH);
	  //fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Track Date & Time;%s", fileName,Ntrack, dateString);
	}
//	else
//	{
//	  fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Track Date & Time;%s", fileName,Ntrack, dateString);
//	}

	pdateTrackEPOCH = dateTrackEPOCH;
	trackRemarksFormat trRmFormat;
	fread (&trRmFormat, sizeof (trRmFormat), 1, fd);

	//Preparing string addind end '\0' to them
	char * calUnit2print;
	char * experimenter2print;
    char * idAnimal2print;

	calUnit2print = addEnd2string (calUnit, (unsigned char) endCalUnit[0]);
	experimenter2print = addEnd2string (experimenter, (unsigned char) endExperimenter[0]);
	idAnimal2print = addEnd2string (idAnimal, (unsigned char) endIdAnimal[0]);

	//fprintf (stdout, "--------------------size %i\n",trRmFormat.size);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Comments;%s\n", fileName, Ntrack, trRmFormat.remarks);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Number of Samples;%i\n", fileName, Ntrack, NPoints);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Calibration Units;%s\n", fileName, Ntrack, calUnit2print);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Experimenter;%s\n", fileName, Ntrack, experimenter2print);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Track Date & Time;%s", fileName,Ntrack, dateString);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Subject Identification;%s\n", fileName, Ntrack, idAnimal2print);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Subject Track Number;%i\n", fileName, Ntrack, NTrackFile);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Sampling Time;%1.1f\n", fileName, Ntrack, samplingTime);
	//puts ("IWH");

	trackPointList dummyTrPointList;
	fread (&dummyTrPointList, sizeof (dummyTrPointList), 1, fd);

	//readCoordinates (trPointList.size, fd, horCal, verCal);

	//fprintf (stdout, "--------------------size %i\n",DummyTrPointList.size);
	fseek (fd, dummyTrPointList.size, SEEK_CUR);

	trackPointList dummyEvents;

	fread (&dummyEvents, sizeof(dummyEvents), 1, fd);

	/*#del
	fprintf (stderr, "event id %s\n", dummyEvents.id);
	fprintf (stderr, "event size %d\n", dummyEvents.size);
	*/
    fseek (fd, dummyEvents.size, SEEK_CUR);

  }

  //returning file to original pos
  fseek (fd, iniPos, SEEK_SET);


  int endPos = 0;//#del
  endPos = ftell (fd);//#del

  //printf ("End pos is %i\n\n", endPos);//#del
//  //return 0;

}

//info2coord//#del
//void readCoordinates (int size, FILE *fd, float hCal, float vCal, int nTrack, char * fileName)
void readCoordinates (int size, FILE *fd, info2coord * info)
{
  //pasarle el tiempo inicial printar t + ctr y el ctr aprovecharlo para printar el index!! #del
  short * PointsBuff;
  PointsBuff = (short *) malloc (sizeof(char)* size);
  fread (PointsBuff, sizeof(char)* size,1, fd);

  int i,n,point;

  //i = 40;
  point = 1; //first index position 1
  i = size/2 ;

  for (n=0; n<=i; n+=10)
	{
	   //printf ("n is  -------------:%d\t %i\n", n, i);

	   fprintf (stdout, "#d;CAGE;%i;",info->nTrack); //#del igual es mejor pasarle una estructura con todos los datos
	   fprintf (stdout, "Index;%i;", point);
	   fprintf (stdout, "Time;%i;", info->iniTrTime + point);
	   fprintf (stdout, "XPos;%2.4f;", PointsBuff[n] * info->hCal);
	   fprintf (stdout, "YPos;%2.4f;", PointsBuff[n+1] * info->vCal);
	   fprintf (stdout, "Type;2;");
	   fprintf (stdout, "File;%s\n", info->fileName);
	   point +=1;
	};

  free (PointsBuff);
}

int excelTime2EPOCH (double timeTrack)
{
	//printf ("Creation date excel: %f\n", timeTrack);
	int timeExcel = 0;
	double timeExcelDec = 0;
    int timeEPOCH = 0;
    int daySecs = 86400;

    timeExcel = (int) timeTrack;
    timeExcelDec = timeTrack - timeExcel;
    //printf ("Creation date excel decimal format: %f\n", timeExcelDec);
    timeEPOCH = (timeExcel- 25569) * 86400;
    timeExcelDec *= daySecs;
    timeEPOCH += timeExcelDec;

    //Winter time is 1 hour (3600s) more than GMT
    //timeEPOCH -= 3600; //Conversion to GTM value, perl functions implemented convert to EPOCH time GTM.

    //Daylight saving time is 2 hours (7200s) more than GMT
    timeEPOCH -= 7200;

    return timeEPOCH;
}

char * returnTimeString (double EPOCHseconds, int n)
{
   char * dateOut;
   dateOut = malloc (n * sizeof (char));
   time_t time2time_t;
   struct tm * creationFileEPOCH;

   time2time_t = excelTime2EPOCH (EPOCHseconds);
   creationFileEPOCH = localtime (&time2time_t);

   strftime (dateOut, 80, "%d/%m/%Y %X\n", creationFileEPOCH);
   return dateOut;

}

char * addEnd2string (char * string, int size)
{
	char * newString;
	newString = malloc (size * sizeof (char));

	strncpy (newString, string, size);
	newString [size] = '\0';

	return newString;
}

int getNumbFiles (char ** argList, int startPos, int endList)
{
	int nFiles = 0;
	int i = 0;

	for (i = startPos; i < endList; i++)
	{
		if (argList[i][0] == '-')
		  {
			  nFiles = i - startPos;
			  //fprintf (stderr, "there is new tag--------%i\n", nFiles);//#del
			  return nFiles;
		  }
	}

	fprintf (stderr, "No next tag--------%i\n", endList - startPos);//#del
	nFiles = endList -startPos;
	return nFiles;
}
