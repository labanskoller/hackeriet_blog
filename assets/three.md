# FragFS
*Et frygteligt fragmenteret filsystem*

---
##Synopsis
>FragFS er et filsystem udviklet alene med det formål at give andre hovedpine. Filsystemet understøtter kun små filer og diskstørrelser. Alt andet kan og vil gå galt.

##Beskrivelse
>FragFS benytter en sektor størrelse på 4096 bytes og har følgende overordnede struktur:

####Version beskrivelse

>De første 512 bytes angiver hvilken version af filsystemet der anvendes.

####FilID og Filsti/Filnavn tabel

>Starter ved byteoffset 512 ved start fra offset 0.

>Hver entry indeholder en MD5 checksum(FilID) skabt ud fra filsti+filnavn. 


####FilID og Offset tabel

>Følger direkte efter den foregående tabel.


####Filsystemets indhold

>Starter ved sectoroffset 20/byteoffset 81920 fra start offset 0.

>Slutter når filsystemet får lyst til at slutte.


####BUGS

>Bunkevis. Brug spray eller DEET.

---
*Af Professor Kenneth Kiwistone*
