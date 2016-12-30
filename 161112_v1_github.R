#czyszczcenie zmiennych
rm(list = setdiff(ls(), lsf.str()))
ptm <- proc.time()

install.packages('stringi', configure.args='--disable-cxx11', repos='http://cran.us.r-project.org')
install.packages("stringr", repos='http://cran.us.r-project.org')
install.packages("rvest", repos='http://cran.us.r-project.org')
install.packages("rJava", repos='http://cran.us.r-project.org')
install.packages("xlsx", repos='http://cran.us.r-project.org')

library(stringr)
library(rvest)
###krok 1 - tworzenie data frame

#kod lotniska wylot

skad = toString("KTW")

#kod lotniska przylotu
dokad = toString("BCN")

#kod lini lotniczych FR=Ryanair W6=wizzair DY=norwegian U2=easyjet
kodLini=toString("W6")

library(xlsx)
setwd("K:\\Dysk Google\\UE wroc\\Studia\\Magisterka\\Magisterka\\Zabawy w R\\opisy")
kierunkiZexcela<-read.xlsx("kierunki.xlsx", sheetIndex=1, header=TRUE, stringsAsFactors=FALSE)
kierunki=data.frame(kierunkiZexcela, stringsAsFactors = FALSE)
setwd("K:\\Dysk Google\\UE wroc\\Studia\\Magisterka\\Magisterka\\Zabawy w R\\loty_dane")

#rok 16 albo 17
ZakresRok=c(16,17)
aktualnyRok = as.numeric(strftime(Sys.Date(),"%y"))

#miesiac od 1 do 12
ZakresMiesiac = 1:12
aktualnyMiesiac = as.numeric(strftime(Sys.Date(),"%m"))

# tworzenie z zmiennych daty w formacie date
date = paste("1/",aktualnyMiesiac,"/",aktualnyRok, sep = "")
dataWylotu=as.Date(date,format = "%m/%d/%y")

# dzien przeprowadzania badania
aktualnyDzien = as.numeric(strftime(Sys.Date(),"%d"))
dzienBadania = paste(aktualnyDzien,"/",aktualnyMiesiac,"/",aktualnyRok, sep = "")

# cena - na ten moment w formacie liczba waluta np. 389 PLN
cena =as.numeric(0)

# waluta
waluta = "PLN"

dfWylot=data.frame(skad, dokad,kodLini, dataWylotu, waluta, cena,stringsAsFactors=FALSE )
dfPrzylot=data.frame(skad, dokad,kodLini, dataWylotu, waluta, cena,stringsAsFactors=FALSE )
colnames(dfWylot)[6]=dzienBadania
colnames(dfPrzylot)[6]=dzienBadania
dfPrzyZerowaniu=dfWylot
###krok 2 - pobieranie ze strony tabelki w formie wektra
k=1 #wieesz w macierzy przylotów-odlotów
j=1 #wiersz w dfWylot
q=1 #wiersz w dfPrzylot

t=nrow(kierunki)
while (k<=t[1][1]) {    #petla po kierunkach 
  
  skad=kierunki[k,1]
  dokad=kierunki[k,2]
  kodLini=kierunki[k,3]
  
  for (rok in ZakresRok){ 
    if (rok<aktualnyRok){
      next
    }
    for (miesiac in ZakresMiesiac) {
      if (rok==aktualnyRok){
        if (miesiac<aktualnyMiesiac) {
          next
        }        
      }
      
      Loty <- read_html(paste("http://samolotemtaniej.pl/tani-lot/",skad,"/",dokad,"/",kodLini,"/",rok,str_pad(miesiac, 2, pad = "0"),"01-",rok,str_pad(miesiac, 2, pad = "0"),"27/1",sep = ""))
      WektroWylot=Loty %>%
        html_nodes("#CalWylot .DayStyleCssClass span") %>% #noodes to pewna czesc strony z CSS
        html_text()
      WektorPowrot=Loty %>%
        html_nodes("#CalPowrot .DayStyleCssClass span") %>% #noodes to pewna czesc strony z CSS
        html_text()
      
       ###Krok 3 - wsadzania danych z kroku 1 do data frame
      for (n in 1:2){
        if (n==1){wektor=WektroWylot}else{wektor=WektorPowrot}
 
        i=1 #dlugosc wektra x z kroku 1
        while (i<=length(wektor)) {
          if (n==1){
            dfWylot[j,1]=skad
            dfWylot[j,2]=dokad
            dfWylot[j,3]=kodLini
            
            date= paste(wektor[i],"/",miesiac,"/",rok, sep = "")
            dataWylotu=as.Date(date,format = "%d/%m/%y")
            dfWylot[j,4]=dataWylotu
            
            #rozbcie komórki "399 PLN" na liste [[1]][1]=399 [[1]][2]=PLN
            z=strsplit(wektor[i+1]," ")
            cena=as.numeric(z[[1]][1])
            waluta=z[[1]][2]
            dfWylot[j,5]=waluta
            dfWylot[j,6]=cena
            
            j=j+1
          }else{
            dfPrzylot[q,1]=dokad
            dfPrzylot[q,2]=skad
            dfPrzylot[q,3]=kodLini
            
            date= paste(wektor[i],"/",miesiac,"/",rok, sep = "")
            dataWylotu=as.Date(date,format = "%d/%m/%y")
            dfPrzylot[q,4]=dataWylotu
            
            #rozbcie komórki "399 PLN" na liste [[1]][1]=399 [[1]][2]=PLN
            z=strsplit(wektor[i+1]," ")
            cena=as.numeric(z[[1]][1])
            waluta=z[[1]][2]
            dfPrzylot[q,5]=waluta
            dfPrzylot[q,6]=cena
            
            q=q+1
          }
          i=i+3
        }
      }
    }
  }
  dfWylot_doDoklejenia=dfWylot
  dfPrzylot_doDoklejenia=dfPrzylot
  
  ###Krok 4a doklejanie danych do wczesnieszych danych Wylotu
  fileNameWylot=paste(skad,"-",dokad,"_" ,kodLini,"_data.Rda",sep = "")
  if (!file.exists(fileNameWylot)){
    df_glownyWylot=dfWylot
    save(df_glownyWylot,file=fileNameWylot)
  } else {
    load(fileNameWylot)
    df_glownyWylot =merge(x=df_glownyWylot,y=dfWylot_doDoklejenia[ , c("dataWylotu",dzienBadania)], by.x="dataWylotu",by.y="dataWylotu", all = TRUE)
    save(df_glownyWylot,file=fileNameWylot)
  }

  ###Krok 4b doklejanie danych do wczesnieszych danych Przylot
  fileNamePrzylot=paste(dokad,"-",skad,"_" ,kodLini,"_data.Rda",sep = "")
  if (!file.exists(fileNamePrzylot)){
    df_glownyPrzylot=dfPrzylot
    save(df_glownyPrzylot,file=fileNamePrzylot)
  } else {
    load(fileNamePrzylot)
    df_glownyPrzylot =merge(x=df_glownyPrzylot,y=dfPrzylot_doDoklejenia[ , c("dataWylotu",dzienBadania)], by.x="dataWylotu",by.y="dataWylotu", all = TRUE)
    save(df_glownyPrzylot,file=fileNamePrzylot)
  }
  
  #tu moze trzeba wszystko wyzerowac
  df_doDoklejenia=0
  df_glowny=0
  df_glownyPrzylot=0
  df_glownyWylot=0
  dfPrzylot_doDoklejenia=0
  dfWylot_doDoklejenia=0
  dfPrzylot=dfPrzyZerowaniu
  dfWylot=dfPrzyZerowaniu
  
  fileNameWylot=0
  fileNamePrzylot=0

  WektroWylot=0
  WektorPowrot=0
  wektor=0
  
  q=1
  j=1
  n=1
  i=1
  k=k+1
}

CzasTrwania=proc.time() - ptm
CzasTrwania
