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

/* Reading tac files */

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



//Function declaration
//functions should be inside decl.c
void fileProcessing (FILE *fd, char * name);
chunk returnChunkHeader (FILE *fd);
int countBytes (FILE *fd);
void asessTag (char fileTag[], char Tag[]);
void readCoordinates (int size, FILE *fd, float hCal, float vCal);
int excelTime2EPOCH (double dateTrack);
char * returnTimeString (double EPOCHseconds, int n);
void printTrackHeaders (FILE *fd, int tracks, char * fileName);
int main (int argc, char *argv[])
//int main ()
{

  //inside eclipse the first element of arg[] is the debugging folder
  //this is the reason for starting at 1
  int fileCtr;

  for (fileCtr = 1; fileCtr < argc; fileCtr += 1)
  {
	 FILE *fd;

	 char * fileName;
	 fileName = argv[fileCtr];

	 fd = fopen (fileName, "rb");

	 if ( fd == NULL )
	 {
	   puts ("Cannot open file");
	   exit (1);
     }

	 fileProcessing (fd, fileName); //fileName only for printing purpose
	 printf ("file is %s\n\n" , fileName);
	 fclose (fd);
  }

  return 0;
}

/*Functions
*/
void fileProcessing (FILE *fd, char * name)
  {
	  char msg[]="test";
	  fprintf (stderr, "%s\n", msg);

	  chunk fileHeader;
	  fileHeader = returnChunkHeader (fd);

	  asessTag (fileHeader.id, "RIFF");

	  fprintf (stderr, "Annotated file size: %d \n", fileHeader.size);//chivato

	  int count = 0;
	  count = countBytes (fd);

	  fprintf (stderr, "Size until end of file: %i \n", count);//chivato

	  chunk experimentInfo;
	  experimentInfo = returnChunkHeader (fd);

	  fprintf (stderr, "id: %s \n", experimentInfo.id);//chivato
	  fprintf (stderr, "size: %i \n", experimentInfo.size);//chivato
	  fprintf (stderr, "type: %s \n", experimentInfo.type);//chivato

	  experimentHeader expHeader;
	  fread (&expHeader, sizeof expHeader, 1, fd);
	  asessTag (expHeader.id, "fmt ");

	  fprintf (stderr, "id: %s \n", expHeader.id);//chivato
	  fprintf (stderr, "size: %i \n", expHeader.size);//chivato
	  fprintf (stderr, "trajectories: %i \n", expHeader.trajectories);//chivato
	  fprintf (stderr, "Creation date excel format: %f\n", expHeader.creationDate);

	  //unsigned char ch = (unsigned char)expHeader.endName[0];
	  fprintf (stderr, "endName: %d \n", expHeader.endName[0]);//chivato
	  fprintf (stderr, "Name: %s \n", expHeader.name);//chivato

	  remarks expRemarks;
	  fread (&expRemarks, sizeof expRemarks, 1, fd);
	  asessTag (expRemarks.id, "cmnt");
	  fprintf (stderr, "Exp remarks size: %d \n", expRemarks.size);
	  fprintf (stderr, "Exp remarks endName: %d \n", expRemarks.endName[0]);//chivato
	  fprintf (stderr, "Exp remarks Name: %s \n", expRemarks.name);//chivato

	  //PRINTING FILE HEADERS
	  //char name2print[35] = expHeader.name; //if we don't know the size use malloc
	  //Preparing string variables to be print
	  char name2print[expHeader.endName[0]];
	  strncpy (name2print, expHeader.name, expHeader.endName[0]);
	  name2print [expHeader.endName[0]] = '\0';

	  char * date2printCreation;
	  char * date2printMod;

	  date2printCreation = returnTimeString (expHeader.creationDate, 80);
	  date2printMod = returnTimeString (expHeader.modDate, 80);

	  fprintf (stdout, "#h;%s;TRACKING FILE;TRACKING FILE;File Creation Date & Time;%s", name, date2printCreation);
	  fprintf (stdout, "#h;%s;TRACKING FILE;TRACKING FILE;Last Modification Date & Time;%s", name, date2printMod);
	  fprintf (stdout, "#h;%s;TRACKING FILE;TRACKING FILE;Code;%s\n", name, name2print);
	  fprintf (stdout, "#h;%s;TRACKING FILE;TRACKING FILE;Comments;%s\n", name, expRemarks.name);
	  fprintf (stdout, "#h;%s;HEADER;EHEADER;Ncages;%i\n", name, expHeader.trajectories);//DO THE ASSIGMENT OF THE END STRING


	  //TRACK STUFF BEGINS HERE, IT SHOULD BE IN A LOOP OF THE NUMBER O TRACKS (NUMBER OF TRAJECTORIES WILL BE THE COUNTER)
	  //Printing tracks header first

	  printTrackHeaders (fd, expHeader.trajectories, name);

	  int Ntrack;
	  //int pdateEPOCH = 0;

	  //for (Ntrack=1; Ntrack <= 12; Ntrack +=1)
	  for (Ntrack=1; Ntrack <= expHeader.trajectories; Ntrack +=1)
	  {

		  fprintf (stderr, "Track being SKIPPED +++++++++++++++++++++++++ : %d \n\n\n", Ntrack);

		  trackInfo trInfo;
		  fread (&trInfo, sizeof trInfo, 1, fd);

		  fprintf (stderr, "TR id: %s \n", trInfo.id);
		  fprintf (stderr, "TR size: %d \n", trInfo.size);
		  fprintf (stderr, "TR listType: %s \n", trInfo.listType);

		  //fseek (fd, trInfo.size, SEEK_CUR);

		  trackFormat trFormat;
		  fread (&trFormat, sizeof trFormat, 1, fd);

	/*	  fprintf (stderr, "TR format id: %s \n", trFormat.id);
		  fprintf (stderr, "TR format id: %s \n", trFormat.id);
		  fprintf (stderr, "TR format size: %d \n", trFormat.size);
*/
		  //char * trHeaderBuf;
		  //trHeaderBuf = (char *) malloc (trFormat.size);
		  //fread (&trHeaderBuf, sizeof (trHeaderBuf), 1, fd);


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

		   //(fread (&version, sizeof version, 1, trHeaderBuf);
		  //printf ("Enter sentence to append: ");

		  //chivatos
		  fprintf (stderr, "TR header version: %d \n", version);//del
		  fprintf (stderr, "TR header endExperimenter: %d \n", endExperimenter[0]);//del
		  fprintf (stderr, "TR header endExperimenter: %s \n", experimenter);//del
		  fprintf (stderr, "TR header trackFile: %d \n", NTrackFile );//del

//		  int dateEPOCH = excelTime2EPOCH (dateTrack);
//
//		  if (dateEPOCH != pdateEPOCH && Ntrack != 1)
//		  {
//		    fprintf (stderr, "ERROR: %i time stamps in tracks are not all equal %i\n", dateEPOCH, pdateEPOCH);
//		    exit (1);
//		  }
//
//
//		  //double i = 3.9; #del
//		  //int x;
//		  //x = (int) i;
//		  //printf ("Rounding i: %i\n", x);
//		  pdateEPOCH = dateEPOCH;
//
//		  fprintf (stderr, "Creation date EPOCH format: %i\n", dateEPOCH);
//
//		  /*Starting time is code in each track so first time is printed in the header and the coincidence with all the
//		  following tracks time is checked */
//		  if (Ntrack == 1)
//		  {
//		    fprintf (stdout, "#h;%s;HEADER;EHEADER;StartStamp;%i\n", name, dateEPOCH);
//		  }


		  //printf ("Creation date EPOCH format integer: %i\n", dateEPOCHint);
		  //exit(1);
		  //int end;
		  //end = expHeader.endName;

		  fprintf (stderr, "TR header horCal: %f \n", horCal);
		  fprintf (stderr, "TR header verCal: %f \n", verCal);
		  fprintf (stderr, "TR header Npoints: %d \n", NPoints);
		  //chivatos

		  trackRemarksFormat trRmFormat;
		  fread (&trRmFormat, sizeof (trRmFormat), 1, fd);

		  trackPointList trPointList;
		  fread (&trPointList, sizeof (trPointList), 1, fd);

		  //readCoordinates (trPointList.size, fd, horCal, verCal);
		  fseek (fd, trPointList.size, SEEK_CUR);

		  trackPointList events;

		  fread (&events, sizeof(events),1, fd);
		  fprintf (stderr, "event id %s\n", events.id);
		  fprintf (stderr, "event size %d\n", events.size);

	//	  trackPointList eventFormat;
	//	  fread (&eventFormat, sizeof(eventFormat),1, fd);
	//	  printf ("EventFormat id %s\n", eventFormat.id);
	//	  printf ("Eventformat size %d\n", eventFormat.size);
	//
	//	  //ME FALTA CABECERA DE EVENTOS
	//	  int eventVersion;
	//	  unsigned short NEvent;
	//	  fread (&eventVersion, sizeof(eventVersion),1, fd);
	//	  fread (&NEvent, sizeof(NEvent),1, fd);
	//	  printf ("EventVersion: %d\n", eventVersion);
	//	  printf ("NEvent: %i\n", NEvent);
	//
	//	  trackPointList eventList;
	//	  fread (&eventList, sizeof(eventList),1, fd);
	//	  printf ("EventList id: %s\n", eventList.id);
	//	  printf ("EventList size %i\n", eventList.size);
	//	  fseek (fd, NEvent*5, SEEK_CUR);
	//	  //fseek (fd, eventList.size, SEEK_CUR);

		  fseek (fd, events.size, SEEK_CUR);
	//	  char caca [4];
	//	  fread (&caca, sizeof(caca),1, fd);
	//	  printf ("que funcione  %s\n", caca);

	  };
	  //free (trHeaderBuf);

	//

	//  trackHeader trHeader;
	//  fread (&trHeader, sizeof trHeader, 1, fd);
	//
	//  currentPos = 0;
	//  currentPos=  ftell (fd);
	//
	//  printf ("TR header version: %d \n", trHeader.version);
	//  printf ("TR header experimenter: %s \n", trHeader.experimenter);
	//  printf ("TR header id animal: %s \n", trHeader.idAnimal);
	//  printf ("TR header date: %f \n", trHeader.date);
	//  printf ("TR header Track Number: %d \n", trHeader.NTrackFile);
	//  printf ("TR header sampling time: %f \n", trHeader.samplingTime);
	//  printf ("TR header end Cal Unit: %d \n", trHeader.endcalUnit[0]);
	//
	//  int end = trHeader.endcalUnit[0];
	//  char calunit[end];
	//  strcpy (calunit ,trHeader.calUnit);
	//  calunit[end] = '\0';
	//  printf ("TR header Cal Unit: %s \n", calunit);

	  //printf ("TR header Horizontal Calibration: %f \n", trHeader.horCal);

	//  float horCal;
	//  fread (&horCal, sizeof horCal, 1, fd);
	//  printf ("TR header Horizontal Calibration: %f \n", horCal);


	  //printf ("TR remarks format: %s \n", track1.trRmFormat.id);
	  //printf ("size: %d \n", track1.trPointList.size);
  }


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
		  exit (1);
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

	size = endPos - iniPos;

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
  printf ("Initial pos is %i tracksN is %i\n\n", iniPos, tracks);
  for (Ntrack=1; Ntrack <= tracks; Ntrack +=1)
  {
	int dateTrackEPOCH=0;
	char * dateString;

	fprintf (stderr, "Track being printed +++++++++++++++++++++++++ : %d \n\n\n", Ntrack);

    trackInfo trInfo;
    fread (&trInfo, sizeof trInfo, 1, fd);

    fprintf (stderr, "TR id: %s \n", trInfo.id);
    fprintf (stderr, "TR size: %d \n", trInfo.size);
    fprintf (stderr, "TR listType: %s \n", trInfo.listType);

    trackFormat trFormat;
    fread (&trFormat, sizeof trFormat, 1, fd);

    fprintf (stderr, "TR format id: %s \n", trFormat.id);
    fprintf (stderr, "TR format size: %d \n", trFormat.size);

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
	char dump[1];

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

	//(fread (&version, sizeof version, 1, trHeaderBuf);
    //printf ("Enter sentence to append: ");

	//chivatos
	fprintf (stderr, "TR header version: %d \n", version);//del
	fprintf (stderr, "TR header endExperimenter: %d \n", endExperimenter[0]);//del
	fprintf (stderr, "TR header endExperimenter: %s \n", experimenter);//del
	fprintf (stderr, "TR header trackFile: %d \n", NTrackFile );

	dateTrackEPOCH = excelTime2EPOCH (dateTrack);
	dateString = returnTimeString (dateTrack, 80);
	//int dateString = excelTime2EPOCH (dateEPOCH);

	if (dateTrackEPOCH != pdateTrackEPOCH && Ntrack != 1)
	{
	  fprintf (stderr, "ERROR: %i time stamps in tracks are not all equal %i\n", dateTrackEPOCH, pdateTrackEPOCH);
	   exit (1);
	}

	fprintf (stderr, "Creation date EPOCH format: %i\n", dateTrackEPOCH);

	/*Starting time is code in each track so first time is printed in the header and the coincidence with all the
	following tracks time is checked */

	if (Ntrack == 1)
	{
	  fprintf (stdout, "#h;%s;HEADER;EHEADER;StartStamp;%i\n", fileName, dateTrackEPOCH);
	  fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Track Date & Time;%s", fileName,Ntrack, dateString);
	}
	else
	{
	  fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Track Date & Time;%s", fileName,Ntrack, dateString);
	}

	pdateTrackEPOCH = dateTrackEPOCH;
	trackRemarksFormat trRmFormat;
	fread (&trRmFormat, sizeof (trRmFormat), 1, fd);
	//fprintf (stdout, "--------------------size %i\n",trRmFormat.size);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Comments;%s\n", fileName, Ntrack, trRmFormat.remarks);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Number of Samples;%i\n", fileName, Ntrack, NPoints);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Calibration Units;%s\n", fileName, Ntrack, calUnit);
	fprintf (stdout, "#h;%s;TRACK INFORMATION;%i;Experimenter;%s\n", fileName, Ntrack, experimenter);
	puts ("IWH");

	trackPointList dummyTrPointList;
	fread (&dummyTrPointList, sizeof (dummyTrPointList), 1, fd);

	//readCoordinates (trPointList.size, fd, horCal, verCal);

	//fprintf (stdout, "--------------------size %i\n",DummyTrPointList.size);
	fseek (fd, dummyTrPointList.size, SEEK_CUR);

	trackPointList dummyEvents;

	fread (&dummyEvents, sizeof(dummyEvents), 1, fd);

	fprintf (stderr, "event id %s\n", dummyEvents.id);
	fprintf (stderr, "event size %d\n", dummyEvents.size);

    fseek (fd, dummyEvents.size, SEEK_CUR);

  }

  //returning file to original pos
  fseek (fd, iniPos, SEEK_SET);


  int endPos = 0;//#del
  endPos = ftell (fd);//#del
  printf ("End pos is %i\n\n", endPos);//#del
//  //return 0;

}

void readCoordinates (int size, FILE *fd, float hCal, float vCal)
{
  short * PointsBuff;
  PointsBuff = (short *) malloc (sizeof(char)* size);
  fread (PointsBuff, sizeof(char)* size,1, fd);

  int i,n,point;

  //i = 40;
  point = 0;
  i = size/2 ;

  for (n=0; n<=i; n+=2)
	{
	   //printf ("n is  -------------:%d\t %i\n", n, i);
	   printf ("%i\t",point);
	   printf ("%f\t",PointsBuff[n]*hCal);
	   printf ("%f\n", PointsBuff[n+1]*vCal);
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
    timeEPOCH -= 3600; //Conversion to GTM value, perl functions implemented convert to EPOCH time GTM.

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
		  //14/05/2010 15:57:44

   strftime (dateOut, 80, "%d/%m/%Y %X\n", creationFileEPOCH);
   return dateOut;

}
