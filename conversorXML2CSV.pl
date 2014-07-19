%La libreria sgml es la que nos da load_xml
:- use_module(library(sgml)).
%La libreria para usar member y append en las listas
:- use_module(library(lists)).
%libreria para poder descargarse cosas desde internet
:- use_module(library(http/http_open)).


transformarXMLaCSV:-
	generarCSVdesdeURL('http://datos.madrid.es/egob/catalogo/202625-0-aparcamientos-publicos.xml','aparcamientos publicos'),
	generarCSVdesdeURL('http://datos.madrid.es/egob/catalogo/200761-0-parques-jardines.xml','parques y jardines'),
	generarCSVdesdeURL('http://datos.madrid.es/egob/catalogo/200284-0-puntos-limpios.xml','puntos limpios').
transformarXMLaCSV(Archivo):- 
	load_xml(Archivo,Parseado,[]),cabeceras(Parseado,Zs),listaFinalCabeceras(Zs,Ys),numPosicion(Ys,0,Xs),contenido(Parseado,Xs,Sol),listaFinalContenido(Sol,Ws),nombreArchivo(Archivo,Nombre),escribirCSV(Xs,Ws,Nombre).
transformarXMLaCSV(URL,NombreArchivo):-
	generarCSVdesdeURL(URL,NombreArchivo).

	
%Predicado que recorre lo que nos devuelve la libreria de load_xml y saca en una lista de listas todas las cabeceras de cada fila ademas si tiene subgrupos dentro de esa lista tendra otra lista con las cabeceras del subgrupo
%En la lista devuelta por load_xml vamos a buscar las cabeceras par anuestro archivo CSV para eso tendremos que recorrer toda la lista debido a que en los xml no es 
%obligatorio poner los atributos que estan vacios.
cabeceras([],_).
cabeceras([element(_,[],Ys)],Zs):-
	cabeceras(Ys,Zs),!.
cabeceras([_,element(_,[],Ys)|Xs],[Zs|Zss]):-
	cabeceras(Ys,Zs),cabeceras(Xs,Zss),!.
cabeceras([_,element(_,_,Ys)|Xs],[Zs|Zss]):-
	esSubGrupo(Ys),!,cabeceras(Ys,Zs),cabeceras(Xs,Zss).	
cabeceras([_,element(_,_,[])|Xs],Zs):-
	cabeceras(Xs,Zs),!.
cabeceras([_,element(_,Ws,_)|Xs],[Zs|Zss]):-
	dameNombre(Ws,Zs),cabeceras(Xs,Zss),!.
cabeceras([_],[]).


%Para saber si el elemento es una lista
esLista([_]).
esLista([_|_]).	
	
%Predicado para trasformar la lista de listas de cabeceras en un unica lista con todas las cabeceras sin repeticiones en orden

listaFinalCabeceras([],_).
listaFinalCabeceras([X],[]):-
	unificarEnUnaLista(X,Zs),Zs==[],!.
listaFinalCabeceras([X],Ys):-
	unificarEnUnaLista(X,Zs),fusionar(Zs,[],Ys),!.
listaFinalCabeceras([X|Xs],Ys):-
	unificarEnUnaLista(X,Zs),Zs==[],!,listaFinalCabeceras(Xs,Ys).
listaFinalCabeceras([X|Xs],Ys):-
	unificarEnUnaLista(X,Zs),listaFinalCabeceras(Xs,Ws),fusionar(Zs,Ws,Ys).
	

%Convierte una lista que tiene sublistas dentrs en una lista que solo tiene listas dentro de un unico nivel

unificarEnUnaLista([],[]).
unificarEnUnaLista([[]|Xs],Ys):-
	unificarEnUnaLista(Xs,Ys),!.
unificarEnUnaLista([X|Xs],Ys):-
	esLista(X),!,append(X,Xs,Zs),unificarEnUnaLista(Zs,Ys).
unificarEnUnaLista([X|Xs],[X|Ys]):-
	unificarEnUnaLista(Xs,Ys).

%Predicado que fusiona las listas Xs e Ys en Zs conservando el orden y sin repeticiones
	
fusionar([],[],[]).
fusionar([],[Y|Ys],[Y|Zs]):-
	fusionar([],Ys,Zs),!.
fusionar([X|Xs],[],[X|Zs]):-
	fusionar(Xs,[],Zs),!.
fusionar([X|Xs],[X|Ys],[X|Zs]):-
	fusionar(Xs,Ys,Zs),!.
fusionar([X|Xs],[Y|Ys],[X|Zs]):-
	member(Y,Xs),delete(Ys,X,Ws),!,fusionar(Xs,[Y|Ws],Zs).
fusionar([X|Xs],[Y|Ys],[X|Zs]):-
	member(Y,Xs),!,fusionar(Xs,[Y|Ys],Zs).
fusionar([X|Xs],[Y|Ys],[X|Zs]):-
	not(member(X,Ys)),delete(Ys,X,Ws),!,fusionar(Xs,[Y|Ws],Zs).
fusionar([X|Xs],[Y|Ys],[X|Zs]):-
	not(member(X,Ys)),!,fusionar(Xs,[Y|Ys],Zs).
fusionar([X|Xs],[Y|Ys],[Y|Zs]):-
	delete(Xs,Y,Ws),!,fusionar([X|Ws],Ys,Zs).
fusionar([X|Xs],[Y|Ys],[Y|Zs]):-
	fusionar([X|Xs],Ys,Zs).
	
%predicado para saber si un atributo tiene un subgrupo de nombres dentro, si lo es no debemos añadirlo a la lista de nombres para la cabecera de csv	

esSubGrupo([_,element(_,_,_)|_]).

%como sabemos que viene el nombre para la cabecera como clave = valor queremos cojer el valor que sera el nombre de la cabecera, ademas suponemos que solo tendremos una pareja clave valor si hay mas fallara el programa ya que no sabriamos cual coger

dameNombre([_=Nombre|[]],Nombre).

%Predicado que pone a la lista de cabeceras un numero para saber su posicion lo pondremos asi [(Nombre,Posisicion)|Xs]

numPosicion([],_,[]).
numPosicion([X|Xs],N,[(X,N)|Ys]):-
	Pos is N+1,numPosicion(Xs,Pos,Ys).

%ahora vamos a sacar el contenido de cada fila esta basada en cabeceras y funciona igual solo que ahora llevamos las cabeceras para poder colocarles el indice que les corresponde para luego poder ordenarlas

contenido([],_,_):-!.
contenido([element(_,[],Ys)],Ca,Zs):-
	contenido(Ys,Ca,Zs),!.
contenido([_,element(_,[],Ys)|Xs],Ca,[Zs|Zss]):-
	contenido(Ys,Ca,Zs),contenido(Xs,Ca,Zss),!.
contenido([_,element(_,_,Ys)|Xs],Ca,[Zs|Zss]):-
	esSubGrupo(Ys),!,contenido(Ys,Ca,Zs),contenido(Xs,Ca,Zss).	
contenido([_,element(_,_,[])|Xs],Ca,Zs):-
	contenido(Xs,Ca,Zs),!.
contenido([_,element(_,Ws,[Zs])|Xs],Ca,[(Zs,N)|Zss]):-
	dameNombre(Ws,No),devolverPos(Ca,No,N),contenido(Xs,Ca,Zss),!.
contenido([_],_,[]).

%Recorremos la lista de contenido quitando las sublistas de dentro

listaFinalContenido([],_).
listaFinalContenido([X],[]):-
	unificarEnUnaLista(X,Zs),Zs==[],!.
listaFinalContenido([X],[Ys]):-
	unificarEnUnaLista(X,Zs),!,quicksort(Zs,Ys).
listaFinalContenido([X|Xs],Yss):-
	unificarEnUnaLista(X,Zs),Zs==[],!,listaFinalContenido(Xs,Yss).
listaFinalContenido([X|Xs],[Ys|Yss]):-
	unificarEnUnaLista(X,Zs),quicksort(Zs,Ys),listaFinalContenido(Xs,Yss).

%ordenar cada lista de contenido segun su numero por si estan desordenadas
/* [+,-] */
quicksort([], []):-!.
quicksort([HEAD | TAIL], SORTED) :- partition(HEAD, TAIL, LEFT, RIGHT),
                                    quicksort(LEFT, SORTEDL),
                                    quicksort(RIGHT, SORTEDR),
                                    append(SORTEDL, [HEAD | SORTEDR], SORTED).

/* [+,+,-,-] */
partition(_, [], [], []):-!.
partition((XPIVOT,NPIVOT), [(XHEAD,NHEAD) | TAIL], [(XHEAD,NHEAD) | LEFT], RIGHT) :- NHEAD @=< NPIVOT,!,
                                                         partition((XPIVOT,NPIVOT), TAIL, LEFT, RIGHT).
partition((XPIVOT,NPIVOT), [(XHEAD,NHEAD) | TAIL], LEFT, [(XHEAD,NHEAD) | RIGHT]) :- NHEAD @> NPIVOT,
                                                         partition((XPIVOT,NPIVOT), TAIL, LEFT, RIGHT).


%devolver la posicion que tiene la tupla de cabeceras con la cabecera dada

devolverPos([],_,_):- false.
devolverPos([(X,N)|_],X,N):-!.
devolverPos([_|Xs],Y,N):-
	devolverPos(Xs,Y,N).

%Escribimos en el fichero CSV el nl es para dejar un salto de linea

escribirCSV(Cabeceras,Contenido,Archivo):-
	open(Archivo,write,Stream,[encoding(utf8)]),escribirLista(Cabeceras,Stream),nl(Stream),escribirContenido(Contenido,Stream),close(Stream).

%recorro una lista y la voy escribirendo en el fichero que me pasaron	

escribirLista([],_).
escribirLista([(X,_)],Stream):-
		sub_string(X,_,_,_,','),!,write(Stream,'"'),write(Stream,X),write(Stream,'"').
escribirLista([(X,_)],Stream):-
		write(Stream,X),!.
escribirLista([(X,_)|Xs],Stream):-
		sub_string(X,_,_,_,','),!,write(Stream,'"'),write(Stream,X),write(Stream,'"'),write(Stream,','),escribirLista(Xs,Stream).
escribirLista([(X,_)|Xs],Stream):-
		write(Stream,X),write(Stream,','),escribirLista(Xs,Stream).
		
%recorro las listas de contenidos y se las paso a escribir lista

escribirContenido([],_).
escribirContenido([X],Stream):-
	escribirLista(X,Stream),!.
escribirContenido([X|Xs],Stream):-
	escribirLista(X,Stream),nl(Stream),escribirContenido(Xs,Stream).

%vamosa sacar el nombre del archivo y ponerle extension csv
nombreArchivo(Archivo,Nombre):-
	 atomic_list_concat(Xs,'.xml',Archivo),comprobar(Xs,X),string_concat(X,'.csv',Nombre).

comprobar([X|Xs],X):-
	restoVacio(Xs).
	
restoVacio([]).
restoVacio([X|Xs]):-
	X='',restoVacio(Xs).

%predicado para convertir una URL que contenga un archivo XML a un archivo CSV
generarCSVdesdeURL(URL,NombreArchivo):-	
	http_open(URL, Stream, []),
	nombreArchivo(NombreArchivo,Nombre),
	load_xml(Stream,Parseado,[]),cabeceras(Parseado,Zs),listaFinalCabeceras(Zs,Ys),numPosicion(Ys,0,Xs),contenido(Parseado,Xs,Sol),listaFinalContenido(Sol,Ws),escribirCSV(Xs,Ws,Nombre),
	close(Stream).	
